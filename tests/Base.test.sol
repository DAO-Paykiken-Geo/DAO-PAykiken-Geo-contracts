// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./Setup.test.sol";

contract Base is Setup {
    address[] accounts;

    function _buyPaykikErc20(address clientAddr, uint256 amount) internal returns (bool) {
        uint256 buyRate = swapDex.getBuyRate(amount);

        vm.startPrank(clientAddr);
        bool result = usdtErc20.approve(address(swapDex), buyRate);
        vm.stopPrank();

        assertEq(result, true);

        vm.startPrank(clientAddr);
        result = swapDex.buy(amount);
        vm.stopPrank();

        assertEq(result, true);
        return true;
    }

    function _getUsdtErc20(address who, uint256 amountToSend) internal {
        vm.startPrank(usdtOwner);
        usdtErc20.transfer(who, amountToSend);
        vm.stopPrank();
    }

    function _approvePaykikForHold(address holder, uint256 amount) internal {
        uint256 amount = paykikErc20.balanceOf(holder);
        vm.startPrank(holder);
        paykikErc20.approve(address(holdContract), amount);
        vm.stopPrank();
    }
}
