// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./PRBMathUD60x18.sol";

contract RoyaltySplitter is Context, ReentrancyGuard {

  address private residualReceiver;

  struct Payee {
    address receiver;
    // Portion should be expressed as fixed-point number.
    uint portion;
  }

  // Once closed, no new mints should be allowed using this royaltyAddress
  bool public isClosed;

  event PayeeRightsTransferred(address indexed from, address indexed to, uint portion);
  event MintClosed();

  Payee[] private payees;
  mapping(address => uint) payeeIndex;
  uint totalPayeePortion;

  constructor(address _residualReceiver, Payee[] memory _payees) {
    residualReceiver = _residualReceiver;
    require(residualReceiver != address(0), "initialize: Must provide a residualReceiver address");
    for (uint i = 0; i < _payees.length; ++i) {
      _addPayee(_payees[i]);
    }
  }

  function closeContract() external {
    require(!isClosed, "closeContract: Contract is already closed");
    require(residualReceiver == _msgSender()
            || (payees[payeeIndex[_msgSender()]].receiver == _msgSender()),
        "closeContract: Sender is not authorized");
    isClosed = true;
    emit MintClosed();
  }

  function _addPayee(Payee memory payee) internal {
    require(totalPayeePortion + payee.portion <= 1 ether, "_addPayee: Insufficent portion remaining");
    require(payee.portion > 0, "_addPayee: Portion must be nonzero");
    payeeIndex[payee.receiver] = payees.length;
    payees.push(payee);
    totalPayeePortion += payee.portion;
  }

  function transferPayeeRights(address to) external {
    if (_msgSender() == residualReceiver) {
      residualReceiver = to;
      emit PayeeRightsTransferred(_msgSender(), to, 1 ether - totalPayeePortion);
    } else {
      uint index = payeeIndex[_msgSender()];
      require(
          payees[index].receiver == _msgSender(),
          "transferPayeeRights: Sender does not have payee rights");
      payeeIndex[_msgSender()] = 0;
      payeeIndex[to] = index;
      payees[index].receiver = to;
      emit PayeeRightsTransferred(_msgSender(), to, payees[index].portion);
    }
  }

  function computePortion(uint totalAmount, Payee memory payee) internal pure returns (uint) {
    return PRBMathUD60x18.mul(totalAmount, payee.portion);
  }

  function distributeERC20(address tokenAddress, uint optionalAmount) external {
    uint distributeAmount;
    if (optionalAmount > 0) {
      distributeAmount = optionalAmount;
      require(
          distributeAmount <= ERC20(tokenAddress).balanceOf(address(this)),
          "distributedERC20: Insufficient balance to distribute");
    } else {
      distributeAmount = ERC20(tokenAddress).balanceOf(address(this));
      require(
          distributeAmount > 0,
          "distributedERC20: No balance to distribute");
    }

    uint remainingValue = distributeAmount;
    for (uint i = 0; i < payees.length; ++i) {
      uint payeePortion = computePortion(distributeAmount, payees[i]);
      remainingValue -= payeePortion;
      ERC20(tokenAddress).transfer(payees[i].receiver, payeePortion);
    }
    if (remainingValue > 0) {
      ERC20(tokenAddress).transfer(residualReceiver, remainingValue);
    }
  }

  receive() external payable nonReentrant {
    require(msg.value > 0, "receive: No payment included.");
    uint remainingValue = msg.value;
    for (uint i = 0; i < payees.length; ++i) {
      uint payeePortion = computePortion(msg.value, payees[i]);
      remainingValue -= payeePortion;
      payable(payees[i].receiver).transfer(payeePortion);
    }
    if (remainingValue > 0) {
      payable(residualReceiver).transfer(remainingValue);
    }
  }

  function payeeInfo(uint index) external view returns (address receiver, uint portion) {
    require(index <= payees.length, "payeeInfo: Index out of bounds");
    if (index == payees.length) {
      return (residualReceiver, 1 ether - totalPayeePortion);
    } else {
      Payee memory payee = payees[index];
      return (payee.receiver, payee.portion);
    }
  }
}
