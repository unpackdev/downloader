pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./math.sol";
import "./stores-mainnet.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

import "./variables.sol";

import "./interfaces.sol";

abstract contract Helpers is DSMath, Stores, Variables {
    using SafeERC20 for IERC20;

    function _paybackBehalfOne(AaveInterface aave, address token, uint amt, uint rateMode, address user) private {
        address _token = token == ethAddr ? wethAddr : token;
        aave.repay(_token, amt, rateMode, user);
    }

    function _PaybackStable(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint256[] memory amts,
        address user
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                _paybackBehalfOne(aave, tokens[i], amts[i], 1, user);
            }
        }
    }

    function _PaybackVariable(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint256[] memory amts,
        address user
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                _paybackBehalfOne(aave, tokens[i], amts[i], 2, user);
            }
        }
    }

    function _PaybackCalculate(
        AaveInterface aave,
        AaveDataRaw memory _data,
        address sourceDsa
    ) internal returns (
        uint[] memory stableBorrow,
        uint[] memory variableBorrow,
        uint[] memory totalBorrow
    ) {
        uint _len = _data.borrowTokens.length;
        stableBorrow = new uint256[](_len);
        variableBorrow = new uint256[](_len);
        totalBorrow = new uint256[](_len);

        for (uint i = 0; i < _len; i++) {
            require(isSupportedToken[_data.borrowTokens[i]], "token-not-enabled");
            address _token = _data.borrowTokens[i] == ethAddr ? wethAddr : _data.borrowTokens[i];
            _data.borrowTokens[i] = _token;

            (
                ,
                uint stableDebt,
                uint variableDebt,
                ,,,,,
            ) = aaveData.getUserReserveData(_token, sourceDsa);


            stableBorrow[i] = _data.stableBorrowAmts[i] == uint(-1) ? stableDebt : _data.stableBorrowAmts[i];
            variableBorrow[i] = _data.variableBorrowAmts[i] == uint(-1) ? variableDebt : _data.variableBorrowAmts[i];

            totalBorrow[i] = add(stableBorrow[i], variableBorrow[i]);

            if (totalBorrow[i] > 0) {
                IERC20(_token).safeApprove(address(aave), totalBorrow[i]);
            }
            aave.borrow(_token, totalBorrow[i], 2, 3288, address(this));
        }
    }

    function _getAtokens(
        address dsa,
        address[] memory supplyTokens,
        uint[] memory supplyAmts
    ) internal returns (
        uint[] memory finalAmts
    ) {
        finalAmts = new uint256[](supplyTokens.length);
        for (uint i = 0; i < supplyTokens.length; i++) {
            require(isSupportedToken[supplyTokens[i]], "token-not-enabled");
            address _token = supplyTokens[i] == ethAddr ? wethAddr : supplyTokens[i];
            (address _aToken, ,) = aaveData.getReserveTokensAddresses(_token);
            ATokenInterface aTokenContract = ATokenInterface(_aToken);
            uint _finalAmt;
            if (supplyAmts[i] == uint(-1)) {
                _finalAmt = aTokenContract.balanceOf(dsa);
            } else {
                _finalAmt = supplyAmts[i];
            }
            require(aTokenContract.transferFrom(dsa, address(this), _finalAmt), "_getAtokens: atokens transfer failed");

            _finalAmt = wmul(_finalAmt, fee);
            finalAmts[i] = _finalAmt;

        }
    }

    function isPositionSafe() internal view returns (bool isOk) {
        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());
        (,,,,,uint healthFactor) = aave.getUserAccountData(address(this));
        uint minLimit = wdiv(1e18, safeRatioGap);
        isOk = healthFactor > minLimit;
        require(isOk, "position-at-risk");
    }

    function getTokensPrices(address[] memory tokens) internal view returns(uint[] memory tokenPricesInEth) {
        tokenPricesInEth = AavePriceOracle(aaveProvider.getPriceOracle()).getAssetsPrices(tokens);
    }
    
    // Liquidation threshold
    function getTokenLt(address[] memory tokens) internal view returns (uint[] memory decimals, uint[] memory tokenLts) {
        uint _len = tokens.length;
        decimals = new uint[](_len);
        tokenLts = new uint[](_len);
        for (uint i = 0; i < _len; i++) {
            (decimals[i],,tokenLts[i],,,,,,,) = aaveData.getReserveConfigurationData(tokens[i]);
        }
    }

    function convertTo18(uint amount, uint decimal) internal pure returns (uint) {
        return amount * (10 ** (18 - decimal));
    }

    /*
     * Checks the position to migrate should have a safe gap from liquidation 
    */
    function _checkRatio(AaveData memory data) public view {
        uint[] memory supplyTokenPrices = getTokensPrices(data.supplyTokens);
        (uint[] memory supplyDecimals, uint[] memory supplyLts) = getTokenLt(data.supplyTokens);

        uint[] memory borrowTokenPrices = getTokensPrices(data.borrowTokens);
        (uint[] memory borrowDecimals,) = getTokenLt(data.borrowTokens);
        uint netSupply;
        uint netBorrow;
        uint liquidation;
        for (uint i = 0; i < data.supplyTokens.length; i++) {
            uint _amt = wmul(convertTo18(data.supplyAmts[i], supplyDecimals[i]), supplyTokenPrices[i]);
            netSupply += _amt;
            liquidation += (_amt * supplyLts[i]) / 10000; // convert the number 8000 to 0.8
        }
        for (uint i = 0; i < data.borrowTokens.length; i++) {
            uint _amt = wmul(convertTo18(data.borrowAmts[i], borrowDecimals[i]), borrowTokenPrices[i]);
            netBorrow += _amt;
        }
        uint _dif = wmul(netSupply, sub(1e18, safeRatioGap));
        require(netBorrow < sub(liquidation, _dif), "position-is-risky-to-migrate");
    }

}