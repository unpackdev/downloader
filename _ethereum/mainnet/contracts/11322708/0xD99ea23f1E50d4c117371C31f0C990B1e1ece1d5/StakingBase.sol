// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./TokenBase.sol";
import "./Console.sol";

contract StakingBase is TokenBase {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // This class is meant to be used to stake a token into a farm. Currently, it only handles getting the rewards
  // from a farm and is only used by PuulStakingPool. Will be enhanced in the future.

  IERC20 private _staking;

  constructor (string memory name, string memory symbol, address token, address fees, address helper) public TokenBase(name, symbol, fees, helper) {
    require(token != address(0), 'token==0');
    _staking = IERC20(token);
  }

  function _initialize() internal override returns(bool success) {
    return true;
  }

  function deposit(uint256 amount) external nonReentrant {
    uint256 bef = _staking.balanceOf(address(this));
    _staking.safeTransferFrom(msg.sender, address(this), amount);
    uint256 aft = _staking.balanceOf(address(this));
    uint256 sent = aft.sub(bef, '!deposit');
    _deposit(sent);
  }

  function _earn() internal override virtual {
    // TODO
  }

  function _unearn(uint256 amount) internal override virtual {
    // TODO
  }

  function _withdrawFees() override internal returns(uint256 amount) {
    amount = EarnPool._withdrawFees();
    _staking.safeTransfer(msg.sender, amount);
  }

  function _withdraw(uint256 amount) override internal returns(uint256 afterFee) {
    afterFee = EarnPool._withdraw(amount);
    _staking.safeTransfer(msg.sender, afterFee);
  }

  function _tokenInUse(address token) override virtual internal view returns(bool) {
    return token == address(_staking) || TokenBase._tokenInUse(token);
  }

  function withdrawAll() nonReentrant external override {
    _withdraw(balanceOf(msg.sender));
  }

  function withdraw(uint256 amount) nonReentrant external override {
    require(amount <= balanceOf(msg.sender));
    _withdraw(amount);
  }

  function withdrawFees() onlyWithdrawal nonReentrant override external {
    _withdrawFees();
  }
  
}
