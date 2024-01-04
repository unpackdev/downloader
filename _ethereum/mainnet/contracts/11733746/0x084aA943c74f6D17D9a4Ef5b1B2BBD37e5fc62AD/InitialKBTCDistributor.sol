pragma solidity ^0.6.0;

import "./KBTCWBTCPool.sol";
// import "./KBTCWBTCPool.sol";
// import "./KBTCSUSDPool.sol";
// import "./KBTCUSDCPool.sol";
// import "./KBTCUSDTPool.sol";
// import "./KBTCyCRVPool.sol";
import "./IDistributor.sol";

contract InitialKBTCDistributor is IDistributor {
    using SafeMath for uint256;

    event Distributed(address pool, uint256 kbtcAmount);

    bool public once = true;

    IERC20 public kbtc;
    IRewardDistributionRecipient[] public pools;
    uint256 public totalInitialBalance;

    constructor(
        IERC20 _kbtc,
        IRewardDistributionRecipient[] memory _pools,
        uint256 _totalInitialBalance
    ) public {
        require(_pools.length != 0, 'a list of KBTC pools are required');

        kbtc = _kbtc;
        pools = _pools;
        totalInitialBalance = _totalInitialBalance;
    }

    function distribute() public override {
        require(
            once,
            'InitialKBTCDistributor: you cannot run this function twice'
        );

        for (uint256 i = 0; i < pools.length; i++) {
            uint256 amount = totalInitialBalance.div(pools.length);

            kbtc.transfer(address(pools[i]), amount);
            pools[i].notifyRewardAmount(amount);

            emit Distributed(address(pools[i]), amount);
        }

        once = false;
    }
}
