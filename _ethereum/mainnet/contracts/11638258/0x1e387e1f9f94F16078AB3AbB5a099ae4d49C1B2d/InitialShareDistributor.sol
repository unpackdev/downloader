pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./IERC20.sol";

import "./IDistributor.sol";
import "./IRewardDistributionRecipient.sol";

contract InitialShareDistributor is IDistributor {
    using SafeMath for uint256;

    event Distributed(address pool, uint256 cashAmount);

    bool public once = true;

    IERC20 public share;
    IRewardDistributionRecipient public daitccLPPool;
    uint256 public daitccInitialBalance;
    IRewardDistributionRecipient public daibasLPPool;
    uint256 public daibasInitialBalance;

    constructor(
        IERC20 _share,
        IRewardDistributionRecipient _daitccLPPool,
        uint256 _daitccInitialBalance,
        IRewardDistributionRecipient _daibasLPPool,
        uint256 _daibasInitialBalance
    ) public {
        share = _share;
        daitccLPPool = _daitccLPPool;
        daitccInitialBalance = _daitccInitialBalance;
        daibasLPPool = _daibasLPPool;
        daibasInitialBalance = _daibasInitialBalance;
    }

    function distribute() public override {
        require(
            once,
            'InitialShareDistributor: you cannot run this function twice'
        );

        share.transfer(address(daitccLPPool), daitccInitialBalance);
        daitccLPPool.notifyRewardAmount(daitccInitialBalance);
        emit Distributed(address(daitccLPPool), daitccInitialBalance);

        share.transfer(address(daibasLPPool), daibasInitialBalance);
        daibasLPPool.notifyRewardAmount(daibasInitialBalance);
        emit Distributed(address(daibasLPPool), daibasInitialBalance);

        once = false;
    }
    
    function _setRewardDistribution() external {
        // Shh
    }
}
