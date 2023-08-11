// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";
import {Base} from "./Base.test.sol";
import {Math} from "../contracts/base/Math.sol";
import {SafeMath} from "../contracts/base/SafeMath.sol";
import {SwapTestBase} from "./Swap.test.sol";

abstract contract TeamTestBase is SwapTestBase {
    function _unlockFrozenPaykiksOnTeam() internal override {
        vm.startPrank(vm.addr(10));
        teamContract.send();
        vm.stopPrank();

        uint256 teamBalance = paykikErc20.balanceOf(address(teamContract));
    }

    function _buyMaxBuyByAmountOfAccounts(uint256 amountOfAccounts, uint256 salt) internal {
        address[] memory users = new address[](amountOfAccounts);
        for (uint256 i; i < users.length; i++) {
            users[i] = _createUserEoa(i + salt);
        }

        for (uint256 j; j < users.length; j++) {
            if (paykikErc20.balanceOf(address(swapDex)) > swapDex.maxBuy()) {
                _buyPaykiks(users[j], swapDex.maxBuy());
            }
        }
    }
}

contract TestTeam is TeamTestBase {
    using Math for uint256;
    using SafeMath for uint256;

    using stdStorage for StdStorage;

    StdStorage public stdstorage;

    function test__A_send__uint256() public {
        _buyPaykikErc20(mike, 7 * 1e3 * 10 ** paykikErc20.decimals());
        _buyPaykikErc20(eric, 7 * 1e3 * 10 ** paykikErc20.decimals());
        _buyPaykikErc20(bob, 7 * 1e3 * 10 ** paykikErc20.decimals());
        _buyPaykikErc20(alice, 7 * 1e3 * 10 ** paykikErc20.decimals());

        uint256 teamBalance = paykikErc20.balanceOf(address(teamContract));

        vm.startPrank(vm.addr(10));
        teamContract.send();
        vm.stopPrank();

        uint256 oneOfParticipants = paykikErc20.balanceOf(vm.addr(10));
        assertEq(oneOfParticipants > 0, true);
    }

    function test__PoolOverTwoHundred() public {
        address[] memory users = _sellEntirePaykikPool();
        _unlockFrozenPaykiksOnTeam();
    }

    function test__stagedWithdrawal() public {
        uint256 paykiksEqualParts = (paykikErc20.balanceOf(address(swapDex))).div(swapDex.maxBuy());

        uint256 fiftyPercent = paykiksEqualParts.mul(50).div(100);
        uint256 thirtyPercent = paykiksEqualParts.mul(30).div(100);
        uint256 twentyPercent = paykiksEqualParts.mul(20).div(100);

        _buyMaxBuyByAmountOfAccounts(twentyPercent, 999);

        console.log("SWAP PAYKIKS POOL: %d", paykikErc20.balanceOf(address(swapDex)));
        console.log("[ BEFORE ] TEAM PAYKIKS POOL: %d", paykikErc20.balanceOf(address(teamContract)));

        vm.startPrank(vm.addr(10));
        teamContract.send();
        vm.stopPrank();

        console.log("[ AFTER ] TEAM PAYKIKS POOL: %d\n", paykikErc20.balanceOf(address(teamContract)));

        _buyMaxBuyByAmountOfAccounts(thirtyPercent, 9999);
        console.log("SWAP PAYKIKS POOL: %d", paykikErc20.balanceOf(address(swapDex)));
        console.log("[ BEFORE ] TEAM PAYKIKS POOL: %d", paykikErc20.balanceOf(address(teamContract)));

        vm.startPrank(vm.addr(10));
        teamContract.send();
        vm.stopPrank();

        console.log("[ AFTER ] TEAM PAYKIKS POOL: %d\n", paykikErc20.balanceOf(address(teamContract)));

        _buyMaxBuyByAmountOfAccounts(fiftyPercent, 99999);

        console.log("SWAP PAYKIKS POOL: %d", paykikErc20.balanceOf(address(swapDex)));
        console.log("[ BEFORE ] TEAM PAYKIKS POOL: %d", paykikErc20.balanceOf(address(teamContract)));

        vm.startPrank(vm.addr(10));
        teamContract.send();
        vm.stopPrank();


        console.log("[ AFTER ] TEAM PAYKIKS POOL: %d", paykikErc20.balanceOf(address(teamContract)));
    }
}
