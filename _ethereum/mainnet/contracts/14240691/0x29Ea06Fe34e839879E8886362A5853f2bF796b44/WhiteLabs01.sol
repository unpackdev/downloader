// SPDX-License-Identifier: MIT
/*  
    WHITE LABS / 2022 
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";


contract WhiteLabs01 is ERC721, ERC721Enumerable, Ownable {
    
  using SafeMath for uint256;
  using Strings for uint256;

  uint256 public constant MAX_SUPPLY = 105;
  uint256 public offsetIndex = 0;

  string private _baseURIExtended;
  
  address private s1 = 0xFD22d35cf24eF9955B367eFA23147f06A2cBCae0;

  modifier onlyRealUser() {
    require(msg.sender == tx.origin, "Oops. Something went wrong !");
    _;
  }
  
  event TokenMinted(uint256 supply);

  constructor() ERC721('WhiteLabs01', 'WLS01') { }

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

  function _mint(uint256 num, address recipient) internal {
    uint256 supply = totalSupply();
    for (uint256 i = 1; i <= num; i++) {
      _safeMint(recipient, supply + i);
    }
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
          offsetId = 105;
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