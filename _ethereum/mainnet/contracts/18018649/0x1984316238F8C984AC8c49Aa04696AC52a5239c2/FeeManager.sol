// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Math.sol";
import "./IFeeManager.sol";
import "./IVault.sol";
import "./IVaultFactory.sol";

contract FeeManager is IFeeManager, Ownable {

    /* ========== STATES ========== */

    address public override protocolFeeTo;
    address public override redemptionFeeTo;

    IVaultFactory public immutable factory;
    uint public maxProtocolFee;
    uint public minRedemptionFee;
    uint public maxRedemptionAdjustment;
    uint public override protocolRedemptionFeeShare;
    uint public maxRedemptionCap;
    uint public redemptionSupplyPerSec;
    uint public lastRedemptionTime;
    uint public redeemed;
    uint public constant PRECISION = 1e18;

    /* ========== CONSTRUCTOR ========== */

    constructor(IVaultFactory _factory, address _protocolFeeTo, address _redemptionFeeTo) {
        factory = _factory;
        protocolFeeTo = _protocolFeeTo;
        redemptionFeeTo = _redemptionFeeTo;
        maxProtocolFee = 40e16; // default to 40%
        minRedemptionFee = 5e15; // default to 0.5%
        maxRedemptionAdjustment = 15e15; // default to 1.5%
        protocolRedemptionFeeShare = 5e17; // default to 50%
        maxRedemptionCap = 100e18; // default to 100 ETH
        redemptionSupplyPerSec = 12e14; // default to 103 ETH restore per day
    }

    /* ========== VIEWS ========== */

    // Calculate protocol fee based on mint ratio
    function protocolFee(address _vault, uint _yield) public view override returns (uint) {
        return _yield * IVault(_vault).mintRatio() / PRECISION * maxProtocolFee / PRECISION;
    }

    // Calculate redemption fee based on mint ratio
    function redemptionFee(address _vault, uint _redeemAmount) public view override returns (uint) {
        return _redeemAmount * (minRedemptionFee + maxRedemptionAdjustment * (PRECISION - IVault(_vault).mintRatio()) / PRECISION) / PRECISION;
    }

    function redemptionSupplyRestored() public view returns (uint) {
        return (block.timestamp - lastRedemptionTime) * redemptionSupplyPerSec;
    }

    function availableRedemption() public view returns (uint) {
        uint restoredSupply = redemptionSupplyRestored();
        return Math.min(maxRedemptionCap, maxRedemptionCap + restoredSupply - redeemed);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function beforeRedeem(uint _amount) external override {
        require(availableRedemption() >= _amount, "!redeem");
    }

    function afterRedeem(uint _amount) external override {
        require(factory.isVault(msg.sender), "!vault");
        uint restoredSupply = redemptionSupplyRestored();
        if (restoredSupply >= redeemed) {
            redeemed = _amount;
        } else {
            redeemed = redeemed + _amount - restoredSupply;
        }
        lastRedemptionTime = block.timestamp;
    }

    /* ========== ADMIN FUNCTIONS ========== */

    function setMinRedemptionFee(uint _minRedemptionFee) external onlyOwner {
        require(_minRedemptionFee > 0 && _minRedemptionFee <= 2e16, "fee needs to be > 0 and <= 2%");
        minRedemptionFee = _minRedemptionFee;
        emit SetMinRedemptionFee(_minRedemptionFee);
    }

    function setMaxRedemptionAdjustment(uint _maxRedemptionAdjustment) external onlyOwner {
        require(_maxRedemptionAdjustment > 0 && _maxRedemptionAdjustment <= 3e16, "adjustment needs to be > 0 and <= 3%");
        maxRedemptionAdjustment = _maxRedemptionAdjustment;
        emit SetMaxRedemptionAdjustment(_maxRedemptionAdjustment);
    }

    function setProtocolRedemptionFeeShare(uint _protocolRedemptionFeeShare) external onlyOwner {
        protocolRedemptionFeeShare = _protocolRedemptionFeeShare;
        emit SetProtocolRedemptionFeeShare(_protocolRedemptionFeeShare);
    }

    function setRedemptionFeeTo(address _redemptionFeeTo) external onlyOwner {
        redemptionFeeTo = _redemptionFeeTo;
        emit SetRedemptionFeeTo(_redemptionFeeTo);
    }

    function setMaxProtocolFee(uint _maxProtocolFee) external onlyOwner {
        require(_maxProtocolFee > 0 && _maxProtocolFee <= 1e18, "fee needs to be > 0 and < 100%");
        maxProtocolFee = _maxProtocolFee;
        emit SetMaxProtocolFee(_maxProtocolFee);
    }

    function setProtocolFeeTo(address _protocolFeeTo) external onlyOwner {
        protocolFeeTo = _protocolFeeTo;
        emit SetProtocolFeeTo(_protocolFeeTo);
    }

    function setRedemptionParams(uint _maxRedemptionCap, uint _redemptionSupplyPerSec) external onlyOwner {
        maxRedemptionCap = _maxRedemptionCap;
        redemptionSupplyPerSec = _redemptionSupplyPerSec;
        // Reset related params
        redeemed = 0;
        lastRedemptionTime = block.timestamp;
        emit SetRedemptionParams(_maxRedemptionCap, _redemptionSupplyPerSec);
    }

    /* ========== EVENTS ========== */

    event SetMinRedemptionFee(uint minRedemptionFee);
    event SetMaxRedemptionAdjustment(uint maxRedemptionAdjustment);
    event SetProtocolRedemptionFeeShare(uint protocolRedemptionFeeShare);
    event SetRedemptionFeeTo(address indexed redemptionFeeTo);
    event SetMaxProtocolFee(uint maxProtocolFee);
    event SetProtocolFeeTo(address indexed protocolFeeTo);
    event SetRedemptionParams(uint maxRedemptionCap, uint redemptionSupplyPerSec);
}
