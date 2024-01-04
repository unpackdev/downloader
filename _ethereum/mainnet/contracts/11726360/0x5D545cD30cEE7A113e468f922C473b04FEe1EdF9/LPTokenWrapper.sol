pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    address public treasury;
    uint256 public devFee;
    uint256 public _totalSupply;
    uint256 public _totalSupplyAccounting;
    uint256 public startTime;
    mapping(address => uint256) public _balances;
    mapping(address => uint256) public _balancesAccounting;

    // Returns the total staked tokens within the contract
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Returns staking balance of the account
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // Set the staking token for the contract
    function setStakingToken(address stakingTokenAddress) internal {
        stakingToken = IERC20(stakingTokenAddress);
    }

    // Stake funds into the pool
    function stake(uint256 amount) public virtual {
        // Increment sender's balances and total supply
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _totalSupply = _totalSupply.add(amount);

        // Transfer funds
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    // Subtract balances withdrawn from the user
    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
    }
}
