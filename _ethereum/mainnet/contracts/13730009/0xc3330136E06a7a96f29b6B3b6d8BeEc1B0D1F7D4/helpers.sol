pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./math.sol";
import "./variables.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

import "./interfaces.sol";

abstract contract Helpers is DSMath, Variables {
    using SafeERC20 for IERC20;

    constructor (
        address _aaveLendingPoolAddressesProvider,
        address _aaveProtocolDataProvider,
        address _instaIndex,
        address _wnativeToken
    ) Variables (
        _aaveLendingPoolAddressesProvider,
        _aaveProtocolDataProvider,
        _instaIndex,
        _wnativeToken
    ){}
    function convertTo18(uint amount, uint decimal) internal pure returns (uint) {
        return amount * (10 ** (18 - decimal));
    }

    function getTokensPrices(address[] memory tokens) public view returns(uint[] memory tokenPricesInEth) {
        tokenPricesInEth = AavePriceOracle(aaveLendingPoolAddressesProvider.getPriceOracle()).getAssetsPrices(tokens);
    }

    struct ReserveConfigData {
        uint256 decimals; // token decimals
        uint256 ltv; // loan to value
        uint256 tl; // liquidationThreshold
        bool enabledAsCollateral;
        bool borrowingEnabled;
        bool isActive;
        bool isFrozen;
        uint256 availableLiquidity;
        uint256 totalOverallDebt;
    }

    function getTokenInfos(address[] memory tokens) public view returns (ReserveConfigData[] memory reserveConfigData) {
        uint _len = tokens.length;
        reserveConfigData = new ReserveConfigData[](_len);
        for (uint i = 0; i < _len; i++) {
            (
                reserveConfigData[i].decimals,
                reserveConfigData[i].ltv,
                reserveConfigData[i].tl,
                ,
                ,
                reserveConfigData[i].enabledAsCollateral,
                reserveConfigData[i].borrowingEnabled,
                ,
                reserveConfigData[i].isActive,
                reserveConfigData[i].isFrozen
            ) = aaveProtocolDataProvider.getReserveConfigurationData(tokens[i]);

            uint256 totalStableDebt;
            uint256 totalVariableDebt;

            (
                reserveConfigData[i].availableLiquidity,
                totalStableDebt,
                totalVariableDebt,
                ,
                ,
                ,
                ,
                ,
                ,
            ) = aaveProtocolDataProvider.getReserveData(tokens[i]);

            reserveConfigData[i].totalOverallDebt = add(totalStableDebt, totalVariableDebt);
        }
    }

    function sortData(Position memory position, bool isTarget) public view returns (AaveData memory aaveData) {
        uint256 supplyLen = position.supply.length;
        uint256 borrowLen = position.withdraw.length;
        aaveData.supplyAmts = new uint256[](supplyLen);
        aaveData.borrowAmts = new uint256[](borrowLen);
        aaveData.supplyTokens = new address[](supplyLen);
        aaveData.borrowTokens = new address[](borrowLen);

        for (uint256 i = 0; i < supplyLen; i++) {
            uint256 amount = position.supply[i].amount;
            address token = !isTarget ? position.supply[i].sourceToken : position.supply[i].targetToken;
            token = token == nativeToken ? wnativeToken : token;
            aaveData.supplyTokens[i] = token;
            aaveData.supplyAmts[i] = amount;
        }

        for (uint256 i = 0; i < borrowLen; i++) {
            uint256 amount = position.withdraw[i].amount;
            address token = !isTarget ? position.withdraw[i].sourceToken : position.withdraw[i].targetToken;
            token = token == nativeToken ? wnativeToken : token;
            aaveData.borrowTokens[i] = token;
            aaveData.borrowAmts[i] = amount;
        }
    }

    function checkSupplyToken(
        address userAddress,
        AaveData memory data,
        bool isTarget
    ) public view returns (
        uint256 totalSupply,
        uint256 totalMaxBorrow,
        uint256 totalMaxLiquidation,
        bool isOk
    ) {
        
        uint256[] memory supplyTokenPrices = getTokensPrices(data.supplyTokens);
        ReserveConfigData[] memory supplyReserveConfigData = getTokenInfos(data.supplyTokens);
        isOk = true;
        for (uint256 i = 0; i < data.supplyTokens.length; i++) {

            if (!isTarget) {
                (
                    uint256 supply,
                    ,
                    ,
                    ,,,,,
                ) = aaveProtocolDataProvider.getUserReserveData(data.supplyTokens[i], userAddress);

                if (supply < data.supplyAmts[i]) {
                    isOk = false;
                }
            }

            uint256 _amt = wmul(
                convertTo18(data.supplyAmts[i], supplyReserveConfigData[i].decimals),
                supplyTokenPrices[i]
            );

            totalSupply += _amt;
            totalMaxLiquidation += (_amt * supplyReserveConfigData[i].tl) / 10000; // convert the number 8000 to 0.8
            totalMaxBorrow += (_amt * supplyReserveConfigData[i].ltv) / 10000; // convert the number 8000 to 0.8
        }
    }

    function checkLiquidityToken(
        address user,
        address[] memory tokens
    ) public view returns (
        uint256 totalSupply,
        uint256 totalBorrow,
        uint256 totalMaxBorrow,
        uint256 totalMaxLiquidation
    ) {
        uint256[] memory tokensPrices = getTokensPrices(tokens);
        ReserveConfigData[] memory reserveConfigData = getTokenInfos(tokens);
        for (uint256 i = 0; i < tokens.length; i++) {
             (
                uint256 supply,
                uint stableDebt,
                uint variableDebt,
                ,,,,,
            ) = aaveProtocolDataProvider.getUserReserveData(tokens[i], user);

            uint256 supplyAmtInUnderlying = wmul(
                convertTo18(supply, reserveConfigData[i].decimals),
                tokensPrices[i]
            );

            uint256 borrowAmtInUnderlying = wmul(
                convertTo18(
                    // add(stableDebt, variableDebt), // checking only variable borrowing balance
                    variableDebt,
                    reserveConfigData[i].decimals
                ),
                tokensPrices[i]
            );

            totalSupply += supplyAmtInUnderlying;
            totalBorrow += borrowAmtInUnderlying;
            totalMaxLiquidation += (supplyAmtInUnderlying * reserveConfigData[i].tl) / 10000; // convert the number 8000 to 0.8
            totalMaxBorrow += (supplyAmtInUnderlying * reserveConfigData[i].ltv) / 10000; // convert the number 8000 to 0.8
        }
    }


    function checkBorrowToken(
        address userAddress,
        AaveData memory data,
        bool isTarget
    ) public view returns (
        uint256 totalBorrow,
        bool isOk
    ) {
        
        uint256[] memory borrowTokenPrices = getTokensPrices(data.borrowTokens);
        ReserveConfigData[] memory borrowReserveConfigData = getTokenInfos(data.borrowTokens);
        isOk = true;
        for (uint256 i = 0; i < data.borrowTokens.length; i++) {

            if (!isTarget) {
                (
                    ,
                    uint stableDebt,
                    uint variableDebt,
                    ,,,,,
                ) = aaveProtocolDataProvider.getUserReserveData(data.borrowTokens[i], userAddress);

                // uint256 borrow = stableDebt + variableDebt;  // checking only variable borrowing balance
                uint256 borrow = variableDebt;

                if (borrow < data.borrowAmts[i]) {
                    isOk = false;
                }
            }

            uint256 _amt = wmul(
                convertTo18(data.borrowAmts[i], borrowReserveConfigData[i].decimals),
                borrowTokenPrices[i]
            );
            totalBorrow += _amt;
        }
    }

    struct PositionData {
        bool isOk;
        uint256 ratio;
        uint256 maxRatio;
        uint256 maxLiquidationRatio;
        uint256 ltv; // loan to value
        uint256 currentLiquidationThreshold; // liquidationThreshold
        uint256 totalSupply;
        uint256 totalBorrow;
        uint256 price;
    }

    /*
     * Checks the position to migrate should have a safe gap from liquidation 
    */
    function _checkRatio(
        address userAddress,
        Position memory position,
        uint256 safeRatioPercentage, 
        bool isTarget
    ) public view returns (
        PositionData memory positionData
    ) {
        AaveData memory data = sortData(position, isTarget);
        bool isSupplyOk;
        bool isBorrowOk;
        uint256 totalMaxBorrow;
        uint256 totalMaxLiquidation;

        (positionData.totalSupply, totalMaxBorrow, totalMaxLiquidation, isSupplyOk) = 
            checkSupplyToken(userAddress, data, isTarget);
        (positionData.totalBorrow, isBorrowOk) =
            checkBorrowToken(userAddress, data, isTarget);

        if (positionData.totalSupply > 0) {
            positionData.maxRatio = (totalMaxBorrow * 10000) / positionData.totalSupply;
            positionData.maxLiquidationRatio = (totalMaxLiquidation * 10000) / positionData.totalSupply;
            positionData.ratio = (positionData.totalBorrow * 10000) / positionData.totalSupply;
        }

        if (!isSupplyOk || !isBorrowOk) {
            positionData.isOk = false;
            return (positionData);
        }

        // require(positionData.totalBorrow < sub(liquidation, _dif), "position-is-risky-to-migrate");
        uint256 _dif = wmul(totalMaxLiquidation, sub(1e18, safeRatioPercentage));
        positionData.isOk = positionData.totalBorrow < sub(totalMaxLiquidation, _dif);
    }

    /*
     * Checks the position to migrate should have a safe gap from liquidation 
    */
    function _checkLiquidityRatio(
        address liquidity,
        address[] memory tokens,
        uint256 safeRatioPercentage,
        uint256 userTotalBorrow
    ) public view returns (
        PositionData memory positionData
    ) {
        uint256 totalMaxBorrow;
        uint256 totalMaxLiquidation;

        (
            positionData.totalSupply,
            positionData.totalBorrow,
            totalMaxBorrow,
            totalMaxLiquidation
        ) = checkLiquidityToken(liquidity, tokens);
        positionData.totalBorrow = add(positionData.totalBorrow, userTotalBorrow);

        if (positionData.totalSupply > 0) {
            positionData.maxRatio = (totalMaxBorrow * 10000) / positionData.totalSupply;
            positionData.maxLiquidationRatio = (totalMaxLiquidation * 10000) / positionData.totalSupply;
            positionData.ratio = (positionData.totalBorrow * 10000) / positionData.totalSupply;
        }

        uint256 _dif = wmul(positionData.totalSupply, sub(1e18, safeRatioPercentage));
        positionData.isOk = positionData.totalBorrow < sub(totalMaxLiquidation, _dif);
    }

    function isPositionSafe(
        address user,
        uint256 safeRatioPercentage
    ) public view returns (
        bool isOk,
        uint256 userTl,
        uint256 userLtv
    ) {
        AaveInterface aave = AaveInterface(aaveLendingPoolAddressesProvider.getLendingPool());
        uint healthFactor;
        (,,, userTl, userLtv, healthFactor) = aave.getUserAccountData(user);
        uint minLimit = wdiv(1e18, safeRatioPercentage);
        isOk = healthFactor > minLimit;
    }
}