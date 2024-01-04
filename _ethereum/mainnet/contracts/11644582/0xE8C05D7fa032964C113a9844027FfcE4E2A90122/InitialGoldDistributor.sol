pragma solidity ^0.6.0;

import "./BSGDAIPool.sol";
import "./BSGDSDPool.sol";
import "./BSGSXAUPool.sol";
import "./BSGESDPool.sol";
import "./BSGBACPool.sol";
import "./BSGBUILDETHPool.sol";
import "./IDistributor.sol";

contract InitialGoldDistributor is IDistributor {
    using SafeMath for uint256;

    event Distributed(address pool, uint256 goldAmount);

    bool public once = true;
    uint256 STABLES_SHARE = 80e18;

    IERC20 public gold;
    IRewardDistributionRecipient[] public stablePools;
    IRewardDistributionRecipient public lpPool;
    uint256 public totalInitialBalance;

    constructor(
        IERC20 _gold,
        IRewardDistributionRecipient[] memory _stablePools,
        IRewardDistributionRecipient _lpPool,
        uint256 _totalInitialBalance
    ) public {
        require(_stablePools.length != 0, 'a list of BSG pools are required');

        gold = _gold;
        stablePools = _stablePools;
        lpPool = _lpPool;
        totalInitialBalance = _totalInitialBalance;
    }

    function distribute() public override {
        require(
            once,
            'InitialGoldDistributor: you cannot run this function twice'
        );

        uint256 stableAmount = totalInitialBalance.mul(STABLES_SHARE).div(100e18);
        uint256 lpAmount = totalInitialBalance.sub(stableAmount);

        for (uint256 i = 0; i < stablePools.length; i++) {
            uint256 amount = stableAmount.div(stablePools.length);

            gold.transfer(address(stablePools[i]), amount);
            stablePools[i].notifyRewardAmount(amount);

            emit Distributed(address(stablePools[i]), amount);
        }

        gold.transfer(address(lpPool), lpAmount);
        lpPool.notifyRewardAmount(lpAmount);
        emit Distributed(address(lpPool), lpAmount);

        once = false;
    }
}
