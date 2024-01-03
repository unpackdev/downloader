pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

library Math {

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
  }
}

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

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }

  function percentageOf(uint256 total, uint256 percentage) internal pure returns (uint256) {
    return div(mul(total, percentage), 100);
  }

  function getPercentage(uint256 total, uint256 piece) internal pure returns (uint256) {
    return div(piece, total);
  }
}

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address tokenOwner) external view returns (uint256 balance);
  function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
  function transfer(address to, uint256 tokens) external returns (bool success);
  function approve(address spender, uint256 tokens) external returns (bool success);
  function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
}

contract CrossChainTransfer {
  using SafeMath for uint256;

  struct TransferGroup {
    uint256 id;
    uint256 tokens;
    address sender;
    string receiver;
  }

  uint256 public nextId = 1;
  ERC20 public HXY;
  ERC20 public HXB;

  mapping (uint256 => TransferGroup) public transferGroups;

  event Transfer(TransferGroup transferGroup);

  constructor (address _hxy, address _hxb) public {
    HXY = ERC20(_hxy);
    HXB = ERC20(_hxb);
  }

  function HXBCost (uint256 amount) public pure returns (uint256) {
    return amount.mul(1e4);
  }

  function ready (uint256 amount) public view returns (bool hxy_ready, bool hxb_ready) {
    return readyForTransfer(amount, msg.sender);
  }

  function readyForTransfer (uint256 amount, address sender) internal view returns (bool hxy_ready, bool hxb_ready) {
    bool _hxy_ready = HXY.allowance(sender, address(this)) >= amount;
    bool _hxb_ready = HXB.allowance(sender, address(this)) >= HXBCost(amount);
    return (_hxy_ready, _hxb_ready);
  }

  // Assuming that the amount has already been approved for both tokens
  function triggerTransfer (uint256 amount, string memory receiver) public {
    bool hxy_ready;
    bool hxb_ready;
    (hxy_ready, hxb_ready) = readyForTransfer(amount, msg.sender);

    require (hxy_ready, "HXY tokens not approved");
    require (hxb_ready, "HXB tokens not approved");

    HXY.transferFrom(msg.sender, address(this), amount);
    HXB.transferFrom(msg.sender, address(this), HXBCost(amount));

    TransferGroup memory transferGroup = TransferGroup(
      {
        id: nextId,
        tokens: amount,
        sender: msg.sender,
        receiver: receiver
      }
    );

    transferGroups[nextId] = transferGroup;
    nextId = nextId.add(1);

    emit Transfer(transferGroup);
  }
}