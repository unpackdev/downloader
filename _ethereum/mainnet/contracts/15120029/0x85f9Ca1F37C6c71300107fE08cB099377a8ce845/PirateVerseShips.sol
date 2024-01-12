// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Base64.sol";
import "./IERC2981.sol";

contract PirateVerseShips is ERC721, IERC2981, Ownable, ReentrancyGuard {
  using Strings for uint256;

  uint256 constant MAX_SUPPLY = 10000;

  uint256 private _currentId;

  string private baseURI;
  string private prerevealTokenURI;
  string public contractURI;

  bool public revealed = false;
  bool public paused = false;

  uint256 public tokensPerMint = 5;
  uint256 public maxPerWallet = 10;
  uint256 public price = 0.18 ether;

  uint256 public royaltiesBps = 250;
  string public baseExtension = ".json";

  mapping(address => uint256) private _alreadyMinted;

  address private beneficiaryAddress;

  constructor(
    address _beneficiaryAddress,
    
    string memory _initialContractURI,
    string memory _initialBaseURI,
    string memory _initialPrerevealTokenURI
  ) ERC721("PirateVerseShips", "SHIPS") ReentrancyGuard(){
    setBeneficiaryAddress(_beneficiaryAddress);
    setContractURI(_initialContractURI);
    setBaseURI(_initialBaseURI);
    setPrerevealTokenURI(_initialPrerevealTokenURI);
  }

  // Accessors

  function setBeneficiaryAddress(address _beneficiaryAddress) public onlyOwner {
    beneficiaryAddress = _beneficiaryAddress;
  }

  function setContractURI(string memory uri) public onlyOwner {
    contractURI = uri;
  }

  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  function setPrerevealTokenURI(string memory uri) public onlyOwner {
    prerevealTokenURI = uri;
  }

  function alreadyMinted(address addr) public view returns (uint256) {
    return _alreadyMinted[addr];
  }

  function totalSupply() public view returns (uint256) {
    return _currentId;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _prerevealToken() internal view returns (string memory) {
    return prerevealTokenURI;
  }

  function _contractURI() internal view returns (string memory) {
    return contractURI;
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function togglePause() public onlyOwner {
        paused = !paused;
    }

  // Minting 

  function mint(
    uint256 amount
  ) public payable {
    address sender = msg.sender;
    require(!paused, "Public Minting is closed");
    require(amount <= tokensPerMint, "Amount exceeds token per mint");
    require(_currentId + amount <= MAX_SUPPLY, "Amount exceeding maximum supply");
    require(amount <= maxPerWallet - _alreadyMinted[sender], "Insufficient mints left");
    require(msg.value >= amount * price, "Incorrect payable amount");

    _mintTokens(sender, amount);
    _alreadyMinted[sender] += amount;
  }

  // Private (Internal Minting Function)

  function _mintTokens(address to, uint256 amount) private nonReentrant{
    for (uint256 i = 0; i < amount; i++) {
      _currentId++;
      _safeMint(to, _currentId);
    }
  }

  // returns URI

  function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        if (revealed == false) {
            return prerevealTokenURI;
        }

        string memory currentBaseURI = _baseURI();
    
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

  // Withdraw

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{
        value: address(this).balance
      }("");
    require(success);
  }

  // ERC165

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  // IERC2981 (royalty)

  function royaltyInfo(uint256 , uint256 _salePrice) external view override returns (address, uint256 royaltyAmount) {
    royaltyAmount = (_salePrice / 10000) * royaltiesBps;
    return (beneficiaryAddress, royaltyAmount);
  }

  function reserveShips(uint256 amount) public onlyOwner {     
    address sender = msg.sender;   
    _mintTokens(sender, amount);
  }
}