pragma solidity ^0.6.0;

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
}

contract Vesting {

  using SafeMath for uint;

  address public beneficiary;
  IERC20 public asset;

  uint public startTime;
  uint public duration;
  uint public released;

  constructor(
    IERC20 _asset,
    uint _startTime,
    uint _duration
  ) public {

    require(_asset != IERC20(0), "Vesting: _asset is zero address");
    require(_startTime.add(_duration) > block.timestamp, "Vesting: final time is before current time");
    require(_duration > 0, "Vesting: _duration == 0");

    beneficiary = msg.sender;
    asset = _asset;
    startTime = _startTime;
    duration = _duration;
  }

  function release(uint _amount) external {
    require(beneficiary == msg.sender, "Vesting: not beneficiary");
    uint unreleased = releasableAmount();

    require(unreleased > 0, "Vesting: no assets are due");
    require(unreleased > _amount, "Vesting: _amount too high");

    released = released.add(_amount);
    asset.transfer(beneficiary, _amount);
  }

  function releasableAmount() public view returns (uint) {
    return vestedAmount().sub(released);
  }

  function vestedAmount() public view returns (uint) {
    uint currentBalance = asset.balanceOf(address(this));
    uint totalBalance = currentBalance.add(released);

    if (block.timestamp >= startTime.add(duration)) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(startTime)).div(duration);
    }
  }
}