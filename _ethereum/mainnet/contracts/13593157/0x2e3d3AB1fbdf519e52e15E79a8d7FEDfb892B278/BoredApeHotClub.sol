// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./NoobClaimableCollectible.sol";
import "./Noobs.sol";

/**
 * @title BoredApeHotClub - a NOOB claimable Certified Collectible
 * @author COBA
 */
contract BoredApeHotClub is NoobClaimableCollectible {

  uint256 private constant _CLAIM_PRICE = 30000000000000000; // 0.03 ETH
  string private constant _BAHC_BASE_URI = "ipfs://QmUGPV5ihTFtVJibQZFVTpLpGEZPFRHzFYiviUUf8rV3Wo/";
  address private constant _BAYC_ADDRESS = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

  constructor() NoobClaimableCollectible("BoredApeHotClub", "BAHC", _BAHC_BASE_URI, _BAYC_ADDRESS, _CLAIM_PRICE) {}
}
