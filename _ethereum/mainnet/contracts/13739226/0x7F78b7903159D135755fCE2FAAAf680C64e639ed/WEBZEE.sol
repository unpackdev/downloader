//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract WEBZEE is ERC721Enumerable, Ownable{
  using Strings for uint256;
  string public constant BASE_TOKEN_URI = "https://webzee.co/tokenData?";

  event Mint(address to, uint256 tokenId);

  constructor() ERC721("WEBZEE", "WBZ")  {

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

    for(uint i = 0; i < _count; i++){
      uint256 newTokenId = totalSupply();
      _safeMint(_to, newTokenId);

      // Emit mint event
      emit Mint(_to, newTokenId);
    }
  }

  /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return string(abi.encodePacked(BASE_TOKEN_URI, "id=", tokenId.toString()));
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function burn(uint256 tokenId) public onlyOwner {
    super._burn(tokenId);
  }

  function withdrawAll() public payable onlyOwner {
    require(payable(_msgSender()).send(address(this).balance));
  }
}
