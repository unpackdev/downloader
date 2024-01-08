// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/****************************************
 * @author: @antontheswan1                 *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./ERC721EnumerableB.sol";
import "./Delegated.sol";
import "./token-types.sol";
import "./Strings.sol";

contract FXC is Delegated, ERC721EnumerableB {
  using Strings for uint;

  string private _baseTokenURI = '';
  string private _tokenURISuffix = '';

  mapping(uint => TOKEN_TYPES) tokenTypeMap;

  constructor() ERC721B( "Foxxies X Catharsis", "FXC", 0 ) {}

  //external
  function burn(uint256 tokenId) external {
    require(_msgSender() == ownerOf(tokenId), "only owner allowed to burn");
    _burn(tokenId);
  }

  function getTokensByOwner(address owner) external view returns(uint256[] memory) {
    return _walletOfOwner(owner);
  }

  function walletOfOwner(address owner) external view returns(uint256[] memory) {
    return _walletOfOwner( owner );
  }

  //external payable
  fallback() external payable {}
  receive() external payable {}

  //onlyDelegates
  function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix) external onlyDelegates {
    _baseTokenURI = _newBaseURI;
    _tokenURISuffix = _newSuffix;
  }

  function mint( address to, TOKEN_TYPES tokenType ) external onlyDelegates {
      uint tokenId = next();
      tokenTypeMap[tokenId] = tokenType;
      _safeMint( to, tokenId, "" );
  }

  //public
  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    TOKEN_TYPES tokenType = tokenTypeMap[tokenId];

    return string(abi.encodePacked(_baseTokenURI, uint(tokenType).toString(), '/', tokenId.toString(), _tokenURISuffix));
  }

  //private
  function _walletOfOwner(address owner) private view returns(uint256[] memory) {
    uint256 balance = balanceOf(owner);
    uint256[] memory tokenIds = new uint256[](balance);
    for(uint256 i; i < balance; i++){
      tokenIds[i] = tokenOfOwnerByIndex(owner, i);
    }
    return tokenIds;
  }
}