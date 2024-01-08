// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IStakingPoolMigrator.sol";
import "./ISwapPair.sol";
import "./ISwapFactory.sol";

contract StakingPoolMigrator is IStakingPoolMigrator, Ownable {

    address public migrateFromFactory;
    address public migrateToFactory;
    address public stakingPools;
    address public txOrigin;
    uint256 public desiredLiquidity = uint256(-1);

    constructor(
        address _migrateFromFactory,
        address _migrateToFactory,
        address _stakingPools
    ) public {
        migrateFromFactory = _migrateFromFactory;
        migrateToFactory = _migrateToFactory;
        stakingPools = _stakingPools;
    }

    function setTxOrigin(address _txOrigin) external onlyOwner {
        txOrigin = _txOrigin;
    }

    function migrate(
        uint256 poolId,
        address oldToken,
        uint256 amount
    ) external override returns (address){
        require(tx.origin == txOrigin, "StakingPoolMigrator: Not from txOrigin defined.");
        require(amount > 0, "StakingPoolMigrator: Zero amount to migrate");
        address _stakingPools = stakingPools;

        require(msg.sender == _stakingPools, "StakingPoolMigrator: Not from StakingPools");
        ISwapPair oldPair = ISwapPair(oldToken);
        require(oldPair.factory() == migrateFromFactory, "StakingPoolMigrator: Not migrating from Uniswap Factory");

        address token0 = oldPair.token0();
        address token1 = oldPair.token1();

        ISwapFactory newFactory = ISwapFactory(migrateToFactory);
        ISwapPair newPair = ISwapPair(newFactory.getPair(token0, token1));
        require(newPair != ISwapPair(address(0)), "StakingPoolMigrator: Convergence pool hasn't been created");
        require(newPair.totalSupply() == 0, "StakingPoolMigrator: Not migrating to a fresh pool");
        require(newFactory.migrator() == address(this), "StakingPoolMigrator: new factory migrator not correct");
        require(amount == oldPair.balanceOf(_stakingPools), "StakingPoolMigrator: Not migrating all amounts from StakingPools");

        desiredLiquidity = amount;
        oldPair.transferFrom(_stakingPools, address(oldPair), amount);
        oldPair.burn(address(newPair));

        uint256 token0AmountMigrated = IERC20(token0).balanceOf(address(newPair));
        uint256 token1AmountMigrated = IERC20(token1).balanceOf(address(newPair));
        newPair.mint(_stakingPools);
        (uint112 reserve0, uint112 reserve1,) = newPair.getReserves();
        require(token0AmountMigrated == reserve0, "StakingPoolMigrator: migrated token0 amount not match with reserve0");
        require(token1AmountMigrated == reserve1, "StakingPoolMigrator: migrated token1 amount not match with reserve1");

        desiredLiquidity = uint256(-1);
        require(amount == newPair.balanceOf(address(_stakingPools)), "StakingPoolMigrator: migrated lp token balance must match");
        require(0 == oldPair.balanceOf(_stakingPools), "StakingPoolMigrator: There is remaining balance for old lp token in StakingPools");

        return address(newPair);
    }


}
