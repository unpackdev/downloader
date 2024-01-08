// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./nf-token.sol";
import "./erc721-metadata.sol";
import "./Strings.sol";

/**
 * @dev Optional metadata implementation for ERC-721 non-fungible token standard.
 */
contract NFTokenMetadata is
  NFToken,
  ERC721Metadata
{

  using Strings for uint256;

  /**
   * @dev A descriptive name for a collection of NFTs.
   */
  string internal nftName;

  /**
   * @dev An abbreviated name for NFTokens.
   */
  string internal nftSymbol;

  /**
   * @dev A prefix for all token uris.
   */
  string internal nftBaseUri;

  /**
   * @notice When implementing this contract don't forget to set nftName and nftSymbol.
   * @dev Contract constructor.
   */
  constructor()
  {
    supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
  }

  /**
   * @dev Returns a descriptive name for a collection of NFTokens.
   * @return _name Representing name.
   */
  function name()
    external
    override
    view
    returns (string memory _name)
  {
    _name = nftName;
  }

  /**
   * @dev Returns an abbreviated name for NFTokens.
   * @return _symbol Representing symbol.
   */
  function symbol()
    external
    override
    view
    returns (string memory _symbol)
  {
    _symbol = nftSymbol;
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   * @return _baseUri Representing baseUri.
   */
  function baseUri()
    external
    view
    returns (string memory _baseUri)
  {
    _baseUri = nftBaseUri;
  }

  /**
   * @dev A distinct URI (RFC 3986) for a given NFT.
   * @param _tokenId Id for which we want uri.
   * @return URI of _tokenId.
   */
  function tokenURI(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (string memory)
  {
    string memory baseURI = nftBaseUri;
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
  }

  /**
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @dev Burns a NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._burn(_tokenId);
  }

  /**
   * @notice This is an internal function which should be called from user-implemented external
   * function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @dev Set a new URI base.
   * @param _baseUri String representing the new URI base.
   */
  function _setBaseUri(
    string memory _baseUri
  )
    internal
  {
    nftBaseUri = _baseUri;
  }

}
