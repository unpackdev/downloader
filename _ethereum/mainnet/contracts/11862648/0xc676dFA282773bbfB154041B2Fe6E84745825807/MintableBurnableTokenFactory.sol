// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./MintableBurnableSyntheticToken.sol";
import "./MintableBurnableIERC20.sol";
import "./Lockable.sol";

contract MintableBurnableTokenFactory is Lockable {
  function createToken(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals
  ) public virtual nonReentrant() returns (MintableBurnableIERC20 newToken) {
    MintableBurnableSyntheticToken mintableToken =
      new MintableBurnableSyntheticToken(tokenName, tokenSymbol, tokenDecimals);
    mintableToken.addAdmin(msg.sender);
    mintableToken.renounceAdmin();
    newToken = MintableBurnableIERC20(address(mintableToken));
  }
}
