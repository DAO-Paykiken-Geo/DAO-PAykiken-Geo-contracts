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
import "./IGovernor.sol";
import {SafeMath} from "../base/SafeMath.sol";
import {Math} from "../base/Math.sol";

contract Swap {
    using SafeMath for uint256;
    using SafeMath for int256;
    using Math for uint256;

    event Buy(uint256 amount, uint256 payUsdt, address sender);
    event Sell(uint256 amount, uint256 payoutUsdt, address sender);

    ITRC20 usdtToken;
    ITRC20 paykikToken;
    IGovernor governor;

    address governorAddress;
    address teamAddress;

    uint256 public constant usdtDecimals = 6;
    uint256 public constant paykikDecimals = 8;
    mapping(address => uint256) public totalBuy;
    uint256 public constant maxBuy = 7999 * (10 ** paykikDecimals);

    constructor(address _usdtToken, address _paykikToken, address _governorAddress, address _teamAddress) {
        usdtToken = ITRC20(_usdtToken);

        paykikToken = ITRC20(_paykikToken);

        governorAddress = _governorAddress;
        governor = IGovernor(_governorAddress);

        teamAddress =  _teamAddress;
    }

    function balanceOf() public view returns (uint256, uint256) {
        return (usdtToken.balanceOf(governorAddress), paykikToken.balanceOf(address(this)));
    }

    function pow(uint256 paykikPoolSize) public pure returns (uint256) {
        uint256 poolFinder;
        uint256 tokenPrice = 1000000 * 1e18;

        if (paykikPoolSize == 0) {
            return 1 * (10 ** usdtDecimals) * 1e18;
        }

        if (paykikPoolSize == 1) {
            return 1000001 * 1e18;
        }

        for (uint256 i = 0; i < 21; i++) {
            uint256 _tokenPrice;
            (poolFinder, _tokenPrice) = findInterval(poolFinder, paykikPoolSize);
            tokenPrice = tokenPrice * _tokenPrice / 1e24;

            if (int256(paykikPoolSize) - int256(poolFinder) <= 1) {
                break;
            }
        }

        if (int256(paykikPoolSize) - int256(poolFinder) == 1) {
            tokenPrice = tokenPrice * 1000001 * 1e18 / 1e24;
        }

        return tokenPrice;
    }

    function findInterval(uint256 initialPoolPosition, uint256 circulation) public pure returns (uint256, uint256) {
        uint256 tokenPrice = 1000001 * 1e18;
        uint256 stages = (circulation - initialPoolPosition).log2();

        for (uint256 i = 0; i < stages; i++) {
            tokenPrice = tokenPrice * tokenPrice / 1e24;
        }

        return (initialPoolPosition + 2 ** stages, tokenPrice);
    }

    function calculateRemainderPrice(uint256 circulation, uint256 amount, bool isBuy)
        public
        view
        returns (uint256)
    {
        uint256 remainder = amount.sub((amount.div(10 ** paykikDecimals)).mul(10 ** paykikDecimals));
        if (remainder > 0) {
            uint256 tokenPrice;
            uint256 circulation_base = circulation / 10 ** paykikDecimals;
            if (isBuy) {
                // buy
                uint256 circulation_buy = circulation_base + amount / 10 ** paykikDecimals;
                uint256 tokenPriceAfterBuy = pow(circulation_buy);
                return tokenPriceAfterBuy.mul(remainder).div(1e24);
            } else {
                // sell
                require(circulation_base >= amount / 10 ** paykikDecimals, "The Paykik amount is incorrect");
                uint256 amountDiv = amount / 10 ** paykikDecimals;
                uint256 circulation_sell = circulation_base - amountDiv;
                uint256 tokenPriceAfterSell = pow(circulation_sell);
                return tokenPriceAfterSell.mul(remainder).div(1e24);
            }
        }

        return 0;
    }

    function getTotalBuy() public view returns (uint256) {
        return totalBuy[msg.sender];
    }

    function calculate(uint256 circulation, uint256 usdtPool, uint256 amount, bool isBuy)
    public
    pure
    returns (uint256)
    {
        uint256 difference = paykikDecimals - usdtDecimals;
        uint256 q = 1 * 10 ** difference * 1e16;
        uint256 baseTokenPrice = 1 * 10 ** paykikDecimals * 1e16;

        usdtPool = usdtPool * 10 ** difference * 1e16;

        uint256 currentTokenPrice = baseTokenPrice + q.mul(usdtPool).div(1e24);
        uint256 tokenPrice = pow(circulation / 1e8);

        uint256 a1 = currentTokenPrice.mul(1e24).div(tokenPrice);

        uint256 S = (a1 * (tokenPrice.mul(baseTokenPrice + q).div(1e24) - baseTokenPrice) / 1e24) * 1e6;

        if (S > usdtPool) {
            a1 = a1.mul(1e24).div(S.mul(1e24).div(usdtPool));
            S = (a1 * (tokenPrice - baseTokenPrice) / 1e24) * 1e6;
        }

        uint256 circulation_base = circulation / 10 ** paykikDecimals;

        if (isBuy) {
            uint256 circulation_buy = circulation_base + amount / 10 ** paykikDecimals;
            uint256 tokenPriceAfterBuy = pow(circulation_buy);
            uint256 S_buy = (a1 * (tokenPriceAfterBuy.mul(1e24 + 1e18).div(1e24) - baseTokenPrice) / 1e24) * 1e6;
            uint256 totalPayBuy = S_buy - S;
            return totalPayBuy / 1e16;
        } else {
            require(circulation_base >= amount / 10 ** paykikDecimals, "The Paykik amount is incorrect");
            uint256 amountDiv = amount / 10 ** paykikDecimals;
            uint256 circulation_sell = circulation_base - amountDiv;
            uint256 tokenPriceAfterSell = pow(circulation_sell);
            uint256 S_sell = (a1 * (tokenPriceAfterSell.mul(1e24 + 1e18).div(1e24) - baseTokenPrice) / 1e24) * 1e6;
            uint256 totalPaySell = S.sub(S_sell);

            return totalPaySell / 1e16;
        }
    }

    function getTerm(uint256 currentUsdtPool) public pure returns (uint256) {
        uint256 difference = paykikDecimals - usdtDecimals;
        uint256 q = 1 * 10 ** difference;
        uint256 baseTokenPrice = 1 * 10 ** paykikDecimals;
        return baseTokenPrice + q.mul(currentUsdtPool).div(1e8);
    }

    function getCirculationPaykik() public view returns(uint256) {
        uint256 currentSwapBalance = paykikToken.balanceOf(address(this));
        uint256 currentTeamBalance = paykikToken.balanceOf(teamAddress);
        if (currentSwapBalance + currentTeamBalance  > paykikToken.totalSupply()) {
            return 0;
        }
        return paykikToken.totalSupply() - (currentSwapBalance + currentTeamBalance );
    }

    function getBuyRate(uint256 amountBase) public view returns (uint256) {
        uint256 paykikPool = paykikToken.balanceOf(address(this));

        uint256 usdtPool = usdtToken.balanceOf(governorAddress);

        uint256 totalPay = 0;
        uint256 amount = amountBase;

        require(usdtPool >= 1 * 1e6, "Governor pool should be more than 1 USDT");

        require(amountBase <= paykikPool, "Requested amount exceeds Paykik availible for purchase");

        uint256 paykikCirculation = getCirculationPaykik();

        totalPay = totalPay.add(calculate(paykikCirculation, usdtPool, amountBase, true));
        totalPay = totalPay.add(calculateRemainderPrice(paykikCirculation, amountBase, true));

        return totalPay;
    }

    function buy(uint256 amountBase) public returns (bool) {
        require(amountBase >= 10 ** paykikDecimals, "Swap amount must be more than 1 Paykik");

        require(totalBuy[msg.sender].add(amountBase) <= maxBuy, "You can't purchase more than 7999 Paykik");

        require(paykikToken.balanceOf(address(this)) >= amountBase, "Requested amount exceeds Paykik availible for purchase");

        uint256 totalPay = getBuyRate(amountBase);
        uint256 value = totalPay.div(10 ** (paykikDecimals.sub(usdtDecimals)));

        require(
            usdtToken.allowance(msg.sender, address(this)) >= value,
            "Aprooved USDT is less than requested amount"
        );

        require(usdtToken.transferFrom(msg.sender, governorAddress, value), "User withdrawal error");

        require(paykikToken.transfer(msg.sender, amountBase), "Contract withdrawal error");

        totalBuy[msg.sender] = totalBuy[msg.sender].add(amountBase);

        emit Buy(amountBase, value, msg.sender);

        return true;
    }

    function getSellRate(uint256 amountBase) public view returns (uint256) {
        uint256 paykikPool = paykikToken.balanceOf(address(this));
        uint256 usdtPool = usdtToken.balanceOf(governorAddress);
        uint256 totalPay;

        uint256 paykikCirculation = getCirculationPaykik();
        totalPay = totalPay.add(calculate(paykikCirculation, usdtPool, amountBase, false));
        totalPay = totalPay.add(calculateRemainderPrice(paykikCirculation, amountBase, true));
        totalPay = totalPay.sub(totalPay.mul(1e8).div(100).div(1e8));

        return totalPay;
    }

    function sell(uint256 amountBase) public returns (bool) {
        require(amountBase >= 10 ** paykikDecimals, "Swap amount must be more than 1 Paykik");

        require(paykikToken.allowance(msg.sender, address(this)) >= amountBase, "Aprooved tokens is less than requested amount");

        uint256 totalPay = getSellRate(amountBase);

        require(
            totalPay.div(10 ** (paykikDecimals - usdtDecimals)) + 10**usdtDecimals <= usdtToken.balanceOf(governorAddress),
            "Cant sell, USDT Governor pool too small"
        );

        require(paykikToken.transferFrom(msg.sender, address(this), amountBase), "User withdrawal error");

        require(
            governor.Spend(msg.sender, totalPay.div(10 ** (paykikDecimals - usdtDecimals))),
            "Contract withdrawal error"
        );
        if (amountBase > totalBuy[msg.sender]) {
            totalBuy[msg.sender] = 0;
        } else {
            totalBuy[msg.sender] = totalBuy[msg.sender].sub(amountBase);
        }

        emit Sell(amountBase, totalPay.div(10 ** (paykikDecimals - usdtDecimals)), msg.sender);

        return true;
    }
}
