pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./IERC20.sol";

import "./IDistributor.sol";
import "./IRewardDistributionRecipient.sol";

contract InitialKlonDistributor is IDistributor {
    using SafeMath for uint256;

    event Distributed(address pool, uint256 kbtcAmount);

    bool public once = true;

    IERC20 public klon;
    IRewardDistributionRecipient public wbtckbtcLPPool;
    uint256 public wbtckbtcInitialBalance;
    IRewardDistributionRecipient public wbtcklonLPPool;
    uint256 public wbtcklonInitialBalance;

    constructor(
        IERC20 _klon,
        IRewardDistributionRecipient _wbtckbtcLPPool,
        uint256 _wbtckbtcInitialBalance,
        IRewardDistributionRecipient _wbtcklonLPPool,
        uint256 _wbtcklonInitialBalance
    ) public {
        klon = _klon;
        wbtckbtcLPPool = _wbtckbtcLPPool;
        wbtckbtcInitialBalance = _wbtckbtcInitialBalance;
        wbtcklonLPPool = _wbtcklonLPPool;
        wbtcklonInitialBalance = _wbtcklonInitialBalance;
    }

    function distribute() public override {
        require(
            once,
            'InitialKlonDistributor: you cannot run this function twice'
        );

        klon.transfer(address(wbtckbtcLPPool), wbtckbtcInitialBalance);
        wbtckbtcLPPool.notifyRewardAmount(wbtckbtcInitialBalance);
        emit Distributed(address(wbtckbtcLPPool), wbtckbtcInitialBalance);

        klon.transfer(address(wbtcklonLPPool), wbtcklonInitialBalance);
        wbtcklonLPPool.notifyRewardAmount(wbtcklonInitialBalance);
        emit Distributed(address(wbtcklonLPPool), wbtcklonInitialBalance);

        once = false;
    }
}
