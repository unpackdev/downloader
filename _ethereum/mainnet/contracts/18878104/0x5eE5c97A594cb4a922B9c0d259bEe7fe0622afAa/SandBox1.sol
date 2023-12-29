// SPDX-License-Identifier: MIT
// SandBox1 
pragma solidity 0.8.21;

import "UBDExchange.sol";
import "MarketConnector.sol";
import "ReentrancyGuard.sol";

/// @title SandBox1 
/// @author UBD Team
/// @notice This contract is main user's entry point in UBD ecosystem
/// @dev  Check deploy params so they are immutable
contract SandBox1 is UBDExchange, MarketConnector, ReentrancyGuard {

    uint256 public constant TREASURY_TOPUP_PERIOD = 1 days;
    uint256 public constant TREASURY_TOPUP_PERCENT = 10000; // 1% - 10000, 13% - 130000, etc 

    uint256 public lastTreasuryTopUp;
    uint256 public MIN_TREASURY_TOPUP_AMOUNT = 1000; // Stable Coin Units (without decimals)

    constructor(address _markets, address _baseAsset)
        UBDExchange(_baseAsset, address(this))
        MarketConnector(_markets)
    {

    }
    
    /// @notice Swap any asset (available at AMM) to UBD
    /// @dev only called from Sandboxes
    /// @param _inAsset - contract address of in asset
    /// @param _inAmount - amount with decimcals
    /// @param _deadline -acceptable time
    /// @param _amountOutMin - min acceptable amount of base 
    function swapExactInput(
        address _inAsset,
        uint256 _inAmount, 
        uint256 _deadline, 
        uint256 _amountOutMin
    ) 
        public
        nonReentrant
        returns (uint256 outAmount)
    {
        
        // Check system balance and redeem sandbox_1 if  need
        if (_inAsset == address(ubdToken) &&
            IERC20(EXCHANGE_BASE_ASSET).balanceOf(address(this)) < _amountOutMin){
            if (_redeemSandbox1() < _amountOutMin ) {
                return 0;
            }
        }

        if (_inAsset != EXCHANGE_BASE_ASSET && _inAsset != address(ubdToken)) {
            address[] memory path = new address[](2);
            
            // Swap any to BASE asset
            uint256 amountBASE = IMarketRegistry(marketRegistry).swapExactInToBASEOut(
                _inAmount,
                _amountOutMin,
                _inAsset,
                msg.sender,
                _deadline
            );
            return super.swapExactInput(EXCHANGE_BASE_ASSET, amountBASE, _deadline, _amountOutMin, msg.sender);
        }
        return super.swapExactInput(_inAsset, _inAmount, _deadline, _amountOutMin, msg.sender);

    }

    /// @notice Check condition and topup Treasury
    /// @dev Revert if no condition yet
    function topupTreasury() external {
        uint256 topupAmount = 
            IERC20(EXCHANGE_BASE_ASSET).balanceOf(address(this)) 
            * TREASURY_TOPUP_PERCENT 
            / (100 * PERCENT_DENOMINATOR);
        require(
            topupAmount 
                >= MIN_TREASURY_TOPUP_AMOUNT * 10**IERC20Metadata(EXCHANGE_BASE_ASSET).decimals(), 
            'Too small topup amount'
        ); 
        require(
            lastTreasuryTopUp + TREASURY_TOPUP_PERIOD < block.timestamp, 
            'Please wait untit TREASURY_TOPUP_PERIOD'
        );
        lastTreasuryTopUp = block.timestamp;
        IERC20(EXCHANGE_BASE_ASSET).approve(marketRegistry, topupAmount);
        IMarketRegistry(marketRegistry).swapExactBASEInToTreasuryAssets(topupAmount, EXCHANGE_BASE_ASSET);
        emit TreasuryTopup(EXCHANGE_BASE_ASSET, topupAmount);
    }
    
    /// @notice Emergency method for  case of Sandbox1 BASE asset.
    /// Call it for  try sell old BASE asset
    /// @dev Revert if use for current BASE asset
    function topupTreasuryEmergency(address _token) external {
        require(_token != EXCHANGE_BASE_ASSET && _token != address(ubdToken), 'Only for other assets');
        uint256 topupAmount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).approve(marketRegistry, topupAmount);
        IMarketRegistry(marketRegistry).swapExactBASEInToTreasuryAssets(topupAmount, _token);
        emit TreasuryTopup(_token, topupAmount);

    }


    ///////////////////////////////////////////////////////////
    ///////    Admin Functions        /////////////////////////
    ///////////////////////////////////////////////////////////
    function setMinTopUp(uint256 _amount) 
        external 
        onlyOwner 
    {
        MIN_TREASURY_TOPUP_AMOUNT = _amount;
    }
    ///////////////////////////////////////////////////////////

    function ubdTokenAddress() external view returns(address) {
        return address(ubdToken);
    }
    
    function _redeemSandbox1() internal returns(uint256 newBASEBalance) {
        if (_getCollateralSystemLevelM10() >= 10) {
            uint256 redeemAmount = IMarketRegistry(marketRegistry).swapTreasuryAssetsPercentToSandboxAsset(); 
            emit Sandbox1Redeem(EXCHANGE_BASE_ASSET,redeemAmount);
        }
        newBASEBalance = IERC20(EXCHANGE_BASE_ASSET).balanceOf(address(this));
    }

}