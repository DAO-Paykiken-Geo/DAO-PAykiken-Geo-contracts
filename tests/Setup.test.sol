// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import {Swap} from "../contracts/project/Swap.sol";
import {UsdtTest} from "../contracts/demo_erc20/Usdt.sol";
import {PaykikTest} from "../contracts/demo_erc20/Paykik.sol";
import {Governor} from "../contracts/project/Governor.sol";
import {Hold} from "../contracts/project/Hold.sol";
import {Team} from "../contracts/project/Team.sol";

contract Setup is Test {
    PaykikTest public paykikErc20;
    UsdtTest public usdtErc20;

    Swap public swapDex;
    Governor public governorDao;
    Hold public holdContract;
    Team public teamContract;

    address public usdtOwner;
    address public paykikOwner;
    address public mike;
    address public eric;
    address public alice;
    address public bob;
    address public receiver;
    address[32] public teamAddresses;

    address[32] public mockedTeamAccounts;

    function sendInitialAmountOfPaykikToSwap() internal {
        vm.startPrank(paykikOwner);
        paykikErc20.transfer(address(swapDex), 18 * 1e5 * 10 ** paykikErc20.decimals());
        vm.stopPrank();
    }

    function deployTeamContract(address paykikErc20Addr) internal {
        vm.startPrank(mike);
        teamAddresses = [
            vm.addr(10),
            vm.addr(11),
            vm.addr(12),
            vm.addr(13),
            vm.addr(14),
            vm.addr(15),
            vm.addr(16),
            vm.addr(17),
            vm.addr(18),
            vm.addr(19),
            vm.addr(20),
            vm.addr(21),
            vm.addr(22),
            vm.addr(23),
            vm.addr(24),
            vm.addr(25),
            vm.addr(26),
            vm.addr(27),
            vm.addr(28),
            vm.addr(29),
            vm.addr(30),
            vm.addr(31),
            vm.addr(32),
            vm.addr(33),
            vm.addr(34),
            vm.addr(35),
            vm.addr(36),
            vm.addr(37),
            vm.addr(38),
            vm.addr(39),
            vm.addr(40),
            vm.addr(41)
        ];

        teamContract = new Team(paykikErc20Addr, teamAddresses);
        vm.stopPrank();
    }

    function setSwapAddrOnTeam(address swapAddr) internal {
        vm.startPrank(mike);
        bool result = teamContract.SetSwap(swapAddr);
        vm.stopPrank();
        require(result, "Swap address can't be established");
    }

    function deployPaykikErc20() internal {
        // Set up Paykik with paykikOwner private key
        paykikOwner = vm.addr(2);
        vm.startPrank(paykikOwner);
        paykikErc20 = new PaykikTest();
        vm.stopPrank();
    }

    function deployUsdtErc20() internal {
        // Set up USDT with usdtOwner private key
        usdtOwner = vm.addr(1);
        vm.startPrank(usdtOwner);
        usdtErc20 = new UsdtTest();
        vm.stopPrank();
    }

    function sendInitialAmountOfPaykiksToTeam() internal {
        vm.startPrank(paykikOwner);
        paykikErc20.transfer(address(teamContract), 2*1e5*10**paykikErc20.decimals());
        vm.stopPrank();
    }

    function setUpAccountBalances() internal {
        vm.startPrank(usdtOwner);
        usdtErc20.transfer(mike, 2 * 1e4 * 10 ** usdtErc20.decimals());
        usdtErc20.transfer(eric, 2 * 1e4 * 10 ** usdtErc20.decimals());
        usdtErc20.transfer(alice, 2 * 1e4 * 10 ** usdtErc20.decimals());
        usdtErc20.transfer(bob, 2 * 1e4 * 10 ** usdtErc20.decimals());

        // Set up initial balance for Governor
        usdtErc20.transfer(address(governorDao), 1 * 10 ** usdtErc20.decimals());
        vm.stopPrank();
    }

    function setUp() public virtual {
        // Set Up Utility Tokens
        deployPaykikErc20();
        deployUsdtErc20();

        // Set up clients
        mike = vm.addr(3);
        eric = vm.addr(4);
        alice = vm.addr(5);
        bob = vm.addr(6);
        receiver = vm.addr(30);

        // Set up project contracts
        governorDao = new Governor(address(usdtErc20), address(paykikErc20));
        holdContract = new Hold(address(paykikErc20), address(governorDao));

        // Set up initial state (account balances)
        setUpAccountBalances();
        deployTeamContract(address(paykikErc20));
        swapDex = new Swap(
            address(usdtErc20),
            address(paykikErc20),
            address(governorDao),
            address(teamContract)
        );
        sendInitialAmountOfPaykikToSwap();
        setSwapAddrOnTeam(address(swapDex));
        sendInitialAmountOfPaykiksToTeam();
        governorDao.setAddresses(address(swapDex), address(holdContract), address(teamContract));
    }
}
