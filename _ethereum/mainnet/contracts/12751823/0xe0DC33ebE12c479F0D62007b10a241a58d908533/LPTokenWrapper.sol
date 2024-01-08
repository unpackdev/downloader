//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./SafeERC20.sol";

abstract contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;
    uint256 public immutable devFee;

    address public treasury;
    // Returns the total staked tokens within the contract
    uint256 public totalSupply;
    uint256 public boostedTotalSupply;
    uint256 public startTime;
    uint256 public burnFee;

    struct Balance {
        uint256 balance;
        uint256 boostedBalance;
    }

    mapping(address => Balance) internal _balances;

    constructor(
        uint256 _devFee,
        address _stakingToken,
        address _treasury,
        uint256 _burnFee
    ) public {
        devFee = _devFee;
        stakingToken = IERC20(_stakingToken);
        treasury = _treasury;
        burnFee = _burnFee;
    }

    // Returns staking balance of the account
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account].balance;
    }

    function boostedBalanceOf(address account) public view returns (uint256) {
        return _balances[account].boostedBalance;
    }

    // Stake funds into the pool
    function stake(uint256 amount) public virtual {
        
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        if (burnFee > 0 ) {
            uint tokenBurnBalance = amount.mul(burnFee).div(1000);
            uint stakedBalance = amount.sub(tokenBurnBalance);
            _balances[msg.sender].balance = _balances[msg.sender].balance.add(
            stakedBalance
           );
            totalSupply = totalSupply.add(stakedBalance);
            return;
        }
         // Increment sender's balances and total supply
        _balances[msg.sender].balance = _balances[msg.sender].balance.add(
            amount
        );
        totalSupply = totalSupply.add(amount);

    }

    // Subtract balances withdrawn from the user
    function withdraw(uint256 amount) public virtual {
        totalSupply = totalSupply.sub(amount);
        _balances[msg.sender].balance = _balances[msg.sender].balance.sub(
            amount
        );

        // Calculate the withdraw tax (it's 1.5% of the amount)
        uint256 tax = amount.mul(devFee).div(1000);

        // Transfer the tokens to user
        stakingToken.safeTransfer(msg.sender, amount - tax);
        // Tax to treasury
        stakingToken.safeTransfer(treasury, tax);
    }
}
