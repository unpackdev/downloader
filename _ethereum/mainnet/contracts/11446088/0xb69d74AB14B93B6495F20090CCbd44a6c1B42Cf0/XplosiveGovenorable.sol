// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./Ownable.sol";

contract XplosiveGovenorable is Ownable {
  address private _governor;

  event TransferredGovenorship(address indexed previousGovenor, address indexed newGovenor);

  constructor()
  internal
  {
    address msgSender = _msgSender();
    _governor = msgSender;
    emit TransferredGovenorship(address(0), msgSender);
  }

  function Governor() public view returns(address) {
    return _governor;
  }

  modifier onlyGovenor() {
    require(_governor == _msgSender(), "caller is not govenor");
    _;
  }

  function transferGovenorship(address newGovenor) public virtual onlyOwner {
    require(newGovenor != address(0), "new rebaser is address zero");
    emit TransferredGovenorship(_governor, newGovenor);
    _governor = newGovenor;
  }
}
