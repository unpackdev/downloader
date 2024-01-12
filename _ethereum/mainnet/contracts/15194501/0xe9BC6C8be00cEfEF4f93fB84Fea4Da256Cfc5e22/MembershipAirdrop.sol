//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./IERC721.sol";

//This contract is for dropping the membership NFT to everyone
contract NFTAirdrop {

  struct Airdrop {
    address nft;
    uint id;
  }

  uint public nextAirdropId;
  address public admin;

  mapping(uint => Airdrop) public airdrops;
  mapping(address => bool) public recipients;

  constructor() {
    admin = msg.sender;
  }

  //Add the list of NFTs we want to airdrop - this contains the NFT address and an ID
  function addAirdrops(Airdrop[] memory _airdrops) external {
    uint _nextAirdropId = nextAirdropId;
    for(uint i = 0; i < _airdrops.length; i++) {
      airdrops[_nextAirdropId] = _airdrops[i];
      //The calling address should own all the NFTs
      IERC721(_airdrops[i].nft).transferFrom(
        msg.sender, 
        address(this), 
        _airdrops[i].id
      );
      _nextAirdropId++;
    }
  }

//Add all the whitelisted recepients addresses
  function addRecipients(address[] memory _recipients) external {
    require(msg.sender == admin, 'only admin');
    for(uint i = 0; i < _recipients.length; i++) {
      recipients[_recipients[i]] = true;
    }
  }

//Remove the whitelisted recepients addresses if required
  function removeRecipients(address[] memory _recipients) external {
    require(msg.sender == admin, 'only admin');
    for(uint i = 0; i < _recipients.length; i++) {
      recipients[_recipients[i]] = false;
    }
  }

//Function to claim the airdrop
  function claim() external {
    require(recipients[msg.sender] == true, 'recipient not registered');
    recipients[msg.sender] = false;
    Airdrop storage airdrop = airdrops[nextAirdropId];
    IERC721(airdrop.nft).transferFrom(address(this), msg.sender, airdrop.id);
    nextAirdropId++;
  }
}