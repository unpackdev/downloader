// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CertifiedCollectible.sol";
import "./Noobs.sol";

/**
 * @title Base contract for Certified Collectibles that can be claimed with NOOBS
 * @author COBA
 */
contract NoobClaimableCollectible is CertifiedCollectible {

  uint256 public claimPrice;
  address private constant _NOOBS_ADDRESS = 0x7D7F6f004a421f980fC2d4522BA294edDC880A00;
  address payable private constant _WALLET = payable(0x0A35FCaE3ABe325C040dcFa43f5b5DF195078f7f);

  Noobs noobs;
  mapping(uint => bool) private _noobReceived;

  constructor(
    string memory name,
    string memory symbol,
    string memory collectibleURI,
    address originalAddress,
    uint256 claimPrice_
  ) CertifiedCollectible(name, symbol, collectibleURI, originalAddress) {
    noobs = Noobs(_NOOBS_ADDRESS);
    claimPrice = claimPrice_;
  }

  /**
   * Claims the token ids provided. Noobs can optionally be used for credits instead of payments
   * @param tokenIds BAHC tokens to claim
   * @param noobIds noobs being used for credits
   */
  function claim(uint256[] memory tokenIds, uint256[] memory noobIds) external payable {
    uint256 noobCredits = 0;
    uint256 noobId;
    for (uint256 i = 0; i < noobIds.length; i++) {
      noobId = noobIds[i];
      require(!_noobReceived[noobId], "A NOOB you provided has already been used");
      noobCredits += claimPrice;
      _noobReceived[noobId] = true;
    }
    require(noobCredits + msg.value >= claimPrice * tokenIds.length, "You must either own a NOOB or pay .03 ETH per token");

    uint256 tokenId;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      _claim(tokenId);
    }
  }

  /**
   * Used to see if noobIds have been used already
   * @param noobIds list of noobIds to check
   * @return boolean list indicating if the noob in the corresponding index of noobIds has been used already
   */
  function haveNoobsBeenReceived(uint256[] calldata noobIds) external view returns(bool[] memory) {
    bool[] memory noobsReceivedStatus = new bool[](noobIds.length);
    for (uint256 i = 0; i < noobIds.length; i++) {
      noobsReceivedStatus[i] = _noobReceived[noobIds[i]];
    }
    return noobsReceivedStatus;
  }

  /**
   * Owner Only
   */

  function setBaseURI(string memory baseURI) external onlyOwner {
    _setBaseURI(baseURI);
  }

  /**
   * Overridable in case alternate withdrawel address or breakdown is needed
   */
  function withdrawFunds() external virtual onlyOwner {
    _WALLET.transfer(address(this).balance);
  }

  /**
   * Modify price to claim collectible
   * @param newClaimPrice new price
   */
  function setClaimPrice(uint256 newClaimPrice) external onlyOwner {
    claimPrice = newClaimPrice;
  }
}
