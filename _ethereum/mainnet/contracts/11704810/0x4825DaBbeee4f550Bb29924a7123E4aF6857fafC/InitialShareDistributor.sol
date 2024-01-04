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

    IRewardDistributionRecipient public daiuncLPPool;
    uint256 public daiuncInitialBalance;
    IRewardDistributionRecipient public daiunsLPPool;
    uint256 public daiunsInitialBalance;

    constructor(
        IERC20 _share,
        
        IRewardDistributionRecipient _daiuncLPPool,
        uint256 _daiuncInitialBalance,
        IRewardDistributionRecipient _daiunsLPPool,
        uint256 _daiunsInitialBalance

    ) public {
        share = _share;

        daiuncLPPool = _daiuncLPPool;
        daiuncInitialBalance = _daiuncInitialBalance;
        daiunsLPPool = _daiunsLPPool;
        daiunsInitialBalance = _daiunsInitialBalance;

    }

    function distribute() public override {
        require(
            once,
            'InitialShareDistributor: you cannot run this function twice'
        );

        share.transfer(address(daiuncLPPool), daiuncInitialBalance);
        daiuncLPPool.notifyRewardAmount(daiuncInitialBalance);
        emit Distributed(address(daiuncLPPool), daiuncInitialBalance);
        share.transfer(address(daiunsLPPool), daiunsInitialBalance);
        daiunsLPPool.notifyRewardAmount(daiunsInitialBalance);
        emit Distributed(address(daiunsLPPool), daiunsInitialBalance);

        once = false;
    }
}
