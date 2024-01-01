// SPDX-License-Identifier: ISC
pragma solidity 0.7.5;

import "./VestingEscrowV2.sol";

/**
 * @title VestingEscrowV4
 */
contract VestingEscrowV4 is VestingEscrowV2 {
  constructor(address token_, address delegateRegistry_) VestingEscrowV2(token_, delegateRegistry_) {}

  function terminateEscrow(address tokenRecipient) external onlyOwner {
    require(tokenRecipient != address(0), "invalid address");
    uint amount = _tokenBalance(token);
    _transferAsset(token, tokenRecipient, amount);
  }
}
