//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";

interface StakingPools {
    function deposit(uint256 _poolId, uint256 _depositAmount) external;
    function claim(uint256 _poolId) external;
    function getStakeTotalDeposited(address _account, uint256 _poolId) external view returns (uint256);
    function withdraw(uint256 _poolId, uint256 _withdrawAmount) external;
}

contract sALCX is ERC20 {
    IERC20 constant alcx = IERC20(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);
    StakingPools constant pools = StakingPools(0xAB8e74017a8Cc7c15FFcCd726603790d26d7DeCa);
    uint constant alcxPoolId = 1;
    bool initialized;

    constructor() ERC20("sALCX", "sALCX") {}

    function deposit(uint amount) external {
        pools.claim(alcxPoolId);
        alcx.transferFrom(msg.sender, address(this), amount);
        uint availableAlcx = alcx.balanceOf(address(this));
        pools.deposit(alcxPoolId, availableAlcx);
        uint totalStakedAlcx = pools.getStakeTotalDeposited(address(this), alcxPoolId);
        uint stakedAlcxBefore = totalStakedAlcx - amount;
        _mint(msg.sender, (totalSupply()*amount)/stakedAlcxBefore);
    }

    // mint first sALCX
    function initialize() external {
        uint amount = 1e18;
        require(!initialized && alcx.balanceOf(address(this)) == amount, "wrong amount or already initialized");
        renewApproval();
        initialized = true;
        pools.deposit(alcxPoolId, amount);
        _mint(msg.sender, amount);
    }

    function renewApproval() public {
        alcx.approve(address(pools), type(uint256).max);
    }

    function compound() public {
        pools.claim(alcxPoolId);
        uint claimedAlcx = alcx.balanceOf(address(this));
        pools.deposit(alcxPoolId, claimedAlcx);
    }

    function withdraw(uint amount) external {
        compound();
        uint totalStakedAlcx = pools.getStakeTotalDeposited(address(this), alcxPoolId);
        uint amountToWithdraw = (amount * totalStakedAlcx) / totalSupply();
        _burn(msg.sender, amount);
        pools.withdraw(alcxPoolId, amountToWithdraw);
        alcx.transfer(msg.sender, amountToWithdraw);
    }
}