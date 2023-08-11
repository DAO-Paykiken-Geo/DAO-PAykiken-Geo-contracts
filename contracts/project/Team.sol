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

import {ITRC20} from "../base/ITRC20.sol";
import {SafeMath} from "../base/SafeMath.sol";
import {Math} from "../base/Math.sol";

contract Team {
    using SafeMath for uint256;

    uint256 public initialBalance;
    uint256 public totalSent;
    address[] public team;
    address public swapAddress;

    uint256 public lastAvailable;
    uint256 public initialSwapBalance;
    uint256 public constant paykikDecimals = 8;
    ITRC20 paykikToken;

    function SetSwap(address swapAddr) public returns (bool) {
        if (swapAddress == address(0)) {
            swapAddress = swapAddr;
            return true;
        }

        return false;
    }

    constructor(address paykikenAddr, address[32] memory teamAddresses) {
        paykikToken = ITRC20(paykikenAddr);
        initialBalance = 200000 * 10 ** paykikDecimals;
        initialSwapBalance = 1800000 * 10 ** paykikDecimals;
        totalSent = 0;
        team = [
            teamAddresses[0],
            teamAddresses[1],
            teamAddresses[2],
            teamAddresses[3],
            teamAddresses[4],
            teamAddresses[5],
            teamAddresses[6],
            teamAddresses[7],
            teamAddresses[8],
            teamAddresses[9],
            teamAddresses[10],
            teamAddresses[11],
            teamAddresses[12],
            teamAddresses[13],
            teamAddresses[14],
            teamAddresses[15],
            teamAddresses[16],
            teamAddresses[17],
            teamAddresses[18],
            teamAddresses[19],
            teamAddresses[20],
            teamAddresses[21],
            teamAddresses[22],
            teamAddresses[23],
            teamAddresses[24],
            teamAddresses[25],
            teamAddresses[26],
            teamAddresses[27],
            teamAddresses[28],
            teamAddresses[29],
            teamAddresses[30],
            teamAddresses[31]
        ];
    }

    function send() public returns (uint256) {
        uint256 swapBalance = paykikToken.balanceOf(swapAddress);
        uint256 teamBalance = paykikToken.balanceOf(address(this));

        require(teamBalance > 0, "Team balance too low");

        bool found = false;
        for (uint256 i = 0; i < team.length; i++) {
            if (team[i] == msg.sender) {
                found = true;
            }
        }

        require(found, "Only team members can call this function");

        uint256 toSendTotal;

        if (swapBalance == 0) {
            toSendTotal = initialBalance.sub(totalSent);
        } else {
            toSendTotal = initialBalance.sub(initialBalance.mul(1e6).div(initialSwapBalance.mul(1e6).div(swapBalance)));
        }

        require(toSendTotal > lastAvailable, "Withdraw unavailable");
        lastAvailable = toSendTotal;

        uint256 toSend = toSendTotal.sub(totalSent);

        if (toSend > teamBalance) {
            toSend = teamBalance;
        }

        uint256 toSendPerUser = toSend.div(team.length);

        for (uint256 i = 0; i < team.length; i++) {
            paykikToken.transfer(team[i], toSendPerUser);
        }

        totalSent = totalSent.add(toSend);

        return toSendTotal;
    }
}
