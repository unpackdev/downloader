// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

import "./AggregatorV3Interface.sol";
import "./Math.sol";
import "./IERC20.sol";
import "./ICurvePool.sol";
import "./IPoolPositionSlim.sol";
import "./IERC4626.sol";

/// @title PxETHSturdyMavPxETHOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for PxETH/SturdyMavPxETH

contract PxETHSturdyMavPxETHOracle {
    uint8 public constant DECIMALS = 18;
    address private  constant MAV_PXETH_POOL = 0x5263DBD1FBFf32E0ba38C67539821B6D0D0dBf61;

    address public immutable STURDY_MAV_PXETH_REWARD_COMPOUNDER;
    uint256 public immutable PRICE_MIN;

    string public name;

    constructor(
        uint256 _priceMin,
        address _sturdyRewardCompounder,
        string memory _name
    ) {
        STURDY_MAV_PXETH_REWARD_COMPOUNDER = _sturdyRewardCompounder;
        name = _name;
        PRICE_MIN = _priceMin;
    }

    /// @notice The ```getPrices``` function is intended to return price of ERC4626 token based on the base asset
    /// @return _isBadData is always false, just sync to other oracle interfaces
    /// @return _priceLow is the lower of the prices
    /// @return _priceHigh is the higher of the prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        uint256 mavLPInETH = _getMavPxETHLPPrice();
        uint256 rate = IERC4626(STURDY_MAV_PXETH_REWARD_COMPOUNDER).convertToAssets(1e18); // SturdyMavPxETH/MavPxETH

        rate = rate * mavLPInETH / 1e18;

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }

    /**
     * @dev Get price for maverick PxETH-ETH boosted position LP Token, 1 pxETH <= 1ETH
     */
    function _getMavPxETHLPPrice() internal view returns (uint256) {
        (uint256 pxETHAmount, uint256 WETHAmount) = IPoolPositionSlim(MAV_PXETH_POOL).getReserves();
        uint256 LPSupply = IERC20(MAV_PXETH_POOL).totalSupply();
        return (pxETHAmount + WETHAmount) * 1e18 / LPSupply;
    }
}
