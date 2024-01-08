pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./SafeERC20.sol";
import "./Ownable.sol";

import "./ABDKMath64x64.sol";
import "./TempleERC20Token.sol";
import "./OGTemple.sol";
import "./ExitQueue.sol";

// import "./console.sol";

/**
 * Mechancics of how a user can stake temple.
 */
contract TempleStaking is Ownable {
    using ABDKMath64x64 for int128;
    
    TempleERC20Token immutable public TEMPLE; // The token being staked, for which TEMPLE rewards are generated
    OGTemple immutable public OG_TEMPLE; // Token used to redeem staked TEMPLE
    ExitQueue public EXIT_QUEUE;    // unstake exit queue

    // epoch percentage yield, as an ABDKMath64x64
    int128 public epy; 

    // epoch size, in seconds
    uint256 public epochSizeSeconds; 

    // The starting timestamp. from where staking starts
    uint256 public startTimestamp;

    // epy compounded over every epoch since the contract creation up 
    // until lastUpdatedEpoch. Represented as an ABDKMath64x64
    int128 accumulationFactor;

    // the epoch up to which we have calculated accumulationFactor.
    uint256 public lastUpdatedEpoch; 

    event StakeCompleted(address _staker, uint256 _amount, uint256 _lockedUntil);
    event AccumulationFactorUpdated(uint256 _epochsProcessed, uint256 _currentEpoch, uint256 _accumulationFactor);
    event UnstakeCompleted(address _staker, uint256 _amount);    

    constructor(
        TempleERC20Token _TEMPLE,
        ExitQueue _EXIT_QUEUE,
        uint256 _epochSizeSeconds) {

        TEMPLE = _TEMPLE;
        EXIT_QUEUE = _EXIT_QUEUE;

        // Each version of the staking contract needs it's own instance of OGTemple users can use to
        // claim back rewards
        OG_TEMPLE = new OGTemple(); 
        epochSizeSeconds = _epochSizeSeconds;
        startTimestamp = block.timestamp;
        epy = ABDKMath64x64.fromUInt(1);
        accumulationFactor = ABDKMath64x64.fromUInt(1);
    }

    /** Sets epoch percentage yield */
    function setEpy(uint256 _numerator, uint256 _denominator) external onlyOwner {
        _updateAccumulationFactor();
        epy = ABDKMath64x64.fromUInt(1).add(ABDKMath64x64.divu(_numerator, _denominator));
    }

    /** Get EPY as uint, scaled up the given factor (for reporting) */
    function getEpy(uint256 _scale) external view returns (uint256) {
        return epy.sub(ABDKMath64x64.fromUInt(1)).mul(ABDKMath64x64.fromUInt(_scale)).toUInt();
    }

    function currentEpoch() public view returns (uint256) {
        return (block.timestamp - startTimestamp) / epochSizeSeconds;
    }

    /** Return current accumulation factor, scaled up to account for fractional component */
    function getAccumulationFactor(uint256 _scale) public view returns(uint256) {
        return _currentAccumulationFactor(currentEpoch()).mul(ABDKMath64x64.fromUInt(_scale)).toUInt();
    }

    /** Calculate the updated accumulation factor, based on the current epoch */
    function _currentAccumulationFactor(uint256 epoch) private view returns(int128) {
        uint256 _nUnupdatedEpochs = epoch - lastUpdatedEpoch;
        return accumulationFactor.mul(epy.pow(_nUnupdatedEpochs));
    }

    /** Balance in TEMPLE for a given amount of OG_TEMPLE */
    function balance(uint256 amountOgTemple) public view returns(uint256 amountTemple) {
        int128 balanceAsFixedPoint = ABDKMath64x64.divu(amountOgTemple, 1e18).mul(_currentAccumulationFactor(currentEpoch()));
        uint256 balanceIntegralDigits = balanceAsFixedPoint.toUInt();
        uint256 balanceFractionalDigits = balanceAsFixedPoint.sub(ABDKMath64x64.fromUInt(balanceIntegralDigits)).mul(ABDKMath64x64.fromUInt(1e18)).toUInt();

        amountTemple = (balanceIntegralDigits * 1e18) + balanceFractionalDigits;
    }

    /** updates rewards in pool */
    function _updateAccumulationFactor() internal {
        uint256 _currentEpoch = currentEpoch();

        // still in previous epoch, no action. 
        // NOTE: should be a pre-condition that _currentEpoch >= lastUpdatedEpoch
        //       It's possible to end up in this state if we shorten epoch size.
        //       As such, it's not baked as a precondition
        if (_currentEpoch <= lastUpdatedEpoch) {
            return;
        }

        accumulationFactor = _currentAccumulationFactor(_currentEpoch);
        uint256 _nUnupdatedEpochs = _currentEpoch - lastUpdatedEpoch;
        lastUpdatedEpoch = _currentEpoch;
        emit AccumulationFactorUpdated(_nUnupdatedEpochs, _currentEpoch, accumulationFactor.mul(10000).toUInt());
    }

    /** Stake on behalf of a given address. Used by other contracts (like Presale) */
    function stakeFor(address _staker, uint256 _amount) public returns(uint256 amountOgTemple) {
        require(_amount > 0, "Cannot stake 0 tokens");

        _updateAccumulationFactor();

        int128 ogTempleAsFixedPoint = ABDKMath64x64.divu(_amount, 1e18).div(accumulationFactor);
        uint256 ogTempleIntegralDigits = ogTempleAsFixedPoint.toUInt();
        uint256 ogTempleFractionalDigits = ogTempleAsFixedPoint.sub(ABDKMath64x64.fromUInt(ogTempleIntegralDigits)).mul(ABDKMath64x64.fromUInt(1e18)).toUInt();
        amountOgTemple = (ogTempleIntegralDigits * 1e18) + ogTempleFractionalDigits;

        SafeERC20.safeTransferFrom(TEMPLE, msg.sender, address(this), _amount);
        OG_TEMPLE.mint(_staker, amountOgTemple);
        emit StakeCompleted(_staker, _amount, 0);

        return amountOgTemple;
    }

    /** Stake temple */
    function stake(uint256 _amount) external returns(uint256 amountOgTemple) {
        return stakeFor(msg.sender, _amount);
    }

    /**
     * Unstake on behalf of a given user. Expected to be used by contracts
     */
    function unstakeFor(address _staker, uint256 _amount) public {      
        require(OG_TEMPLE.allowance(msg.sender, address(this)) >= _amount, 'Insufficient OGTemple allowance. Cannot unstake');

        _updateAccumulationFactor();
        uint256 unstakeBalance = balance(_amount);

        OG_TEMPLE.burnFrom(_staker, _amount);
        SafeERC20.safeIncreaseAllowance(TEMPLE, address(EXIT_QUEUE), unstakeBalance);
        EXIT_QUEUE.join(_staker, unstakeBalance);

        emit UnstakeCompleted(msg.sender, _amount);    
    }

    /** Unstake temple */
    function unstake(uint256 _amount) external {      
        unstakeFor(msg.sender, _amount);
    }
}