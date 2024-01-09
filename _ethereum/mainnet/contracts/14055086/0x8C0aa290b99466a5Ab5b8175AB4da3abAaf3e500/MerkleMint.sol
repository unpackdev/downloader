// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

/*
 ▄████▄   ██▀███   ▄▄▄      ▒███████▒▓██   ██▓
▒██▀ ▀█  ▓██ ▒ ██▒▒████▄    ▒ ▒ ▒ ▄▀░ ▒██  ██▒
▒▓█    ▄ ▓██ ░▄█ ▒▒██  ▀█▄  ░ ▒ ▄▀▒░   ▒██ ██░
▒▓▓▄ ▄██▒▒██▀▀█▄  ░██▄▄▄▄██   ▄▀▒   ░  ░ ▐██▓░
▒ ▓███▀ ░░██▓ ▒██▒ ▓█   ▓██▒▒███████▒  ░ ██▒▓░
░ ░▒ ▒  ░░ ▒▓ ░▒▓░ ▒▒   ▓▒█░░▒▒ ▓░▒░▒   ██▒▒▒
  ░  ▒     ░▒ ░ ▒░  ▒   ▒▒ ░░░▒ ▒ ░ ▒ ▓██ ░▒░
░          ░░   ░   ░   ▒   ░ ░ ░ ░ ░ ▒ ▒ ░░
░ ░         ░           ░  ░  ░ ░     ░ ░
░                           ░         ░ ░
 ▄████▄   ██▓     ▒█████   █     █░ ███▄    █   ██████
▒██▀ ▀█  ▓██▒    ▒██▒  ██▒▓█░ █ ░█░ ██ ▀█   █ ▒██    ▒
▒▓█    ▄ ▒██░    ▒██░  ██▒▒█░ █ ░█ ▓██  ▀█ ██▒░ ▓██▄
▒▓▓▄ ▄██▒▒██░    ▒██   ██░░█░ █ ░█ ▓██▒  ▐▌██▒  ▒   ██▒
▒ ▓███▀ ░░██████▒░ ████▓▒░░░██▒██▓ ▒██░   ▓██░▒██████▒▒
░ ░▒ ▒  ░░ ▒░▓  ░░ ▒░▒░▒░ ░ ▓░▒ ▒  ░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░
  ░  ▒   ░ ░ ▒  ░  ░ ▒ ▒░   ▒ ░ ░  ░ ░░   ░ ▒░░ ░▒  ░ ░
░          ░ ░   ░ ░ ░ ▒    ░   ░     ░   ░ ░ ░  ░  ░
░ ░          ░  ░    ░ ░      ░             ░       ░
░

Crazy Clowns Insane Asylum
2021, V1.1
https://ccia.io
*/

import "./MerkleProof.sol";

import "./Pausable.sol";
import "./Ownable.sol";
import "./ICrazyClown.sol";

contract MerkleMint is Ownable, Pausable {
  bytes32 public merkleRoot;

  //Address => tokenIDs
  mapping(address => uint256) public mintRecords;

  //Crazy Clown interface
  ICrazyClown public crazyClown;

  constructor(address _crazyClown, bytes32 _hash) {
    crazyClown = ICrazyClown(_crazyClown);
    merkleRoot = _hash;
    _pause();
  }

  function merkleMint(
    uint256 numberOfTokens,
    uint256 maxQuantity,
    bytes32[] memory _merkleProof
  ) public whenNotPaused {
    require(crazyClown.totalSupply() + numberOfTokens <= crazyClown.maxSupply(), 'Mint would exceed max supply');

    bytes32 node = keccak256(abi.encode(msg.sender, maxQuantity));
    require(MerkleProof.verify(_merkleProof, merkleRoot, node), 'Address not eligible for mint');

    uint256 mintedNum = mintRecords[msg.sender];
    require(mintedNum + numberOfTokens <= maxQuantity, 'Mint would exceed max allowed');

    mintRecords[msg.sender] = mintRecords[msg.sender] + numberOfTokens;

    crazyClown.sendReserve(msg.sender, numberOfTokens);
  }

  function getMintRecord(address _minter) public view returns (uint256) {
    return mintRecords[_minter];
  }

  function setMerkleRoot(bytes32 _hash) external onlyOwner {
    merkleRoot = _hash;
  }

  function setMintContract(address _contract) external onlyOwner {
    crazyClown = ICrazyClown(_contract);
  }

  function togglePause() public onlyOwner {
    if (paused() == true) {
      require(crazyClown.saleStarted() == true, 'Public Sale not started');
      _unpause();
    } else {
      _pause();
    }
  }
}
