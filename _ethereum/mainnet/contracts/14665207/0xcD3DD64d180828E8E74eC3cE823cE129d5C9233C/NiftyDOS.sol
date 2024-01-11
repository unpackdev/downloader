//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";

contract NiftyDOS is ERC721ABurnable, Ownable{
  using Strings for uint256;
  string public constant BASE_TOKEN_URI = "http://niftydos.com/token?";

  event Mint(address to, uint256 tokenId);

  constructor() ERC721A("NiftyDOS", "NDOS")  {

  }

  function mintTokens(address _to, uint _count, uint _maxSupply, uint _maxPerMint, uint _maxMint, uint _price, bool _canMint, uint8 v, bytes32 r, bytes32 s) external payable {
    require(totalSupply() + _count <= _maxSupply, "Max supply reached");
    require(_canMint, "This user is not allowed to mint");
    require(balanceOf(_to) + _count <= _maxMint, "Max mint reached");
    require(_count <= _maxPerMint, "Max per mint reached");
    // Check the price
    require(msg.value >= _count * _price, "Sent value below price");

    require(
      ecrecover(keccak256(
          abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(_to, _maxSupply, _maxPerMint, _maxMint, _price, _canMint))
          )), v, r, s) == owner(), "Unable to verify signature");

    _safeMint(_to, _count);
  }

  /**
     * @dev See {IERC721-isApprovedForAll}.
  */
  function isApprovedForAll(address _owner, address operator) public view virtual override returns (bool) {
    // owner can move any of the token
    if (operator == owner()) {
      return true;
    }
    return super.isApprovedForAll(_owner, operator);
  }

  /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return string(abi.encodePacked(BASE_TOKEN_URI, "id=", tokenId.toString()));
  }

  function withdrawAll() public payable onlyOwner {
    require(payable(_msgSender()).send(address(this).balance));
  }
}
