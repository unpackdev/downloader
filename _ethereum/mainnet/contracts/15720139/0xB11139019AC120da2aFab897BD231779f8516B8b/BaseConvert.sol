// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./BaseModule.sol";

abstract contract BaseConvert is BaseModule {
  constructor(address asset) BaseModule(asset) {}

  function _receiveLoan(
    address borrower,
    uint256 amount,
    uint256 nonce,
    bytes calldata data
  ) internal override returns (uint256 collateralIssued) {
    ConvertLocals memory locals;
    locals.borrower = borrower;
    locals.amount = amount;
    if (data.length > 0) (locals.minOut) = abi.decode(data, (uint256));
    collateralIssued = swap(locals);
    transfer(borrower, collateralIssued);
  }

  function _repayLoan(
    address,
    uint256,
    uint256,
    bytes calldata
  ) internal override returns (uint256) {
    //no-op
    return 0;
  }
}
