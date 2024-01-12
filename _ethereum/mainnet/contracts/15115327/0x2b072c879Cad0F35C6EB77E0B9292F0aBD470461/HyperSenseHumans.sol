// SPDX-License-Identifier: MIT
/*  
    Hyper Sense Humans /2022 
*/

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract HyperSenseHumans is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    
  using SafeMath for uint256;
  using Strings for uint256;
  
  mapping(address => bool) private _allowList; 
  mapping(address => bool) private _blackList;

  uint256 public constant MAX_SUPPLY = 8888;
  uint256 public offsetIndex = 0;
  uint256 public PRICE1 = .1 ether;
  uint256 public PRICE2 = .2 ether;
  uint256 public PRICE3 = .3 ether;
  
  bool private _isWhitelistActive = false;
  bool private _isDoubleWhiteActive = false;
  bool private _isPublicActive = false;

  address private s1 = 0x07E6550526b9117AD9070FA2a8249dF34E838613;
  address private s2 = 0x0C2f634fE28e181757002e45c1111bccb04c1917;

  string private _baseURIExtended;
  bytes32 public merkleRoot = 0x3b8f6fbc9ca6ba46271ae3f3871ee22a11850aab7b5687e43c2f04cb8a952bf8;

  modifier onlyRealUser() {
    require(msg.sender == tx.origin, "Invalid");
    _;
  }

  modifier onlyShareHolders() {
    require(msg.sender == s1 || msg.sender == s2 );
    _;
  }

  event TokenMinted(uint256 supply);

  constructor() ERC721('HyperSenseHumans', 'HSH') {}

  function withdraw() public onlyShareHolders {
    uint256 _each = address(this).balance / 2;
    require(payable(s1).send(_each), "Send Failed");
    require(payable(s2).send(_each), "Send Failed");
  }
  
  function getTotalSupply() public view returns (uint256) {
    return totalSupply();
  }

  function getTokenByOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
  
  function reserve(uint256 num) public onlyOwner {
    require(totalSupply().add(num) <= MAX_SUPPLY, "Exceeding max supply");
    _mint(num, msg.sender);
    emit TokenMinted(totalSupply());
  }

  function airdrop(uint256 num, address recipient) public onlyOwner {
    require(totalSupply().add(num) <= MAX_SUPPLY, "Exceeding max supply");
    _mint(num, recipient);
    emit TokenMinted(totalSupply());
  }

  function airdropToMany(address[] memory recipients) external onlyOwner {
    require(totalSupply().add(recipients.length) <= MAX_SUPPLY, "Exceeding max supply");
    for (uint256 i = 0; i < recipients.length; i++) {
      airdrop(1, recipients[i]);
    }
  }

  function mint_doublewhite(uint8 NUM_TOKENS_MINT) public payable nonReentrant onlyRealUser {
    require(_isDoubleWhiteActive, "Sales is not active");
    require(totalSupply().add(NUM_TOKENS_MINT) <= 8888, "Exceeding max supply");
    require(_allowList[msg.sender], "You have already minted");
    require(NUM_TOKENS_MINT <= 3, "Invalid");
    require(NUM_TOKENS_MINT > 0, "Invalid");
    require(PRICE1*NUM_TOKENS_MINT <= msg.value, "Not enough ether sent");
    _allowList[msg.sender] = false ;
    _mint(NUM_TOKENS_MINT, msg.sender);
    emit TokenMinted(totalSupply());
  }

  function mint_whitelist (uint8 NUM_TOKENS_MINT, bytes32[] calldata _merkleProof) public payable nonReentrant onlyRealUser {
    require(_isWhitelistActive, "Sales is not active");
    require(totalSupply().add(NUM_TOKENS_MINT) <= 8888, "Exceeding max supply");
    require(_blackList[msg.sender] == false, "You have already minted"); 
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid");
    require(NUM_TOKENS_MINT <= 3, "Invalid");
    require(NUM_TOKENS_MINT > 0, "Invalid");
    require(PRICE2 * NUM_TOKENS_MINT <= msg.value, "Not enough ether sent");
    _blackList[msg.sender] = true;
    _mint(NUM_TOKENS_MINT, msg.sender);
    emit TokenMinted(totalSupply());
  }

  function mint_public (uint8 NUM_TOKENS_MINT) public payable nonReentrant onlyRealUser {
    require(_isPublicActive, "Sales is not active");
    require(totalSupply().add(NUM_TOKENS_MINT) <= 8888, "Exceeding max supply");
    require(NUM_TOKENS_MINT > 0, "Invalid");
    require(PRICE3 * NUM_TOKENS_MINT <= msg.value, "Not enough ether sent");
    _mint(NUM_TOKENS_MINT, msg.sender);
    emit TokenMinted(totalSupply());
  }

  function _mint(uint256 num, address recipient) internal {
    uint256 supply = totalSupply();
    for (uint256 i = 1; i <= num; i++) {
      _safeMint(recipient, supply + i);
    }
  }
   
   function setPrice3(uint256 price) public onlyOwner {
    PRICE3 = price;
  }

   function setMintWhitelist(bool action) public onlyOwner {
    _isWhitelistActive = action;
  }

   function setMintDoubleWhite(bool action) public onlyOwner {
    _isDoubleWhiteActive = action;
  }

   function setMintPublic(bool action) public onlyOwner {
    _isPublicActive = action;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    _baseURIExtended = baseURI_;
  }

  function addToAllowList(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _allowList[addresses[i]] = true;
    }
  }

  function removeFromAllowList(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _allowList[addresses[i]] = false;
    }
  }
  
  function onAllowList(address addr) external view returns (bool) {
    return _allowList[addr];
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIExtended;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
      if (tokenId < MAX_SUPPLY+1) {
        uint256 offsetId = tokenId.add(MAX_SUPPLY.sub(offsetIndex)).mod(MAX_SUPPLY);
        if (offsetId == 0 ) {
          offsetId = 8888;
        }
        return string(abi.encodePacked(_baseURI(), offsetId.toString(), ".json"));
      }  
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

}