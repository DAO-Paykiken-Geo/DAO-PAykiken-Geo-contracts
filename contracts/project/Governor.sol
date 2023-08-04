// SPDX-License-Identifier: MIT
/**
 *           _____                    _____                _____                    _____                    _____                    _____                    _____                    _____
 *          /\    \                  /\    \              |\    \                  /\    \                  /\    \                  /\    \                  /\    \                  /\    \
 *         /::\    \                /::\    \             |:\____\                /::\____\                /::\    \                /::\____\                /::\    \                /::\____\
 *        /::::\    \              /::::\    \            |::|   |               /:::/    /                \:::\    \              /:::/    /               /::::\    \              /::::|   |
 *       /::::::\    \            /::::::\    \           |::|   |              /:::/    /                  \:::\    \            /:::/    /               /::::::\    \            /:::::|   |
 *      /:::/\:::\    \          /:::/\:::\    \          |::|   |             /:::/    /                    \:::\    \          /:::/    /               /:::/\:::\    \          /::::::|   |
 *     /:::/__\:::\    \        /:::/__\:::\    \         |::|   |            /:::/____/                      \:::\    \        /:::/____/               /:::/__\:::\    \        /:::/|::|   |
 *    /::::\   \:::\    \      /::::\   \:::\    \        |::|   |           /::::\    \                      /::::\    \      /::::\    \              /::::\   \:::\    \      /:::/ |::|   |
 *   /::::::\   \:::\    \    /::::::\   \:::\    \       |::|___|______    /::::::\____\________    ____    /::::::\    \    /::::::\____\________    /::::::\   \:::\    \    /:::/  |::|   | _____
 *  /:::/\:::\   \:::\____\  /:::/\:::\   \:::\    \      /::::::::\    \  /:::/\:::::::::::\    \  /\   \  /:::/\:::\    \  /:::/\:::::::::::\    \  /:::/\:::\   \:::\    \  /:::/   |::|   |/\    \
 * /:::/  \:::\   \:::|    |/:::/  \:::\   \:::\____\    /::::::::::\____\/:::/  |:::::::::::\____\/::\   \/:::/  \:::\____\/:::/  |:::::::::::\____\/:::/__\:::\   \:::\____\/:: /    |::|   /::\____\
 * \::/    \:::\  /:::|____|\::/    \:::\  /:::/    /   /:::/~~~~/~~      \::/   |::|~~~|~~~~~     \:::\  /:::/    \::/    /\::/   |::|~~~|~~~~~     \:::\   \:::\   \::/    /\::/    /|::|  /:::/    /
 *  \/_____/\:::\/:::/    /  \/____/ \:::\/:::/    /   /:::/    /          \/____|::|   |           \:::\/:::/    / \/____/  \/____|::|   |           \:::\   \:::\   \/____/  \/____/ |::| /:::/    /
 *           \::::::/    /            \::::::/    /   /:::/    /                 |::|   |            \::::::/    /                 |::|   |            \:::\   \:::\    \              |::|/:::/    /
 *            \::::/    /              \::::/    /   /:::/    /                  |::|   |             \::::/____/                  |::|   |             \:::\   \:::\____\             |::::::/    /
 *             \::/____/               /:::/    /    \::/    /                   |::|   |              \:::\    \                  |::|   |              \:::\   \::/    /             |:::::/    /
 *              ~~                    /:::/    /      \/____/                    |::|   |               \:::\    \                 |::|   |               \:::\   \/____/              |::::/    /
 *                                   /:::/    /                                  |::|   |                \:::\    \                |::|   |                \:::\    \                  /:::/    /
 *                                  /:::/    /                                   \::|   |                 \:::\____\               \::|   |                 \:::\____\                /:::/    /
 *                                  \::/    /                                     \:|   |                  \::/    /                \:|   |                  \::/    /                \::/    /
 *                                   \/____/                                       \|___|                   \/____/                  \|___|                   \/____/                  \/____/
 */
pragma solidity ^0.8.6;

import "../base/TRC20.sol";
import "../base/ITRC20.sol";
import {SafeMath} from "../base/SafeMath.sol";
import {Strings} from "../base/Strings.sol";
import "./IHold.sol";
import {SafeMath} from "../base/SafeMath.sol";

contract Governor {
    using SafeMath for uint256;
    using Strings for uint256;

    event CreatePoll(uint256 pollID, uint256 amount, address sendTo, address creator, uint256 deadline);
    event FinishPoll(uint256 participationRate, address to, uint256 amount);
    event SubmitVote(uint256 pollID, uint256 paykikInHold, uint256 totalVoted, address sender);
    event CancelVote(uint256 paykikAmount, address sender, uint256[] polls);

    address public swapAddress;
    address public holdAddress;
    address public teamAddress;

    ITRC20 immutable paykikToken;
    ITRC20 immutable usdtToken;

    IHold private holdContract;

    uint256 public constant deadlineDelta = 60 * 60;
//    uint256 public constant deadlineDelta = 60 * 60 * 24 * 21; // todo убрать тест!
    uint256 private constant usdtDecimals = 1e6;

    uint256 nextPollID;

    struct Poll {
        uint256 amount;
        address sendTo;
        address creator;
        uint256 totalVoted;
        uint256 deadline;
        bool sent;
    }

    mapping(uint256 => Poll) public polls;
    mapping(address => mapping(uint256 => uint256)) public pollsVotes;
    mapping(address => uint256[]) public userPolls;

    bool public notDeployed = true;

    modifier onlyOnce() {
        require(notDeployed, "This function can be called only once");
        _;
        notDeployed = !notDeployed;
    }

    modifier onlySwap() {
        require(msg.sender == address(swapAddress), "This function can be called only by Swap Contract");
        _;
    }

    constructor(address usdtErc20Addr, address paykikErc20Addr) {
        usdtToken = ITRC20(usdtErc20Addr);

        paykikToken = ITRC20(paykikErc20Addr);
    }

    function setAddresses(address _swapAddr, address _holdAddr, address _teamAddr) public onlyOnce {
        require(
            _swapAddr != address(0) && _holdAddr != address(0) && _teamAddr != address(0),
            "One of arguments is a zero adress"
        );

        swapAddress = _swapAddr;
        holdAddress = _holdAddr;
        holdContract = IHold(holdAddress);
        teamAddress = _teamAddr;
    }

    function Spend(address to, uint256 amount) external onlySwap returns (bool) {
        require(usdtToken.balanceOf(address(this)) >= amount, "There is not enough USDT on Governor contract balance");
        usdtToken.transfer(to, amount);
        return true;
    }

    function createPoll(address to, uint256 amount) public returns (uint256) {
        uint256 amountHeld;
        (amountHeld,) = holdContract.get(msg.sender);

        require(
            paykikToken.balanceOf(msg.sender) > 0 || amountHeld > 0, "This function is availible only to DAO memebers"
        );
        require(amount + usdtDecimals <= usdtToken.balanceOf(address(this)), "Entered amount exceeds the limit");

        polls[nextPollID] = Poll(amount, to, msg.sender, 0, uint256(block.timestamp) + uint256(deadlineDelta), false);

        uint256 pollID = nextPollID;

        nextPollID += 1;

        emit CreatePoll(pollID, amount, to, msg.sender, uint256(block.timestamp) + uint256(deadlineDelta));

        return pollID;
    }

    function submitVote(uint256 id) public returns (bool) {
        require(pollsVotes[msg.sender][id] == 0, "You have already submitted your vote");

        require(polls[id].deadline > block.timestamp, "This poll has expired");

        uint256 amount = paykikToken.balanceOf(msg.sender);

        if (amount > 0) {
            holdContract.depositFrom(msg.sender, polls[id].deadline, amount);
        }

        uint256 deadline;
        (deadline, amount) = holdContract.get(msg.sender);
        require(amount > 0, "You must hold more than 0 Paykik for this function");

        require(deadline >= polls[id].deadline, "Hold deadline doesn't correlate with poll deadline");

        pollsVotes[msg.sender][id] = amount;
        polls[id].totalVoted += amount;
        userPolls[msg.sender].push(id);

        emit SubmitVote(id, amount, polls[id].totalVoted, msg.sender);

        return true;
    }

    function cancelVotes() public returns (bool) {
        require(userPolls[msg.sender].length > 0, "You haven't submitted your vote yet");

        uint256 amount;
        (, amount) = holdContract.get(msg.sender);

        require(amount > 0, "You don't have any tokens on hold");

        uint256[] memory canceledPollsTemp = new uint[](userPolls[msg.sender].length);
        uint256 canceledPollsCounterTemp = 0;

        for (uint256 i = userPolls[msg.sender].length; i > 0; i--) {
            uint256 pollId = userPolls[msg.sender][i - 1];

            if (polls[pollId].deadline <= block.timestamp) {
                userPolls[msg.sender].pop();
                continue;
            }

            polls[pollId].totalVoted -= pollsVotes[msg.sender][pollId];
            pollsVotes[msg.sender][pollId] = 0;
            userPolls[msg.sender].pop();

            canceledPollsTemp[canceledPollsCounterTemp] = pollId;
            canceledPollsCounterTemp++;
        }

        uint256[] memory canceledPolls = new uint[](canceledPollsCounterTemp);
        uint256 canceledPollsCounter = 0;

        for (uint256 i = 0; i < canceledPollsTemp.length; i++) {
            if (canceledPollsTemp[i] > 0) {
                canceledPolls[canceledPollsCounter] = canceledPollsTemp[i];
                canceledPollsCounter++;
            }
        }

        holdContract.withdrawTo(msg.sender, amount);

        emit CancelVote(amount, msg.sender, canceledPolls);

        return true;
    }

    function getPoll(uint256 id) public view returns (uint256, address, address, uint256, uint256, bool) {
        require(polls[id].deadline > 0, "The entered Poll ID was not found");

        return (
            polls[id].amount,
            polls[id].sendTo,
            polls[id].creator,
            polls[id].deadline,
            polls[id].totalVoted,
            polls[id].sent
        );
    }

    function getCirculationPaykik() public view returns (uint256) {
        uint256 currentSwapBalance = paykikToken.balanceOf(swapAddress);
        uint256 currentTeamBalance = paykikToken.balanceOf(teamAddress);

        if (currentSwapBalance + currentTeamBalance > paykikToken.totalSupply()) {
            return 0;
        }
        return paykikToken.totalSupply() - (currentSwapBalance + currentTeamBalance);
    }

    function getParticipationRate(uint256 pollId) public view returns (uint256) {
        uint256 currentSwapBalance = paykikToken.balanceOf(swapAddress);

        uint256 circulatingAmount = getCirculationPaykik(); // TODO: Надо переписать тесты!

        (bool success, uint256 rate) = (polls[pollId].totalVoted).mul(100).tryDiv(circulatingAmount);
        require(success, "Patcipation rate calculation error");

        require(rate > 0, string(abi.encodePacked("Current Swap balance: ", currentSwapBalance.toString())));

        return rate;
    }

    function finishPoll(uint256 id) public returns (bool) {
        require(polls[id].deadline > 0, "The entered Poll ID was not found");

        require(polls[id].deadline < block.timestamp, "This Poll is still active");

        require(!polls[id].sent, "The transaction was already sent");

        require(
            usdtToken.balanceOf(address(this)) >= polls[id].amount + usdtDecimals,
            "Not enough funds on the contract balance"
        );

        uint256 participationRate = getParticipationRate(id);

        require(
            participationRate >= 51,
            string(
                abi.encodePacked(
                    "The share of tokens in this poll must be more than 50%. Current partcipation rate:",
                    participationRate.toString()
                )
            )
        );

        bool success = usdtToken.transfer(polls[id].sendTo, polls[id].amount);

        require(success, "Transaction execution error");

        polls[id].sent = true;

        emit FinishPoll(participationRate, polls[id].sendTo, polls[id].amount);

        return true;
    }
}
