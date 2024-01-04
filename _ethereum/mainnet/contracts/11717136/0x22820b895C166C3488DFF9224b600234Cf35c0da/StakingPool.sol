// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Governable.sol";

abstract contract StakingPool is Governable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public lpToken;

  uint256 public totalSupply;
  mapping(address => uint256) public balances;

  event Recovered(address token, uint256 amount);

  constructor(address _governance) public 
    Governable(_governance) {
  }

  function balanceOf(address account) public view returns (uint256) {
    return balances[account];
  }

  function stake(uint256 _amount) public virtual {
    lpToken.safeTransferFrom(msg.sender, address(this), _amount);
    addStakeBalance(msg.sender, _amount);
  }

  function withdraw(uint256 _amount) public virtual {
    removeStakeBalance(msg.sender, _amount);
    lpToken.safeTransfer(msg.sender, _amount);
  }

  function addStakeBalance(address _owner, uint256 _amount) internal {
    totalSupply = totalSupply.add(_amount);
    balances[_owner] = balances[_owner].add(_amount);
  }

  function removeStakeBalance(address _owner, uint256 _amount) internal {
    totalSupply = totalSupply.sub(_amount);
    balances[_owner] = balances[_owner].sub(_amount);
  }

  function recoverERC20(address _token, uint256 _amount) external onlyGovernance {
    require(_token != address(lpToken), "Cannot withdraw staking tokens");
    
    IERC20(_token).safeTransfer(msg.sender, _amount);
    emit Recovered(_token, _amount);
  }
}