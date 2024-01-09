// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./LotteryBox.sol";
import "./HunterHound.sol";


contract Mintor is LotteryBox {

  event MintEvent(address indexed operator, uint hunters, uint hounds, uint256[] tokenIds);

  struct Minting {
    uint blockNumber;
    uint amount;
  }

  // the cost to mint in every phase
  uint256 constant MINT_PRICE = .067 ether;
  uint256 constant MINT_PHASE2_PRICE = 40000 ether;
  uint256 constant MINT_PHASE3_PRICE = 60000 ether;
  uint256 constant MINT_PHASE4_PRICE = 80000 ether;

  // the amount corresponds to every hunter's alpha score
  uint constant maxAlpha8Count = 500;
  uint constant maxAlpha7Count = 1500;
  uint constant maxAlpha6Count = 3000;
  uint constant maxAlpha5Count = 5000;

  // 50,000 tokens in total and mint amount in every phase
  uint constant MAX_TOKENS = 50000;
  uint constant PHASE1_AMOUNT = 10000;
  uint constant PHASE2_AMOUNT = 10000;
  uint constant PHASE3_AMOUNT = 20000;
  uint constant PHASE4_AMOUNT = 10000;


  // saves metadataID for next hunter
  uint private alpha8Count = 1;
  uint private alpha7Count = 1;
  uint private alpha6Count = 1;
  uint private alpha5Count = 1;

  // saves metadataId for next hound
  uint internal totalHoundMinted = 1;

  // saves mint request of users
  mapping(address => Minting) internal mintRequests;

  // total minted amount
  uint256 internal minted;

  // total minted number of hunters
  uint256 internal hunterMinted;

  // recorded mint requests
  uint internal requested;

  /**
   * check mint request
   * @return blockNumber mint request block
   * @return amount mint amount
   * @return state mint state
   * @return open NFT reavel countdown
   * @return timeout NFT request reveal timeout countdown
   */
  function _mintRequestState(address requestor) internal view returns (uint blockNumber, uint amount, uint state, uint open, uint timeout) {
    Minting memory req = mintRequests[requestor];
    blockNumber = req.blockNumber;
    amount = req.amount;
    state = boxState(req.blockNumber);
    open = openCountdown(req.blockNumber);
    timeout = timeoutCountdown(req.blockNumber);
  }

  /**
   * create mint request, record requested block and data
   */
  function _request(address requestor, uint amount) internal {

    require(mintRequests[requestor].blockNumber == 0, 'Request already exists');
    
    mintRequests[requestor] = Minting({
      blockNumber: block.number,
      amount: amount
    });

    requested = requested + amount;
  }

  /**
   * process mint request to get random number, through which to determine hunter or hound
   */
  function _receive(address requestor, HunterHound hh) internal {
    Minting memory minting = mintRequests[requestor];
    require(minting.blockNumber > 0, "No mint request found");

    delete mintRequests[requestor];

    uint random = openBox(minting.blockNumber);
    uint boxResult = percentNumber(random);
    uint percent = boxResult;
    uint hunters = 0;
    uint256[] memory tokenIds = new uint256[](minting.amount);
    for (uint256 i = 0; i < minting.amount; i++) {
      HunterHoundTraits memory traits;
      if (i > 0 && boxResult > 0) {
        random = simpleRandom(percent);
        percent = percentNumber(random);
      }
      if (percent == 0) {
        traits = selectHound();
      } else if (percent >= 80) {
        traits = selectHunter(random);
      } else {
        traits = selectHound();
      }
      minted = minted + 1;
      hh.mintByController(requestor, minted, traits);
      tokenIds[i] = minted;
      if (traits.isHunter) {
        hunters ++;
      }
    }
    if (hunters > 0) {
      hunterMinted = hunterMinted + hunters;
    }
    emit MintEvent(requestor, hunters, minting.amount - hunters, tokenIds);
  }

  /**
   *  return a hunter, if hunters run out, return a hound
   * @param random make parameter random a random seed to generate another random number to determine alpha score of a hunter
   *               if number of hunters with corresponding alpha score runs out, it chooses the one with alpha score minus one util it runs out, otherwise it will be a hound
   *
   * probabilities of hunters with different alpha score and their numbers:
   * alpha 8: 5%   500
   * alpha 7: 15%  1500
   * alpha 6: 30%  3000
   * alpha 5: 50%  5000
   */
  function selectHunter(uint random) private returns(HunterHoundTraits memory hh) {
    
    random = simpleRandom(random);
    uint percent = percentNumber(random);
    if (percent <= 5 && alpha8Count <= maxAlpha8Count) {
      hh.alpha = 8;
      hh.metadataId = alpha8Count;
      alpha8Count = alpha8Count + 1;
    } else if (percent <= 20 && alpha7Count <= maxAlpha7Count) {
      hh.alpha = 7;
      hh.metadataId = alpha7Count;
      alpha7Count = alpha7Count + 1;
    } else if (percent <= 50 && alpha6Count <= maxAlpha6Count) {
      hh.alpha = 6;
      hh.metadataId = alpha6Count;
      alpha6Count = alpha6Count + 1;
    } else if (alpha5Count <= maxAlpha5Count) {
      hh.alpha = 5;
      hh.metadataId = alpha5Count;
      alpha5Count = alpha5Count + 1;
    } else {
      return selectHound();
    }
    hh.isHunter = true;

  }

  /**
   * return a hound
   */
  function selectHound() private returns(HunterHoundTraits memory hh) {
    hh.isHunter = false;
    hh.metadataId = totalHoundMinted;
    totalHoundMinted = totalHoundMinted + 1;
  }

}