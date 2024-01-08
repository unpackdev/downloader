pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./math.sol";
import "./interfaces.sol";

interface AaveProtocolDataProvider {
    function getUserReserveData(address asset, address user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );

    function getReserveConfigurationData(address asset) external view returns (
        uint256 decimals,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 reserveFactor,
        bool usageAsCollateralEnabled,
        bool borrowingEnabled,
        bool stableBorrowRateEnabled,
        bool isActive,
        bool isFrozen
    );
}

interface AaveAddressProvider {
    function getLendingPool() external view returns (address);
    function getPriceOracle() external view returns (address);
}

interface AavePriceOracle {
    function getAssetPrice(address _asset) external view returns(uint256);
    function getAssetsPrices(address[] calldata _assets) external view returns(uint256[] memory);
    function getSourceOfAsset(address _asset) external view returns(uint256);
    function getFallbackOracle() external view returns(uint256);
}

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint256);
}


contract Variables {
    ChainLinkInterface public constant ethPriceFeed = ChainLinkInterface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    AaveProtocolDataProvider public constant aaveDataProvider = AaveProtocolDataProvider(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    AaveAddressProvider public constant aaveAddressProvider = AaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    address public constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
}

contract Resolver is Variables, DSMath {
    struct Position {
        uint256 supplyLength;
        uint256 borrowLength;
        address[] _supplyTokens;
        address[] _borrowTokens;
        uint256 ethPriceInUSD;
        uint256 totalSupplyInETH;
        uint256 totalBorrowInETH;
        uint256[] supplyTokenPrices;
        uint256[] borrowTokenPrices;
        uint256[] supplyTokenDecimals;
        uint256[] borrowTokenDecimals;
    }
    function _getPosition(
        uint256 networthAmount,
        uint256 rewardAmount,
        address[] memory supplyTokens,
        address[] memory borrowTokens,
        uint256[] memory supplyAmounts,
        uint256[] memory borrowAmounts
    ) 
    internal
    view 
    returns (
        uint256 claimableRewardAmount,
        uint256 claimableNetworth
    ) {
        Position memory position;
        position.supplyLength = supplyTokens.length;
        position.borrowLength = borrowTokens.length;

        position._supplyTokens = new address[](position.supplyLength);
        position._borrowTokens = new address[](position.borrowLength);
        position.supplyTokenDecimals = new uint256[](position.supplyLength);
        position.borrowTokenDecimals = new uint256[](position.borrowLength);

        for (uint i = 0; i < position.supplyLength; i++) {
            position._supplyTokens[i] = supplyTokens[i] == ethAddr ? wethAddr : supplyTokens[i];
            position.supplyTokenDecimals[i] = TokenInterface(position._supplyTokens[i]).decimals();
        }
        
        for (uint i = 0; i < position.borrowLength; i++) {
            position._borrowTokens[i] = borrowTokens[i] == ethAddr ? wethAddr : borrowTokens[i];
            position.borrowTokenDecimals[i] = TokenInterface(position._borrowTokens[i]).decimals();
        }

        position.ethPriceInUSD = uint(ethPriceFeed.latestAnswer());

        AavePriceOracle aavePriceOracle = AavePriceOracle(aaveAddressProvider.getPriceOracle());

        position.totalSupplyInETH = 0;
        position.totalBorrowInETH = 0;

       position.supplyTokenPrices = aavePriceOracle.getAssetsPrices(position._supplyTokens);
       position.borrowTokenPrices = aavePriceOracle.getAssetsPrices(position._borrowTokens);

        for (uint256 i = 0; i < position.supplyLength; i++) {
            require(supplyAmounts[i] > 0, "InstaAaveV2MerkleDistributor:: _getPosition: supply amount not valid");
            uint256 supplyInETH = wmul((supplyAmounts[i] * 10 ** (18 - position.supplyTokenDecimals[i])), position.supplyTokenPrices[i]);

            position.totalSupplyInETH = add(position.totalSupplyInETH, supplyInETH);
        }

        for (uint256 i = 0; i < position.borrowLength; i++) {
            require(borrowAmounts[i] > 0, "InstaAaveV2MerkleDistributor:: _getPosition: borrow amount not valid");
            uint256 borrowInETH = wmul((borrowAmounts[i] * 10 ** (18 - position.borrowTokenDecimals[i])), position.borrowTokenPrices[i]);

            position.totalBorrowInETH = add(position.totalBorrowInETH, borrowInETH);
        }

        claimableNetworth = sub(position.totalSupplyInETH, position.totalBorrowInETH);
        claimableNetworth = wmul(claimableNetworth, position.ethPriceInUSD * 1e10);

        if (networthAmount > claimableNetworth) {
            claimableRewardAmount = wdiv(claimableNetworth, networthAmount);
            claimableRewardAmount = wmul(rewardAmount, claimableRewardAmount);
        } else {
            claimableRewardAmount = rewardAmount;
        }
    }

    function getPosition(
        uint256 networthAmount,
        uint256 rewardAmount,
        address[] memory supplyTokens,
        address[] memory borrowTokens,
        uint256[] memory supplyAmounts,
        uint256[] memory borrowAmounts
    ) 
    public
    view 
    returns (
        uint256 claimableRewardAmount,
        uint256 claimableNetworth
    ) { 
        return _getPosition(
            networthAmount,
            rewardAmount,
            supplyTokens,
            borrowTokens,
            supplyAmounts,
            borrowAmounts
        ); 
    }
}

contract InstaAaveV2MerkleResolver is Resolver {
    string public constant name = "AaveV2-Merkle-Resolver-v1.0";
}