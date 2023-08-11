// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import "./Base.test.sol";

abstract contract HoldTestBase is Base {
    function _buyPaykiks(address buyer, uint256 amountToBuy) internal {
        uint256 amountToBuyRecorderByRate = swapDex.getBuyRate(amountToBuy);

        vm.startPrank(buyer);
        usdtErc20.approve(address(swapDex), amountToBuyRecorderByRate);
        vm.stopPrank();

        vm.startPrank(buyer);
        swapDex.buy(amountToBuy);
        vm.stopPrank();
    }
}

contract HoldTest is HoldTestBase {
    uint256 amountToBuy;

    /*
        Covered methods:
            [+] depositFrom
            [+] deposit
            [+] withdraw
    */
    function setUp() public override {
        super.setUp();
        amountToBuy = 2 * 1e3 * 10 ** paykikErc20.decimals();
    }

    function testRevert__depositFrom__checkAllowance() public {
        /*
            1. User buys paykiks
            2. User triggers depositFrom from InCome/Governor contracts (we do that from HoldTest)
            3. User got revert with message "Aprooved tokens is less than requested amount"
        */
        _buyPaykiks(alice, amountToBuy);

        vm.expectRevert();
        holdContract.depositFrom(
            alice,
            block.timestamp + 60 * 60 * 24,
            amountToBuy
        );
    }

    function test__depositFrom__bool_true() public {
        /*
            1. User buys paykiks
            2. User triggers depositFrom from InCome/Governor contracts (we do that from HoldTest)
            3. User approves some "amount" of paykiks
            4. User deposit that "amount" of paykiks
        */

        _buyPaykiks(alice, amountToBuy);

        // Implementation of step #3
        vm.startPrank(alice);
        paykikErc20.approve(address(holdContract), amountToBuy);
        vm.stopPrank();

        bool isOk = holdContract.depositFrom(
            alice,
            block.timestamp + 60 * 60 * 24,
            amountToBuy
        );

        assertEq(isOk, true);
    }

    function test__deposit__checkAllowance() public {
        /*
            1. User buys paykiks
            2. User tries to deposit "amount" of paykiks on Hold contract
            3. User got revert with message "Aprooved tokens is less than requested amount"
        */

        _buyPaykiks(alice, amountToBuy);

        vm.expectRevert(bytes("Aprooved tokens is less than requested amount"));
        vm.startPrank(alice);
        holdContract.deposit(block.timestamp + 60 * 60 * 24, amountToBuy);
        vm.stopPrank();
    }

    function test__deposit__bool_true() public {
        /*
            1. User buys paykiks
            2. User approves some "amount" of paykiks for Hold contract
            3. User deposits "amount" of paykiks on Hold contract
        */
        _buyPaykiks(alice, amountToBuy);

        vm.startPrank(alice);
        paykikErc20.approve(address(holdContract), amountToBuy);
        vm.stopPrank();

        vm.startPrank(alice);
        bool isOk = holdContract.deposit(
            block.timestamp + 60 * 60 * 24,
            amountToBuy
        );
        vm.stopPrank();

        assertEq(isOk, true);
    }

    function test__withdraw__bool_true() public {
        /*
            1. User deposited paykiks on Hold contract
            2. Time has passed according to deadline of deposit
            3. User withdraw paykiks from hold
         */
        address withdrawAddress = alice;
        test__depositFrom__bool_true();

        // Mock block.timestamp that implement #2 step
        vm.warp(1 * 1e18);

        vm.startPrank(alice);
        bool isOk = holdContract.withdraw();
        vm.stopPrank();

        assertEq(isOk, true);
    }

    function test__withdraw__holdNotFinished() public {
        /*
            1. User has deposited paykiks on Hold contract
            3. User tries to withdraw paykiks from hold
            4. User got revert with message "Hold is still active"
        */
        address withdrawAddress = alice;
        test__depositFrom__bool_true();

        vm.expectRevert(bytes("Hold is still active"));
        vm.startPrank(alice);
        bool isOk = holdContract.withdraw();
        vm.stopPrank();
    }
}
