// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

import "./IBEP20.sol";
import "./IFlashLoanReceiver.sol";
import "./IQToken.sol";
import "./IWETH.sol";
import "./SafeToken.sol";


contract FlashLoanReceiver is IFlashLoanReceiver {
    using SafeMath for uint;

    address private constant qBNB = 0xbE1B5D17777565D67A5D2793f879aBF59Ae5D351;
    address private constant qBTC = 0xd055D32E50C57B413F7c2a4A052faF6933eA7927;
    address private constant qETH = 0xb4b77834C73E9f66de57e6584796b034D41Ce39A;
    address private constant qUSDC = 0x1dd6E079CF9a82c91DaF3D8497B27430259d32C2;
    address private constant qUSDT = 0x99309d2e7265528dC7C3067004cC4A90d37b7CC3;
    address private constant qDAI = 0x474010701715658fC8004f51860c90eEF4584D2B;
    address private constant qBUSD = 0xa3A155E76175920A40d2c8c765cbCB1148aeB9D1;
    address private constant qCAKE = 0xaB9eb4AE93B705b0A74d3419921bBec97F51b264;
    address private constant qQBT = 0xcD2CD343CFbe284220677C78A08B1648bFa39865;
    address private constant qMDX = 0xFF858dB0d6aA9D3fCA13F6341a1693BE4416A550;

    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant BTC = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address private constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address private constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;  // BUSD pair
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address private constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; // BUSD pair
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private constant QBT = 0x17B7163cf1Dbd286E262ddc68b553D899B93f526;
    address private constant MDX = 0x9C65AB58d8d978DB963e63f2bfB7121627e3a739;

    address private constant Qore = 0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48;

    constructor() public {
        for (uint i = 0; i < underlyingTokens().length; i++) {
            address underlying = underlyingTokens()[i];
            IBEP20(underlying).approve(Qore, uint(- 1));
            IBEP20(underlying).approve(qTokens()[i], uint(- 1));
        }
    }

    /* ========== VIEWS ========== */

    function underlyingTokens() public pure returns (address[10] memory) {
        return [WBNB, BTC, ETH, DAI, USDC, BUSD, USDT, CAKE, QBT, MDX];
    }

    function qTokens() public pure returns (address[10] memory) {
        return [qBNB, qBTC, qETH, qDAI, qUSDC, qBUSD, qUSDT, qCAKE, qQBT, qMDX];
    }

    receive() external payable {

    }

    /* ========== Qubit Flashloan Callback FUNCTION ========== */

    function executeOperation(
        address[] calldata markets,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        address,
        bytes calldata
    ) external override returns (bool) {

        for (uint i = 0; i < markets.length; i++) {
            uint amountIncludingFee = amounts[i].add(fees[i]);
            address underlying = IQToken(markets[i]).underlying();
            if (underlying == address(WBNB)) {
                IWETH(underlying).deposit{value:amountIncludingFee}();
//                SafeToken.safeTransferETH(markets[0], amountIncludingFee);
            }
        }

        return true;
    }
}
