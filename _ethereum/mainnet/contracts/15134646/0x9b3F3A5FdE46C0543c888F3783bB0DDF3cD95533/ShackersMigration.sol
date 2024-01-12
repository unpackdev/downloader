// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./OpenSeaMigration.sol";

interface IShackers {
  function mint(address to, uint256 tokenId, string calldata tokenUri) external;
}

interface ISurprise {
  function mint(address to, uint256 id, uint96 amount) external;
}

/*
                            :+
                           -#:
                          -##
                         .##*
                         =###
                         *###:     +
                         *###*     =*.
                   +.    +####*-   :##-
                   *+  . .#######++*###*.
                 .*#+ .*  +##############+.
                 +#*. +#  .################-
                     +#+   +################+.
                   :*##:   -##########*==#####:
                  +####:   -########=:.+#######-
                :*######=-=######+-  -##########-
               -##############*=.  .*############:
              :#############=:    -##############*
             .###########+-      =################-
             *#########=.          :-+############+
            :##########*+-:            :=*#########
            +#######+*######*+-        .=##########
            ########= .=*#####-      :+############
            #########.   .=*#:     -*#############*
            +########=      .    -*###############-
            :#########*+-:      +################*
             +###########+  :-:   :+############*.
              +#########= :*####*+-:.-+########*.
               -#######=-*###########*+=+*####=
                 -*#########################=.
                   :=*##################*=:
                       :-=+**####**+=-:.


@title Shackers Migration - Bring OG Shackers to the other side
@author loltapes.eth
*/
contract ShackersMigration is OpenSeaMigration, Ownable, Pausable, ReentrancyGuard {

  IShackers public immutable SHACKERS_CONTRACT;
  ISurprise public immutable SURPRISE_CONTRACT;

  uint96 internal constant SURPRISE_AMOUNT = 3;
  uint256 internal constant SURPRISE_ID = 0;

  constructor(
    address shackersContractAddress,
    address surpriseContractAddress,
    address openSeaStoreAddress,
    address makerAddress
  ) OpenSeaMigration(openSeaStoreAddress, makerAddress) {
    SHACKERS_CONTRACT = IShackers(shackersContractAddress);
    SURPRISE_CONTRACT = ISurprise(surpriseContractAddress);

    _pause();
  }

  function setPaused(bool paused) external onlyOwner {
    if (paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  function _onMigrateLegacyToken(
    address owner,
    uint256 legacyTokenId,
    uint256 internalTokenId,
    uint256 amount,
    bytes calldata /* data */
  ) internal override whenNotPaused nonReentrant {
    // burn OpenSea legacy shacker; we could also transfer to MAKER and change the metadata but decided not to
    // amount is always `1`, so we don't bother to support minting multiple below
    _burn(legacyTokenId, amount);

    // reverts on invalid tokens as a safeguard to not migrate just any token
    uint256 newTokenId = convertInternalToNewId(internalTokenId);

    // mint shiny new shacker
    SHACKERS_CONTRACT.mint(owner, newTokenId, "");

    // mint surprise
    // OpenSea seems to not invoke onERC1155BatchReceived, but instead onERC1155Received per token transferred
    // when calling `safeBatchTransferFrom`, so minting the surprise can't be batched :/
    SURPRISE_CONTRACT.mint(owner, SURPRISE_ID, SURPRISE_AMOUNT);
  }

  function convertInternalToNewId(uint256 id) pure public returns (uint256) {
    // here comes the fun part; mapping of the legacy NFT IDs to IDs in this contract
    // Grown up Shackers 0-102 plus the X Shacker will be mapped to token IDs 0-103.
    // Babies come thereafter

    if (id > 0 && id < 5) {            //  1-4  =>  0-3
      return id - 1;
    } else if (id > 5 && id < 10) {    //  6-9  =>  4-7
      return id - 2;
    } else if (id > 10 && id < 18) {   // 11-17 => 8-14
      return id - 3;
    } else if (id > 18 && id < 24) {   // 19-23 => 15-19
      return id - 4;
    } else if (id == 26 || id == 27) { // 26-27 => 20-21
      return id - 6;
    } else if (id > 28 && id < 32) {   // 29-31 => 22-24
      return id - 7;
    } else if (id == 34 || id == 35) { // 34-35 => 25-26
      return id - 9;
    } else if (id == 50) {
      return 27;
    } else if (id > 51 && id < 59) {   // 52-58 => 28-34
      return id - 24;
    } else if (id == 62) {
      return 35;
    } else if (id == 67) {
      return 36;
    } else if (id > 68 && id < 73) {   // 69-72 => 37-40
      return id - 32;
    } else if (id == 75 || id == 76) { // 75-76 => 41-42
      return id - 34;
    } else if (id > 77 && id < 86) {   // 78-85 => 43-50
      return id - 35;
    } else if (id == 90 || id == 91) { // 90-91 => 51-52
      return id - 39;
    } else if (id == 101) {
      return 53;
    } else if (id == 103) {
      return 54;
    } else if (id == 105) {
      return 55;
    } else if (id == 108) {
      return 56;
    } else if (id == 112) {
      return 57;
    } else if (id == 113) {
      return 58;
    } else if (id == 114) {
      return 59;
    } else if (id == 117) {
      return 60;
    } else if (id == 119) {
      return 61;
    } else if (id == 121) {
      return 62;
    } else if (id == 123) {
      return 63;
    } else if (id == 125) {
      return 64;
    } else if (id == 127) {
      return 65;
    } else if (id == 131) {
      return 66;
    } else if (id == 135) {
      return 67;
    } else if (id > 137 && id < 141) { // 138-140 => 68-70
      return id - 70;
    } else if (id == 143) {
      return 71;
    } else if (id == 145) {
      return 72;
    } else if (id == 147) {
      return 73;
    } else if (id == 148) {
      return 74;
    } else if (id == 151) {
      return 75;
    } else if (id == 162) {
      return 76;
    } else if (id == 171) {
      return 77;
    } else if (id == 180) {
      return 78;
    } else if (id == 182) {
      return 79;
    } else if (id == 189) {
      return 80;
    } else if (id == 192) {
      return 81;
    } else if (id == 193) {
      return 82;
    } else if (id == 197) {
      return 83;
    } else if (id == 199) {
      return 84;
    } else if (id == 201) {
      return 85;
    } else if (id == 202) {
      return 86;
    } else if (id > 203 && id < 218) { // 204-217 => 87-100
      return id - 117;
    } else if (id == 268) {
      return 101;
    } else if (id == 269) {
      return 102;
    } else if (id == 200) {
      return 103;
    } else if (id == 5) {  // BABIES FROM HERE
      return 104;
    } else if (id == 10) {
      return 105;
    } else if (id == 18) {
      return 106;
    } else if (id == 32) {
      return 107;
    } else if (id == 36) {
      return 108;
    } else if (id > 58 && id < 62) { // 59-61 => 109-111
      return id + 50;
    } else if (id == 92) {
      return 112;
    } else if (id == 93) {
      return 113;
    } else if (id == 102) {
      return 114;
    } else if (id == 106) {
      return 115;
    } else if (id == 107) {
      return 116;
    } else if (id == 132) {
      return 117;
    } else if (id > 171 && id < 175) { // 172-174 => 118-120
      return id - 54;
    } else if (id == 177) {
      return 121;
    } else if (id == 178) {
      return 122;
    } else if (id > 269 && id < 276) { // 270-275 => 123-128
      return id - 147;
    }

    // reaching this means no valid ID was matched
    revert("Invalid Token ID");
  }
}
