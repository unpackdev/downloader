// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./Ownable.sol";

interface IOddContract {
  function ownerOf(uint256 tokenId) external returns (address);
  function transferFrom(address from, address to, uint256 tokenId) external;
}

contract OddLife is Ownable {
  uint256 constant PRICE = 0.01 ether;

  IOddContract private immutable oddFrensContract;
  IOddContract private immutable oddPetsContract;

  mapping(uint256 => bool) public isAlive;

  event BringToLife(uint256 indexed tokenId);

  constructor(address _oddFrensContract, address _oddPetsContract) {
    oddFrensContract = IOddContract(_oddFrensContract);
    oddPetsContract = IOddContract(_oddPetsContract);
  }

  function sendPetsToLive(uint256 _frenId, uint256[] calldata _petIds) external {
    require(
      oddFrensContract.ownerOf(_frenId) == msg.sender,
      "NOT FREN OWneR"
    );
    require(isAlive[_frenId] == false, "aLrEadY ALiVe");
    require(_petIds.length == 3, "NEEds 3 PeTs");

    for (uint256 i = 0; i < _petIds.length; ++i) {
      require(
        oddPetsContract.ownerOf(_petIds[i]) == msg.sender,
        "NOT PET OWneR"
      );

      oddPetsContract.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _petIds[i]);
    }
    
    isAlive[_frenId] = true;

    emit BringToLife(_frenId);
  }

  function payToLive(uint256 _tokenId) external payable {
    require(
      oddFrensContract.ownerOf(_tokenId) == msg.sender,
      "NOT FREN OWneR"
    );
    require(isAlive[_tokenId] == false, "aLrEadY ALiVe");
    require(msg.value == PRICE, "EthEr sENt is NOT corrEcT");
    
    isAlive[_tokenId] = true;

    emit BringToLife(_tokenId);
  }

  function areAlive(uint256[] calldata _tokenIds)
    external
    view
    returns (bool[] memory)
  {
    bool[] memory alive = new bool[](_tokenIds.length);

    for (uint256 i = 0; i < _tokenIds.length; ++i) {
      alive[i] = isAlive[_tokenIds[i]];
    }

    return alive;
  }

  function devBringToLife(uint256[] calldata _tokenIds) external onlyOwner {
    for (uint256 i = 0; i < _tokenIds.length; ++i) {
      isAlive[_tokenIds[i]] = true;

      emit BringToLife(_tokenIds[i]);
    }
  }

  function withdraw() external onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "WIThDRaW UNsucCEssFUl"
    );
  }
}
