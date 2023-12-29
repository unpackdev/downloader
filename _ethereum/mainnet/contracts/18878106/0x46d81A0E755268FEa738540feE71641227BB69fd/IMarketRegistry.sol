// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;



interface IMarketRegistry  {

    struct AsssetShare {
        address asset;
        uint8 percent;
    }

    struct UBDNetwork {
        address sandbox1;
        address treasury;
        address sandbox2;
        AsssetShare[] treasuryERC20Assets;

    }

    struct Market {
        address marketAdapter;
        address oracleAdapter;
        uint256 slippage;
    }

    struct ActualShares{
        address asset;
        uint256 actualPercentPoint;
        uint256 excessAmount;
    } 
    
    function swapExactInToBASEOut(
        uint256 amountIn,
        uint256 amountOutMin,
        address assetIn,
        address to,
        uint deadline
    ) external returns (uint256 amountOut);


    function swapExactBASEInToTreasuryAssets(uint256 _amountIn, address _baseAsset) external;

    function swapTreasuryAssetsPercentToSandboxAsset() 
        external 
        returns(uint256 totalStableAmount);

    function getAmountOut(
        uint amountIn, 
        address[] memory path
    ) external view returns (uint256 amountOut);
    function getCollateralLevelM10() external view returns(uint256);
    function getBalanceInStableUnits(address _holder, address[] memory _assets) external view returns(uint256);
    function treasuryERC20Assets() external view returns(address[] memory assets);
    function getUBDNetworkTeamAddress() external view returns(address);
    function getUBDNetworkInfo() external view returns(UBDNetwork memory);
}