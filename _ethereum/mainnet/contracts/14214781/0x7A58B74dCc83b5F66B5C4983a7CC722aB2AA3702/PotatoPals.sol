// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

//................................................................................
//............................./@&&&&@&%((#((%&@&@&&&,............................
//.........................&&&&**********************/&&&#........................
//......................@&@*/****************************/@&%.....................
//....................&&#***********************************&&&...................
//..................@@#***************************************&&&.................
//.................&@*****/*************************************&&................
//................&&*********************************************&&...............
//...............&@**********&&&&&%***************&&&&&&**********&&..............
//...............&&*********&&   &&#*************&&   &&(*********&&..............
//..............#&(*****/**/&&   &&**************&&.  &&**********&&..............
//..............*&#**********&&&&&*****************(&&/****//*****&&..............
//...............&&***************************************//******&&..............
//...............,&&***************&&&&&&*/****(@&***************@&...............
//................*&&///*********#&&//&&&&&&&&&&&&&*************&&................
//..................&&************#@&#    &&&&&&&&************(&&.................
//...................,&@**************/#&&&&#/**************/&&...................
//......................&&&*******************************&&@.....................
//.......................,&&&&%*******//**************&&@&&.......................
//..................... &&***/*%&&&&#***********%&&&&#****/@@.....................
//....................&&#//**********/#&&&&&&&#*************&&&...................
//...................@&/*****&&/*********************(&&**/***&@ .................
//..................&&******(&%***********************&&*******&&.................
//.................&&*******&&*************************@&*/*****&&................
//................&&*****/**&&*************************&&*******&&*...............

contract PotatoPals is Ownable, ERC721A {
  using SafeMath for uint256;
  string public potatoUrl;
  uint256 public farm = 10000; 
  uint256 public batch = 20;
  uint256 public water = 0.03 ether;
  mapping(address => bool) public allowlist;
  address founder = 0xd7212FfE2539347BE56BBB9c5BFf796fd8aDea2b;
  address coFounder = 0xCdBB6A67d213BEb6e275722c13Ca0Dd1ad2A00E8;
  address developer = 0x1AF8c7140cD8AfCD6e756bf9c68320905C355658;
  address artist = 0xaf35a6672CE9FCDb205158073D8D4268990304A2;
  address community = 0xAc23Ad166C50537Ac046478580353B57B796a8bF;

  enum SproutStatus {
    OFF, ALLOWLIST, PUBLIC
  }

  SproutStatus public sproutStatus;

  constructor(string memory _potatoUrl) ERC721A("Potato Pals", "PALS", batch, farm) {
    potatoUrl = _potatoUrl;
  }

  /// @notice Sprout a Potato Pal during public mint
  /// @dev Pass in number of pals to sprout
  function sprout(uint256 pals) public payable {
    require(sproutStatus == SproutStatus.PUBLIC, "Public sprouting off");
    require(totalSupply() + pals <= farm, "Over the farm limit");
    require(pals <= batch, "Sprouting too much");
    require(msg.value >= water * pals, "Not enough water");
    _safeMint(msg.sender, pals);
  }

  /// @notice Sprout a Potato Pal during allowlist
  /// @dev Pass in number of pals to sprout. 
  /// @dev Potato Pal Genesis holders are auto allowlisted
  function sproutAllowlist(uint256 pals) public payable {
    require(sproutStatus == SproutStatus.ALLOWLIST, "Allowlist sprouting off");
    require(allowlist[msg.sender], "Not on allowlist");
    require(totalSupply() + pals <= farm, "Over the farm limit");
    require(pals <= batch, "Sprouting too much");
    require(msg.value >= water * pals, "Not enough water");
    _safeMint(msg.sender, pals);
  }


  /// @notice Donate pals to an address
  /// @dev Pass in address and total number of pals to reserve
  function donate(address owner, uint256 pals) external onlyOwner {
    require(totalSupply() + pals <= farm, "Over the farm limit");
    require(pals <= batch, "Donating too much");
    _safeMint(owner, pals);
  }

  /// @notice Harvest funds
  /// @dev When teamHarvest is true funds are split to team. 
  /// @dev When teamHarvest is false funds are sent to community wallet.
  function harvest(bool teamHarvest) external payable onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "farm is dry");
    if (teamHarvest) {
      require(payable(founder).send(balance.mul(30).div(100)));
      require(payable(coFounder).send(balance.mul(25).div(100)));
      require(payable(developer).send(balance.mul(20).div(100)));
      require(payable(artist).send(balance.mul(15).div(100)));
      require(payable(community).send(balance.mul(10).div(100)));
    } else {
      require(payable(community).send(balance));
    }
  }

  /// @notice Set Sprout Status
  /// @dev Status must be either 0 (closed), 1 (allowlist) or 2 (public)
  function setSproutStatus(uint256 status) external onlyOwner {
    require(status <= uint256(SproutStatus.PUBLIC), "Sprout status unrecognized");
    sproutStatus = SproutStatus(status);
  }

  /// @notice Set Water
  /// @dev Pass water (price) amount in gwei
  function setWater(uint256 _water) external onlyOwner {
    water = _water;
  }

  /// @notice Set Potato URL
  /// @dev Pass new potato url string
  function setPotatoUrl(string memory _potatoUrl) external onlyOwner {
    potatoUrl = _potatoUrl;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return potatoUrl;
  }

  /// @notice Set Allowlist
  /// @dev Pass list of pal addresses
  function setAllowlist(address[] calldata pals) external onlyOwner {
    for (uint256 i; i < pals.length; i++) {
      allowlist[pals[i]] = true;
    }
  }
}