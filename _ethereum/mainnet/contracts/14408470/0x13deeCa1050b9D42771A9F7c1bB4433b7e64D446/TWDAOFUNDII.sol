// SPDX-License-Identifier: MIT
/*  
    TWDAO_FUND_II /2022 
*/

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";


contract TWDAOFUNDII is ERC721, ERC721Enumerable, Ownable {
    
  using SafeMath for uint256;
  using Strings for uint256;

  uint256 public constant MAX_SUPPLY = 1000;
  uint256 public constant PRICE = 1 ether;
  uint256 public offsetIndex = 0;
  uint256 public publicStartTime;

  string private _baseURIExtended;
  
  address private s1 = 0x0B30da447C22244ce72c6bDEc1A31F0D9Ac1e147;

  bool private _isPublicSaleActive = false;

  modifier onlyRealUser() {
    require(msg.sender == tx.origin, "Oops. Something went wrong !");
    _;
  }

  event PublicSale_Started();
  event PublicSale_Stopped();
  event TokenMinted(uint256 supply);

  constructor() ERC721('TWDAOFUNDII', 'TWDFII') { }

  function withdraw() public onlyOwner {
    require(payable(s1).send(address(this).balance), "Send Failed");
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

  function mint_public(uint8 NUM_TOKENS_MINT) public payable onlyRealUser {
    require(_isPublicSaleActive, "Sales is not active");
    require(block.timestamp >= publicStartTime,"Sales is not active");
    require(totalSupply().add(NUM_TOKENS_MINT) <= 1000, "Exceeding max supply");
    require(NUM_TOKENS_MINT <= 20, "You can not mint over 20 at a time");
    require(NUM_TOKENS_MINT > 0, "At least one should be minted");
    require(PRICE*NUM_TOKENS_MINT <= msg.value, "Not enough ether sent");
    _mint(NUM_TOKENS_MINT, msg.sender);
    emit TokenMinted(totalSupply());
  }

  function startPublicSale() public onlyOwner {
    _isPublicSaleActive = true;
    emit PublicSale_Started();
  }

  function pausePublicSale() public onlyOwner {
    _isPublicSaleActive = false;
    emit PublicSale_Stopped();
  }

  function isPublicSaleActive() public view returns (bool) {
    return _isPublicSaleActive;
  }
  function _mint(uint256 num, address recipient) internal {
    uint256 supply = totalSupply();
    for (uint256 i = 1; i <= num; i++) {
      _safeMint(recipient, supply + i);
    }
  }

  function setpublicStartTime(uint256 _publicStartTime) public onlyOwner {
    publicStartTime = _publicStartTime;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    _baseURIExtended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIExtended;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
      if (tokenId < MAX_SUPPLY+1) {
        uint256 offsetId = tokenId.add(MAX_SUPPLY.sub(offsetIndex)).mod(MAX_SUPPLY);
        if (offsetId == 0 ) {
          offsetId = 1000;
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