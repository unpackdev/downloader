pragma solidity ^0.6.0;

import "./BECAAVEPool.sol";
import "./BECBACPool.sol";
import "./BECBUSDPool.sol";
import "./BECUNIPool.sol";
import "./BECDAIPool.sol";
import "./BECESDPool.sol";
import "./BECLINKPool.sol";
import "./BECSUSDPool.sol";
import "./BECSUSHIPool.sol";
import "./BECUSDCPool.sol";
import "./BECUSDTPool.sol";
import "./BECYFIPool.sol";
import "./BECMICPool.sol";
import "./BECFRAXPool.sol";
import "./IDistributor.sol";

contract InitialCashDistributor is IDistributor {
    using SafeMath for uint256;

    event Distributed(address pool, uint256 cashAmount);

    bool public once = true;

    IERC20 public cash;
    IRewardDistributionRecipient[] public pools;
    uint256 public totalInitialBalance;

    constructor(
        IERC20 _cash,
        IRewardDistributionRecipient[] memory _pools,
        uint256 _totalInitialBalance
    ) public {
        require(_pools.length != 0, 'a list of BAC pools are required');

        cash = _cash;
        pools = _pools;
        totalInitialBalance = _totalInitialBalance;
    }

    function distribute() public override {
        require(
            once,
            'InitialCashDistributor: you cannot run this function twice'
        );

        for (uint256 i = 0; i < pools.length; i++) {
            uint256 amount = totalInitialBalance.div(pools.length);

            cash.transfer(address(pools[i]), amount);
            pools[i].notifyRewardAmount(amount);

            emit Distributed(address(pools[i]), amount);
        }

        once = false;
    }
}
