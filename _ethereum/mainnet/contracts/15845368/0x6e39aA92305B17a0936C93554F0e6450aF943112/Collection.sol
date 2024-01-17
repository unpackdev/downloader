// SPDX-License-Identifier: ISC

pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract Collection is ERC721Enumerable, Ownable {
  using Strings for uint;

  string public baseURI;

  mapping(uint => string) private tokenIdToTokenURI;

  /**
   * @notice Constructor
   * @param _name Name of the token
   * @param _symbol Symbol of the token
   */
  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

  /**
   * @notice Set prefix of all tokenURI
   * @param _baseURI prefix of all tokenURI
   * @dev only owner can call this function
   */
  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  /**
   * @notice Mint a new NFT to the specified address
   * @param _to address to mint NFT
   * @param _tokenURI tokenURI to assign to tokenID
   */
  function mint(address _to, string memory _tokenURI) public onlyOwner {
    require(bytes(_tokenURI).length > 0, "Collection: tokenURI not valid");

    uint tokenID = totalSupply();
    _safeMint(_to, tokenID);
    tokenIdToTokenURI[tokenID] = _tokenURI;
  }

  /**
   * @notice Mint batch a new NFT to the list of specified address
   * @param _to list of address to mint NFT
   * @param _tokenURI list of tokenURI to assign to tokenID
   */
  function mintBatch(address[] memory _to, string[] memory _tokenURI) public onlyOwner {

    for ( uint i = 0; i < _to.length; i++) {
      require(bytes(_tokenURI[i]).length > 0, "Collection: tokenURI not valid");

      uint tokenID = totalSupply();
      _safeMint(_to[i], tokenID, "");
      tokenIdToTokenURI[tokenID] = _tokenURI[i];
    }
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   * @param _tokenID id of the token to retrieve
   * This function concatenates the base uri with the token uri set during mint
  */
  function tokenURI(uint _tokenID) public view virtual override returns (string memory) {
    require(_exists(_tokenID), "Collection: tokenID not exist");

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenIdToTokenURI[_tokenID])) : "";
  }
}
