// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: mhxalt.eth
/// @author: seesharp.eth

import "./Ownable.sol";

/// __/\\\\\\\\\\\\\\\_________________________________________/\\\\\\\\\\\\\____/\\\\\\___________________________________________________________        
///  _\////////////\\\_________________________________________\/\\\/////////\\\_\////\\\_________________________________/\\\______________________       
///   ___________/\\\/__________________________________________\/\\\_______\/\\\____\/\\\________________________________\/\\\______________________      
///    _________/\\\/_________/\\\\\\\\___/\\/\\\\\\_____________\/\\\\\\\\\\\\\\_____\/\\\________/\\\\\________/\\\\\\\\_\/\\\\\\\\_____/\\\\\\\\\\_     
///     _______/\\\/_________/\\\/////\\\_\/\\\////\\\____________\/\\\/////////\\\____\/\\\______/\\\///\\\____/\\\//////__\/\\\////\\\__\/\\\//////__    
///      _____/\\\/__________/\\\\\\\\\\\__\/\\\__\//\\\___________\/\\\_______\/\\\____\/\\\_____/\\\__\//\\\__/\\\_________\/\\\\\\\\/___\/\\\\\\\\\\_   
///       ___/\\\/___________\//\\///////___\/\\\___\/\\\___________\/\\\_______\/\\\____\/\\\____\//\\\__/\\\__\//\\\________\/\\\///\\\___\////////\\\_  
///        __/\\\\\\\\\\\\\\\__\//\\\\\\\\\\_\/\\\___\/\\\___________\/\\\\\\\\\\\\\/___/\\\\\\\\\__\///\\\\\/____\///\\\\\\\\_\/\\\_\///\\\__/\\\\\\\\\\_ 
///         _\///////////////____\//////////__\///____\///____________\/////////////____\/////////_____\/////________\////////__\///____\///__\//////////__

interface DATA_BLOCKS {
  function maxSupply() external view returns (uint256);
  function mintZenBlockActiveTs() external view returns (uint256);
}

contract ZEN_BLOCKS_RARITY is Ownable {
  uint256 public PROVENANCE_HASH = 0;
  uint256 public startingIndexBlock = 0;
  uint256 public startingIndex = 0;

  address public dataBlocksContract;

  constructor(address _dataBlocksContract) {
    dataBlocksContract = _dataBlocksContract;
  }

  function setProvenanceHash(uint256 _provenanceHash) public onlyOwner {
    require(PROVENANCE_HASH == 0, "Provenance Hash Already Set!");
    PROVENANCE_HASH = _provenanceHash;
  }

  function setStartingIndexBlock() public {
    require(startingIndexBlock == 0, "startingIndexBlock alredy set!");
    DATA_BLOCKS db = DATA_BLOCKS(dataBlocksContract);

    require(db.mintZenBlockActiveTs() == 0, "zen block minting hasn't ended");

    startingIndexBlock = block.number;
  }

  function setStartingIndex() public {
    require(startingIndexBlock != 0, "startingIndexBlock not set!");
    require(startingIndex == 0, "startingIndex already set!");

    DATA_BLOCKS db = DATA_BLOCKS(dataBlocksContract);

    uint256 maxSupplyDB = db.maxSupply();

    uint256 usedHash = uint256(blockhash(startingIndexBlock));
    // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
    if ((block.number - startingIndexBlock) > 255) {
      usedHash = uint256(blockhash(block.number - 1));
    }
    startingIndex = usedHash % maxSupplyDB;
    // Prevent default sequence
    if (startingIndex == 0) {
        startingIndex = startingIndex + 1;
    }
  }
}