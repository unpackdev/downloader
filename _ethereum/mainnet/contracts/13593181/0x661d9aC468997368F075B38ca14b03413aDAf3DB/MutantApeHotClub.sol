// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./NoobClaimableCollectible.sol";
import "./Noobs.sol";

/**
 * @title MutantApeHotClub - a NOOB claimable Certified Collectible
 * @author COBA
 */
contract MutantApeHotClub is NoobClaimableCollectible {

  uint256 private constant _CLAIM_PRICE = 30000000000000000; // 0.03 ETH
  string private constant _MAHC_BASE_URI = "ipfs://QmYFUPUAAGdFA97AXpuyPc6pDFuEBcKDDfDSnfUWjsBjgP/";
  address private constant _MAYC_ADDRESS = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;

  constructor() NoobClaimableCollectible("MutantApeHotClub", "MAHC", _MAHC_BASE_URI, _MAYC_ADDRESS, _CLAIM_PRICE) {}
}
