//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";

import "./IDiamondCut.sol";
import "./IDiamondLoupe.sol";
import "./IERC173.sol";
import "./IToken.sol";

import "./LibDiamond.sol";
import "./ERC721ALib.sol";
import "./MetadataLib.sol";

import "./DiamondInit.sol";

library DiamondLib {

  bytes32 internal constant DIAMOND_STORAGE_POSITION =
    keccak256("diamond.nextblock.bitgem.app.DiamondStorage.storage");

  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }
}
