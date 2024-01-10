//SPDX-License-Identifier: UNLICENSED

/*
 _  __     _                   
| |/ /    | |                  
| ' / ___ | | _____  _ __ ___  
|  < / _ \| |/ / _ \| '__/ _ \ 
| . \ (_) |   < (_) | | | (_) |
|_|\_\___/|_|\_\___/|_|  \___/ 
                               
                               
                       _                      
    /\                | |                     
   /  \   ___ __ _  __| | ___ _ __ ___  _   _ 
  / /\ \ / __/ _` |/ _` |/ _ \ '_ ` _ \| | | |
 / ____ \ (_| (_| | (_| |  __/ | | | | | |_| |
/_/    \_\___\__,_|\__,_|\___|_| |_| |_|\__, |
                                         __/ |
                                        |___/ 
A gas-optimized contract standard by @magmar_official
*/

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

contract KokoroAcademy is ERC721, Ownable {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private supply;
  
  uint256 public presaleCost = .065 ether;
  uint256 public presalemaxMintAmountPlusOne = 4;

  uint256 public publicCost = .08 ether;
  uint256 public maxMintAmountPlusOne = 6;

  uint256 public maxSupplyPlusOne = 8889;
  uint256 public devMintAmount = 100;

  string public PROVENANCE;
  string private _baseURIextended;

  bool public saleIsActive;
  bool public presaleIsActive;

  address payable public immutable creatorAddress = payable(0xBdA74fbe5135b374DA44DBE99E0D5e35A1008C94);
  address payable public immutable devAddress = payable(0x15C560d2D9Eb3AF98524aA73BeCBA43E9e6ceF02);
  address payable public immutable marketingAddress = payable(0xb596fB8CcDAFEF91017D311a734F22e572EB0A79);

  mapping(address => uint256) public whitelistBalances;

  bytes32 public merkleRoot;

  constructor() ERC721("Kokoro Academy", "KOKORO") {
    _baseURIextended = "ipfs://QmVntcYNfRoM1NJRhXzQrfdaaGEZHfcBtCuQZeYZv964QU/";
    _mintLoop(msg.sender, devMintAmount);
    saleIsActive = false;
    presaleIsActive = false;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount < maxMintAmountPlusOne, "Invalid mint amount!");
    require(supply.current() + _mintAmount < maxSupplyPlusOne, "Max supply exceeded!");
    _;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata merkleProof) public payable mintCompliance(_mintAmount) callerIsUser {
    require (presaleIsActive, "Presale inactive");
    require(balanceOf(msg.sender) + _mintAmount < presalemaxMintAmountPlusOne, "Attempting to mint too many Waifus for pre-sale");
    require(whitelistBalances[msg.sender] + _mintAmount < presalemaxMintAmountPlusOne, "Attempting to mint too many Waifus for pre-sale (balance transferred out)");
    require(msg.value >= presaleCost * _mintAmount, "Not enough eth sent!");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "You're not whitelisted for presale!");
    _mintLoop(msg.sender, _mintAmount);
    whitelistBalances[msg.sender] += _mintAmount;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) callerIsUser {
    require (saleIsActive, "Public sale inactive");
    require(msg.value >= publicCost * _mintAmount, "Not enough eth sent!");
    _mintLoop(msg.sender, _mintAmount);
  }

  function setSale(bool newState) public onlyOwner {
    saleIsActive = newState;
  }

  function setPreSale(bool newState) public onlyOwner {
    presaleIsActive = newState;
  }

  function setProvenance(string memory provenance) public onlyOwner {
    PROVENANCE = provenance;
  }

  function setPublicCost(uint256 _newCost) public onlyOwner {
    publicCost = _newCost;
  }

  function setPreSaleCost(uint256 _newCost) public onlyOwner {
    presaleCost = _newCost;
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function setBaseURI(string memory baseURI_) external onlyOwner() {
    _baseURIextended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function withdraw() public onlyOwner {
      uint256 balance = address(this).balance;
      Address.sendValue(creatorAddress, balance.mul(50).div(100));
      Address.sendValue(marketingAddress, balance.mul(25).div(100));
      Address.sendValue(devAddress, balance.mul(25).div(100));
  }

}
