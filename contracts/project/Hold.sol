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

contract Hold {
    using SafeMath for uint256;

    event Deposit(uint256 timePeriod, uint256 amount, address sender);
    event DepositFrom(address from, uint256 timePeriod, uint256 amount);
    event Withdraw(address sender, uint256 amount);
    event WithdrawTo(address sender, uint256 amount);

    address public governorAddress;
    uint256 nextHoldID;

    struct Holder {
        uint256 deadline;
        uint256 amount; // <2m
    }

    mapping(address => Holder) public holds;
    ITRC20 paykikToken;

    constructor(address _paykikTokenAddress, address _governorAddress) {
        nextHoldID = 0;
        paykikToken = ITRC20(address(_paykikTokenAddress));
        governorAddress = _governorAddress;
    }

    function depositFrom(address from, uint256 timePeriod, uint256 amount) external returns (bool) {
        require(paykikToken.allowance(from, address(this)) >= amount, "Aprooved tokens is less than requested amount");

        require(paykikToken.transferFrom(from, address(this), amount), "User withdrawal error");

        holds[from].amount = holds[from].amount.add(amount);
        holds[from].deadline = timePeriod;

        emit DepositFrom(from, timePeriod, amount);

        return true;
    }

    function deposit(uint256 timePeriod, uint256 amount) public returns (bool) {
        require(paykikToken.allowance(msg.sender, address(this)) >= amount, "Aprooved tokens is less than requested amount");

        require(paykikToken.transferFrom(msg.sender, address(this), amount), "User withdrawal error");

        holds[msg.sender].amount = holds[msg.sender].amount.add(amount);
        holds[msg.sender].deadline = timePeriod;

        emit Deposit(timePeriod, amount, msg.sender);

        return true;
    }

    function withdrawTo(address holderAddr, uint256 amount) external returns (bool) {
        require(msg.sender == governorAddress, "Withdrawal is not allowed");
        require(holds[holderAddr].amount >= amount, "Entered token amount exceeds hold amount");
        require(paykikToken.transfer(holderAddr, amount), "Withdrawal transfer error");
        holds[holderAddr].amount -= amount;

        emit WithdrawTo(holderAddr, amount);

        return true;
    }

    function withdraw() public returns (bool) {
        require(holds[msg.sender].deadline < block.timestamp, "Hold is still active");

        require(paykikToken.transfer(msg.sender, holds[msg.sender].amount), "Withdrawal transfer error");

        emit Withdraw(msg.sender, holds[msg.sender].amount);

        holds[msg.sender].amount = 0;
        return true;
    }

    function get(address a) public view returns (uint256, uint256) {
        return (holds[a].deadline, holds[a].amount);
    }

    function getMe() public view returns (uint256, uint256) {
        return (holds[msg.sender].deadline, holds[msg.sender].amount);
    }
}
