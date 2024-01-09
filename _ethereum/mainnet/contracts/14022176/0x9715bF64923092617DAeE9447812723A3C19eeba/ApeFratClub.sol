// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721PEnum.sol";

contract ApeFratClub is ERC721PEnum, Ownable, PaymentSplitter {
  using Strings for uint256;
  string public apesUrl;
  uint256 public dues = 0.042069 ether;
  uint256 public pledgeLimit = 11;
  uint256 public fullHouse;
  bool public pledgeOn = false;
  bool public blindfolded = true;
  address[] payees = [0x8Ccf49757Cac5b3F061efD9f65B8361007b37727, 0xFEdA8f13bCb118E4b0f42518b68111B3812A2AfF];
  uint256[] split = [50, 50];

  constructor(uint256 _fullHouse, string memory _apesUrl) ERC721P("ApeFratClub", "AFC") PaymentSplitter(payees, split) {
    fullHouse = _fullHouse;
    apesUrl = _apesUrl;
  }

  function pledge(uint256 apes) public payable {
    uint256 members = totalSupply();
    require(pledgeOn, "Walk of shame");
    require(apes < pledgeLimit, "Slow down");
    require(msg.value >= dues * apes, "Pay your dues");
    require(members + apes <= fullHouse, "Full house");
    for (uint256 i; i < apes; ++i) {
      _safeMint(msg.sender, members + i, "");
    }
    delete members;
  }

  function reserve(uint256 apes) public onlyOwner {
    uint256 members = totalSupply();
    require(members + apes <= fullHouse, "Full house");
    for (uint256 i; i < apes; ++i) {
      _safeMint(msg.sender, members + i, "");
    }
    delete members;
  }

  function pledgeFlip() public onlyOwner {
    pledgeOn = !pledgeOn;
  }

  function blindfoldFlip() public onlyOwner {
    blindfolded = !blindfolded;
  }

  function changeDues(uint256 newDues) public onlyOwner {
    dues = newDues;
  }

  function withdrawDues() external payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  function changeApesUrl(string memory newApesUrl) public onlyOwner {
    apesUrl = newApesUrl;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
    if (blindfolded) {
      return bytes(apesUrl).length > 0 ? string(abi.encodePacked(apesUrl)) : "";
    } else {
      return bytes(apesUrl).length > 0 ? string(abi.encodePacked(apesUrl, tokenId.toString(), ".json")) : "";
    }
  }
}