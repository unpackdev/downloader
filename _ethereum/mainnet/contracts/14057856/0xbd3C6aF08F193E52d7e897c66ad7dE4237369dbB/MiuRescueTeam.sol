// SPDX-License-Identifier: GPL-3.0
// Author: Pagzi Tech Inc. | 2022
// Miu Rescue Team | 2022
pragma solidity ^0.8.11;
import "./ERC721.sol";
import "./Ownable.sol";

contract MiuRescueTeam is ERC721, Ownable {
  string public baseURI;
  uint256 public supply = 10000;
  uint256 public totalSupply;
  address miuDevTeam = 0x2d0F4bcD4D2f08FAbD5a9e6Ed7c7eE86aFC3B73f;
  address miuFounder = 0xeC35A4F27f5163e3035510E13a227fA518c4906d;
  address miuFounder1 = 0x9aFaAaE1FE850CD71324930Fa399BC41ae7Aa0ce;
  address miuFounder2 = 0xDF210CF3aec762903c8F9bf4249FDb4aE84fAf19;
  address miuAdvisor = 0xfBC76261FD55cF91b81a97dbcc2B3F6118f2B935;
  address miuIllustrator1 = 0x1D1997Edf9Ea8D75bCd2E24211AA3665f0146374;
  address miuIllustrator2 = 0x4ce808fAd9923398e63D8A760f24409301BdC0F9;
  address miuCommunity1 = 0x81845ec7df4Fa5776998053457b8c4fB1e60CF84;
  address miuCommunity2 = 0xbc164c450B9b56669649c9b7AaB50e65085E5F6D;
  address miuDiscord = 0x331bB44Bfd8095B8887A12a4A854D179386b0c44;
  address miuWfAWDonate = 0x9D5025B327E6B863E5050141C987d988c07fd8B2;
  address miuProjectBox = 0xC20786135D630B3F79F1413D0d8cF401F1bDb860;
  //presale settings
  uint256 public publicDate = 1642975200000;

  constructor(
  string memory _initBaseURI
  ) ERC721("Miu Rescue Team", "MIU"){
  setBaseURI(_initBaseURI);
  mintVault();
  }
  
  function getPrice(uint256 quantity) public view returns (uint256){
  uint256 totalPrice = 0;
  if (publicDate <= block.timestamp) {
  for (uint256 i = 0; i < quantity; i++) {
  totalPrice += 0.06 ether;
  }
  return totalPrice;
  }
  uint256 current = totalSupply;
  for (uint256 i = 0; i < quantity; i++) {
  if (current >= 1800) {
  totalPrice += 0.06 ether;
  } else {
  totalPrice += 0.04 ether;
  }
  current++;
  }
  return totalPrice;
  }
  // public
  function mint(uint256 _mintAmount) public payable{
  require(publicDate <= block.timestamp, "Not yet");
  require(totalSupply + _mintAmount + 1 <= supply, "0" );
  require(msg.value >= getPrice(_mintAmount));
  for (uint256 i; i < _mintAmount; i++) {
  _safeMint(msg.sender, totalSupply + 1 + i);
  }
  totalSupply += _mintAmount;
  }
  function presaleMint(uint256 _mintAmount) public payable{
  require(totalSupply + _mintAmount + 1 <= supply, "0" );
  require(msg.value >= getPrice(_mintAmount));
  for (uint256 i; i < _mintAmount; i++) {
  _safeMint(msg.sender, totalSupply + 1 + i);
  }
  totalSupply += _mintAmount;
  }

  //only owner
  function gift(uint[] calldata quantity, address[] calldata recipient) public onlyOwner{
  require(quantity.length == recipient.length, "Provide quantities and recipients" );
  uint totalQuantity = 0;
  for(uint i = 0; i < quantity.length; ++i){
  totalQuantity += quantity[i];
  }
  require(totalSupply + totalQuantity + 1 <= supply, "0" );
  for(uint i = 0; i < recipient.length; ++i){
  for(uint j = 0; j < quantity[i]; ++j){
  _safeMint(recipient[i], totalSupply + 1);
	totalSupply++;
  }
  }
  }
  function withdraw() public onlyOwner {
  uint256 balance = address(this).balance;
  payable(miuDevTeam).transfer((balance * 150) / 1000);
  payable(miuFounder1).transfer((balance * 190) / 1000);
  payable(miuFounder2).transfer((balance * 190) / 1000);
  payable(miuAdvisor).transfer((balance * 100) / 1000);
  payable(miuIllustrator1).transfer((balance * 80) / 1000);
  payable(miuIllustrator2).transfer((balance * 80) / 1000);
  payable(miuCommunity1).transfer((balance * 70) / 1000);
  payable(miuCommunity2).transfer((balance * 70) / 1000);
  payable(miuDiscord).transfer((balance * 40) / 1000);
  payable(miuProjectBox).transfer((balance * 10) / 1000);
  payable(miuWfAWDonate).transfer((balance * 20) / 1000);
  }
  function setSupply(uint256 _supply) public onlyOwner {
  supply = _supply;
  }
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
  baseURI = _newBaseURI;
  }
  
  //internal
  function mintVault() internal {
  for (uint256 i; i < 130; i++) {
  _safeMint(miuFounder, totalSupply + 1 + i);
  }
  totalSupply = 130;
  }
  function _baseURI() internal view override returns (string memory) {
  return baseURI;
  }
}