// SPDX-License-Identifier: MIT

/*   
 ██████╗██████████╗   ████████╗██████████╗██████╗█████╗███████████████╗
██╔════╝██╔════████╗  ████╔══████╚══██╔══██╔════██╔══██╚══██╔══██╔════╝
██║  ████████╗ ██╔██╗ ████████╔██║  ██║  ██║    ███████║  ██║  ███████╗
██║   ████╔══╝ ██║╚██╗████╔══████║  ██║  ██║    ██╔══██║  ██║  ╚════██║
╚██████╔█████████║ ╚██████████╔██║  ██║  ╚████████║  ██║  ██║  ███████║
 ╚═════╝╚══════╚═╝  ╚═══╚═════╝╚═╝  ╚═╝   ╚═════╚═╝  ╚═╝  ╚═╝  ╚══════╝
 
*/

pragma solidity 0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";

contract GenBitCats is ERC721, Ownable, PaymentSplitter { 
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  address[] private _team = [
    0x68565FDC8De0437aF593D6cD78d0c5397A94C75f,
    0x3C389a52CE6f9e570B3a93de37A160D5D90319a8,
    0x06264A2eFb48d936E86cB4CD0d010716b19AFEee,
    0x5D52F6632B1a9D743A5290dc26a3f831f09Db6A0 
    ];
  uint[] private _teamShares = [
    40,
    26,
    17,
    17
    ];

  uint public constant maxSupply = 1024;
  uint public constant maxMintsPerTransaction = 2;
  uint public constant maxMintsPerAddress = 2;
  uint public constant maxMintWhitelist = 1;
  uint public constant maxMintOgBitCatHolder = 2;
  uint public constant reservedAmount = 32; 
  uint public constant price = 0.04 ether;
  uint public reservedMintedAlready; 

  bool public presaleOpen = false;
  bool public saleOpen = false;
  bool public revealed = false;

  mapping(address => bool) public whitelisted;
  mapping(address => bool) public ogBitCatHolder;
  mapping(address => uint256) public whitelistFree;
  mapping(address => uint256) public ogBitCatHolderFree;
  mapping(address => uint256) public whitelistPaid;
  mapping(address => uint256) public ogBitCatHolderPaid;
  mapping(address => uint256) public tokensMintedDuringPublicSale;

  string public BaseURI = "https://onchain.mypinata.cloud/ipfs//" ;
  string public baseExtension  = "";
  string public hiddenTokenURI = "https://onchain.mypinata.cloud/ipfs/QmVPNiRbzM9Sp7QVDjVvurmHkRFs1h5cvJ6wakEVE6wW96";

  event Minted(address to, uint tokenId);

  constructor() 
    ERC721("GenBitCats", "GBC") 
    PaymentSplitter(_team, _teamShares) {} 

  function addToWhitelist(address[] memory addresses) external onlyOwner {
    for(uint256 i = 0; i < addresses.length; i++) {
      whitelisted[addresses[i]] = true;
    }
  }

  function addToOgBitCatHolder(address[] memory addresses) external onlyOwner {
    for(uint256 i = 0; i < addresses.length; i++) {
      ogBitCatHolder[addresses[i]] = true;
    }
  }

  function getMaxMintableSupply() public view returns(uint){
    return maxSupply - (reservedAmount - reservedMintedAlready);
  }

  function mintWhitelistFree(uint amount) external {
    require(presaleOpen , "PreSale not started yet");
    require(whitelisted[msg.sender] , "not whitelisted");
    require(totalSupply() + amount <= getMaxMintableSupply(), "max supply reached");
    require(whitelistFree[msg.sender] + amount <= maxMintWhitelist, "minted already");
    whitelistFree[msg.sender] += amount;
    _mintGBC(msg.sender, amount);
  }

  function mintOgBitCatHolderFree(uint amount) external {
    require(presaleOpen , "PreSale not started yet");
    require(ogBitCatHolder[msg.sender] , "not whitelisted");
    require(totalSupply() + amount <= getMaxMintableSupply(), "max supply reached");
    require(ogBitCatHolderFree[msg.sender] + amount <= maxMintOgBitCatHolder, "minted already");
    ogBitCatHolderFree[msg.sender] += amount;
    _mintGBC(msg.sender, amount);
  }

  function mintWhitelistPaid(uint amount) external payable {
    require(presaleOpen , "PreSale not started yet");
    require(whitelisted[msg.sender], "not whitelisted");
    require(totalSupply() + amount <= getMaxMintableSupply(), "max supply reached");
    require(whitelistPaid[msg.sender] + amount <= maxMintWhitelist, "not enough whitelist balance");
    require(msg.value == price * amount, "sent incorrect price");
    whitelistPaid[msg.sender] += amount;
    _mintGBC(msg.sender, amount);
  }

 function mintOgBitCatHolderPaid(uint amount) external payable {
    require(presaleOpen , "PreSale not started yet");
    require(ogBitCatHolder[msg.sender], "not whitelisted");
    require(totalSupply() + amount <= getMaxMintableSupply(), "max supply reached");
    require(ogBitCatHolderPaid[msg.sender] + amount <= maxMintOgBitCatHolder, "not enough whitelist balance");
    require(msg.value == price * amount, "sent incorrect price");
    ogBitCatHolderPaid[msg.sender] += amount;
    _mintGBC(msg.sender, amount);
  }

  function mintReserved(address receiver, uint amount) external onlyOwner {
    require(totalSupply() + amount <= maxSupply, "max reached");
    require(reservedMintedAlready + amount <= reservedAmount, "reserved max reached");
    reservedMintedAlready += amount;
    _mintGBC(receiver, amount);
  }

  function mintSale(uint amount) external payable {
    require(msg.sender == tx.origin, "Only EOA");
    require(saleOpen , "Sale not started yet");
    require(amount > 0 && amount <= maxMintsPerTransaction, "amount out of bounds");
    require(totalSupply() + amount <= getMaxMintableSupply(), "max supply reached");
    require(tokensMintedDuringPublicSale[msg.sender] + amount <= maxMintsPerAddress, "maximum minted");
    require(msg.value == price * amount, "sent incorrect price");
    tokensMintedDuringPublicSale[msg.sender] += amount;
    _mintGBC(msg.sender, amount);
  }

  function _mintGBC(address to, uint amount) private {
    uint id;
    for(uint i = 0; i < amount; i++){
      _tokenIds.increment();
      id = _tokenIds.current();
      _mint(to, id);
      emit Minted(to, id);
    }
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    BaseURI = newBaseURI;
  }

  function setBaseExtension(string memory newBaseExtension) external onlyOwner {
    baseExtension = newBaseExtension;
  }

  function setHiddenTokenURI(string memory newHiddenTokenURI) external onlyOwner {
    hiddenTokenURI = newHiddenTokenURI;
  }

  function switchSaleState() external onlyOwner {
    saleOpen = !saleOpen;
  }

  function switchPresaleState() external onlyOwner {
    presaleOpen = !presaleOpen;
  }

  function switchRevealState() external onlyOwner {
    revealed = !revealed;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory _tokenURI = "Token with that ID does not exist.";
    if (_exists(tokenId)){
      if(!revealed){
        _tokenURI = hiddenTokenURI;
      }
      else{
      _tokenURI = string(abi.encodePacked(BaseURI, tokenId.toString(),  baseExtension));
      }
    }
    return _tokenURI;
  }
  
  function totalSupply() public view returns(uint){
    return _tokenIds.current();
  }

  function withdrawAll() external {
    for (uint256 i = 0; i < _team.length; i++) {
      release(payable(_team[i]));
    }
  }

}
