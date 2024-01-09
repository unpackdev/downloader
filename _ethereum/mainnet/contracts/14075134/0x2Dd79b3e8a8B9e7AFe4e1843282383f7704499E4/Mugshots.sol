
//  ______                     _    _                   ___  ___                _           _       
//  |  _  \                   | |  | |                  |  \/  |               | |         | |      
//  | | | |___  _ __   ___    | |  | | __ _ _ __ ___    | .  . |_   _  __ _ ___| |__   ___ | |_ ___ 
//  | | | / _ \| '_ \ / _ \   | |/\| |/ _` | '__/ __|   | |\/| | | | |/ _` / __| '_ \ / _ \| __/ __|
//  | |/ / (_) | |_) |  __/   \  /\  / (_| | |  \__ \   | |  | | |_| | (_| \__ \ | | | (_) | |_\__ \
//  |___/ \___/| .__/ \___|    \/  \/ \__,_|_|  |___/   \_|  |_/\__,_|\__, |___/_| |_|\___/ \__|___/
//             | |                                                     __/ |                        
//             |_|                                                    |___/                         
//
//  Created for fun for Dope Wars by @mboyle
//  Learn More at: https://community.dopewars.gg/mugshots
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Strings.sol";

import "./console.sol";

contract Mugshots is ERC721, Pausable, Ownable, ERC721Burnable {

  string  metadataBaseUrl = 'https://community.dopewars.gg/collectibles/';
  address rebelAddress = 0x440DAA861400Bf754B83121479Bf26895F1Df7C4;
  address dopeDaoAddress = 0xB57Ab8767CAe33bE61fF15167134861865F7D22C;
  uint256 public switchoverTimestamp = 1650427200;
  uint256 public costToMint = 69 ether / 1000;

  constructor() ERC721("Dope Wars Mugshots", "MUGSHOT") {}

  function setRebelAddress(address newAddress)
    public
    onlyOwner
  {
    rebelAddress = newAddress;
  }

  function setDopeDaoAddress(address newAddress)
    public
    onlyOwner
  {
    dopeDaoAddress = newAddress;
  }

  function setMetadataBaseUrl(string calldata newUrl) 
    public
    onlyOwner
  {
    metadataBaseUrl = newUrl;
  }

  function setMintPrice(uint256 newPrice) 
    public
    onlyOwner
  {
    costToMint = newPrice;
  }

  function setSwitchoverTimestamp(uint256 newTime)
    public
    onlyOwner
  {
    switchoverTimestamp = newTime;
  }

  function withdraw() public onlyOwner {
    
    uint256 commission = (address(this).balance  * 20) /  100;
  
    if(block.timestamp <= switchoverTimestamp) {
      payable(dopeDaoAddress).transfer(commission);
      payable(rebelAddress).transfer(address(this).balance);
    } else {
      payable(rebelAddress).transfer(commission);
      payable(dopeDaoAddress).transfer(address(this).balance);
    }
  }

  function mint(uint256 tokenId)
    public
    payable
    returns (uint256)
  {
    // Must have enough ETH attached
    require(msg.value >= mintCost(), "Please send the correct amount of ETH");

    _safeMint(msg.sender, tokenId);

    return tokenId;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mintCost() public view returns(uint256) {
    if(msg.sender == address(owner()) || msg.sender == rebelAddress) {
      return(0);
    } else {
      return costToMint;
    }
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
      internal
      whenNotPaused
      override
  {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
    return string(abi.encodePacked(metadataBaseUrl, Strings.toString(tokenId), '/metadata.json'));
  }
}