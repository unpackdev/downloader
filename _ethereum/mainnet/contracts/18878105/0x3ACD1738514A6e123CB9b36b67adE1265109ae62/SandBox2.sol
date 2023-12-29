// SPDX-License-Identifier: MIT
// Sandboxd2 
pragma solidity 0.8.21;

import "MarketConnector.sol";
import "IERC20Burn.sol";

/// @title SandBox2 
/// @author UBD Team
/// @notice This contract store UBD ecosystem reserves and team shares
/// @dev  Check deploy params so they are immutable
contract SandBox2 is MarketConnector {

    uint256 public constant TREASURY_TOPUP_PERIOD = 1 days;
    uint256 public constant TREASURY_TOPUP_PERCENT = 10000; //   1% -   10000, 13% - 130000, etc 
    uint256 public constant PERCENT_DENOMINATOR = 10000; 
    uint256 public constant TEAM_PERCENT = 330000; //   1% -   10000, 13% - 130000, etc 
    
    address public immutable SANDBOX_2_BASE_ASSET;

    uint256 public lastTreasuryTopUp;
    uint256 public MIN_TREASURY_TOPUP_AMOUNT = 1000; // Stable Coin Units (without decimals)

    event TeamShareIncreased(uint256 Income, uint256 TeamLimit);

	constructor(address _markets, address _baseAsset)
        MarketConnector(_markets)
    {
        require(_markets != address(0), 'No zero markets');
        require(_baseAsset != address(0),'No zero address assets');
        SANDBOX_2_BASE_ASSET = _baseAsset;
    }

    /// @notice Check condition and topup Treasury
    /// @dev Revert if no condition yet
    function topupTreasury() external returns(bool) {
        if (_getCollateralSystemLevelM10() >= 5 && _getCollateralSystemLevelM10() < 10) {
            uint256 topupAmount = 
                IERC20(SANDBOX_2_BASE_ASSET).balanceOf(address(this)) * TREASURY_TOPUP_PERCENT / (100 * PERCENT_DENOMINATOR);
            
            require(
                topupAmount 
                    >= MIN_TREASURY_TOPUP_AMOUNT 
                       * 10**IERC20Metadata(SANDBOX_2_BASE_ASSET).decimals(),
                'Too small topup amount'
            );
            
            require(
                lastTreasuryTopUp + TREASURY_TOPUP_PERIOD < block.timestamp, 
                'Please wait untit TREASURY_TOPUP_PERIOD'
            );

            lastTreasuryTopUp = block.timestamp;
            IERC20(SANDBOX_2_BASE_ASSET).approve(marketRegistry, topupAmount);
            IMarketRegistry(marketRegistry).swapExactBASEInToTreasuryAssets(
                topupAmount, 
                SANDBOX_2_BASE_ASSET
            );
            emit TreasuryTopup(SANDBOX_2_BASE_ASSET, topupAmount);
            return true;
        } else {
            return false;
        }
    }

    /// @notice Check condition and topup SandBox2
    /// @dev Revert if no condition yet
    function topupSandBox2() external returns (bool){
        uint256  topupAmount;
        topupAmount = IMarketRegistry(marketRegistry).swapTreasuryAssetsPercentToSandboxAsset();
        emit Sandbox2Topup(SANDBOX_2_BASE_ASSET, topupAmount);
        _increaseApproveForTEAM(topupAmount * TEAM_PERCENT / (100 * PERCENT_DENOMINATOR));

    }

    /// @notice Approve 33% from DAI in to Team wallet
    function _increaseApproveForTEAM(uint256 _incAmount) internal {
        address team = IMarketRegistry(marketRegistry).getUBDNetworkTeamAddress();
        uint256 newApprove = IERC20(SANDBOX_2_BASE_ASSET).allowance(address(this),team) + _incAmount;
        IERC20(SANDBOX_2_BASE_ASSET).approve(team, newApprove);
        emit TeamShareIncreased(_incAmount, newApprove);
    }
}