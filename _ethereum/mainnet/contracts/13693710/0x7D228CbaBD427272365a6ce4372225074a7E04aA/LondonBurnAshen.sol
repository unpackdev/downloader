// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Mintable.sol";
import "./ERC721.sol";
import "./LondonBurnMinterBase.sol";
import "./LondonBurn.sol";

abstract contract LondonBurnAshen is LondonBurnMinterBase {
  uint256 constant MIN_SELF_AMOUNT_PER_BURN =    3;
  uint256 constant MAX_SELF_AMOUNT_PER_BURN =    7;

  constructor(
  ) {
  }

  function numBurnFromSelfAmount(uint256 amount) public pure returns (uint256) {
    return amount - 1;
  }

  function londonNeededFromSelfAmount(uint256 amount) public view returns (uint256) {
    if (block.number >= ultraSonicForkBlockNumber) {
      return 1559 ether;
    } else {
      return 1559 ether * amount;
    }
  }

  function mintAshenType(
    uint256[] calldata tokenIds,
    LondonBurn.MintCheck calldata _mintCheck
  ) payable public {
    require(block.number > burnRevealBlockNumber, 'ASHEN has not been revealed yet');
    require(tokenIds.length >= MIN_SELF_AMOUNT_PER_BURN && tokenIds.length <= MAX_SELF_AMOUNT_PER_BURN , "Exceeded self burn range");
    _payLondon(_msgSender(), londonNeededFromSelfAmount(tokenIds.length));
    // burn gifts
    for (uint i = 0; i < tokenIds.length; ++i) {
      londonBurn.transferFrom(_msgSender(), address(0xdead), tokenIds[i]);
    }
    require(_mintCheck.uris.length == numBurnFromSelfAmount(tokenIds.length), "MintCheck required mismatch");
    require(_mintCheck.tokenType == (block.number < ultraSonicForkBlockNumber ? ASHEN_TYPE : ULTRA_SONIC_TYPE), "Must be correct tokenType");
    londonBurn.mintTokenType(_mintCheck);
  }
}