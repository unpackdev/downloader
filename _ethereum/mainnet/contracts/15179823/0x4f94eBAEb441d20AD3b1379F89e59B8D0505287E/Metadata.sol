// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./base64.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SVG.sol";
import "./SVGUtils.sol";
import "./SVGColor.sol";
import "./ISource.sol";
import "./ICitizenAlpha.sol";
import "./SourceENS.sol";
import "./CitizenAlpha.sol";
import "./SVGRender.sol";

/**
 * @title Metadata
 * @author Kames Geraghty
 * @notice CitizenAlpha metadata resolver.
 */
contract Metadata is Ownable {
  using Strings for uint256;

  /// @notice Token instance
  address private _token;

  /// @notice SVGRender instance
  address private _svgRender;

  /// @notice ISources[] list
  address[] private _sources;

  struct Metadata {
    string name;
    string description;
    string avatar;
    string did;
    string ensAlias;
    string ensNode;
    string ensResolver;
    string traits;
  }

  struct ExternalMetadata {
    string avatar;
    string did;
    string ensNode;
    string ensAlias;
    string ensResolver;
    string traits;
  }

  constructor(address _svgRender_) {
    _svgRender = _svgRender_;
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  /**
   * @notice Get Token instance
   * @return token Token
   */
  function getToken() external view returns (address token) {
    return _token;
  }

  /**
   * @notice Get Token instance
   * @return token Token
   */
  function getSVGRender() external view returns (address token) {
    return _svgRender;
  }

  function getSourceData(uint256 idx, address user)
    external
    view
    returns (string[] memory, string[] memory)
  {
    return _getSourceData(idx, user);
  }

  function getSourcesData(address user) external view returns (string[] memory, string[] memory) {
    return _getSourcesData(user);
  }

  /**
   * @notice Construct tokenURI
   * @param tokenId address
   * @return uri string - Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory) {
    return _constructTokenURI(tokenId);
  }

  /**
   * @notice Construct resolver tokenURI
   * @param tokenId address
   * @return uri string - Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURIResolver(uint256 tokenId) external view returns (string memory) {
    return _constructTokenURIResolver(tokenId);
  }

  /**
   * @notice Get User Metadata
   * @param user address
   * @return metadata Metadata
   */
  function getMetadata(address user) external view returns (Metadata memory) {
    return _constructMetadata(user, CitizenAlpha(_token).getId(user));
  }

  /**
   * @notice Get User Avatar
   * @param user address
   * @return avatar string
   */
  function getAvatar(address user) external view returns (string memory) {
    uint256 _tokenId = ICitizenAlpha(_token).getId(user);
    SourceENS _resolverEns = SourceENS(_sources[0]);
    (, string memory alias_, ) = _resolverEns.getMetadata(user);
    string memory avatar_ = _resolverEns.getValue(user, "avatar");
    return _generateAvatar(avatar_, _tokenId, alias_);
  }

  /**
   * @notice Get User Image
   * @param user address
   * @return avatar string
   */
  function getImage(address user) external view returns (string memory) {
    uint256 _tokenId = ICitizenAlpha(_token).getId(user);
    SourceENS _resolverEns = SourceENS(_sources[0]);
    (, string memory alias_, ) = _resolverEns.getMetadata(user);
    return _generateImage(_tokenId, alias_);
  }

  /**
   * @notice Append Source instance
   * @param source address
   */
  function appendSource(address source) external onlyOwner {
    _sources.push(source);
  }

  /**
   * @notice Set Source instance
   * @param idx uint256
   * @param source address
   */
  function updateSource(uint256 idx, address source) external onlyOwner {
    require(idx < _sources.length - 1, "Metadata:invalid-index");
    _sources[idx] = source;
  }

  /**
   * @notice Set Token instance
   * @param token_ address
   */
  function setToken(address token_) external onlyOwner {
    _token = token_;
  }

  /**
   * @notice Set SVGRender instance
   * @param svgRender_ address
   */
  function setSVGRender(address svgRender_) external onlyOwner {
    _svgRender = svgRender_;
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _constructTokenURI(uint256 _tokenId) internal view returns (string memory) {
    ICitizenAlpha token_ = ICitizenAlpha(_token);
    Metadata memory _meta = _constructMetadata(token_.ownerOf(_tokenId), _tokenId);

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              string.concat(
                '{"name":',
                '"',
                _meta.name,
                '",',
                '"description":',
                '"',
                _meta.description,
                '",',
                '"image":',
                '"',
                _meta.avatar,
                '",',
                '"attributes": [',
                _meta.traits,
                "]",
                "}"
              )
            )
          )
        )
      );
  }

  function _constructTokenURIResolver(uint256 _tokenId) internal view returns (string memory) {
    ICitizenAlpha token_ = ICitizenAlpha(_token);
    address owner_ = token_.ownerOf(_tokenId);
    ExternalMetadata memory externalMetadata_ = _getExternalMetadata(owner_, _tokenId);
    string memory name_ = string(abi.encodePacked("Citizen #", _tokenId.toString()));
    string memory description_ = bytes(externalMetadata_.ensAlias).length > 0
      ? externalMetadata_.ensAlias
      : Strings.toHexString(uint256(uint160(owner_)), 20);
    string memory avatar_ = _generateImage(_tokenId, externalMetadata_.ensAlias);
    address link_ = ICitizenAlpha(_token).getLink(owner_);
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              string.concat(
                '{"name":',
                '"',
                name_,
                '",',
                '"description":',
                '"',
                description_,
                '",',
                '"image":',
                '"',
                avatar_,
                '",',
                '"attributes": [',
                _generateTrait("link", Strings.toHexString(uint256(uint160(link_)), 20)),
                "]",
                "}"
              )
            )
          )
        )
      );
  }

  function _constructMetadata(address user, uint256 tokenId)
    internal
    view
    returns (Metadata memory)
  {
    ExternalMetadata memory externalMetadata_ = _getExternalMetadata(user, tokenId);
    string memory name_ = string(abi.encodePacked("Citizen #", tokenId.toString()));
    string memory description_ = bytes(externalMetadata_.ensAlias).length > 0
      ? externalMetadata_.ensAlias
      : Strings.toHexString(uint256(uint160(user)), 20);
    address link_ = ICitizenAlpha(_token).getLink(user);

    Metadata memory _meta = Metadata({
      name: name_,
      description: description_,
      avatar: externalMetadata_.avatar,
      did: externalMetadata_.did,
      ensNode: externalMetadata_.ensNode,
      ensAlias: externalMetadata_.ensAlias,
      ensResolver: externalMetadata_.ensResolver,
      traits: string.concat(
        externalMetadata_.traits,
        _generateTrait("link", Strings.toHexString(uint256(uint160(link_)), 20))
      )
    });

    return _meta;
  }

  function _getExternalMetadata(address user, uint256 _tokenId)
    internal
    view
    returns (ExternalMetadata memory)
  {
    /// @dev ENS resolver must always be in the first slot. TODO: make better
    SourceENS _resolverEns = SourceENS(_sources[0]);
    string memory did_ = _resolverEns.getValue(user, "did");
    string memory avatar_ = _resolverEns.getValue(user, "avatar");
    (bytes32 node, string memory alias_, address resolver_) = _resolverEns.getMetadata(user);
    string memory traits_ = _getUnwrappedTraits(user);
    return
      ExternalMetadata({
        avatar: _generateAvatar(avatar_, _tokenId, alias_),
        did: did_,
        ensNode: string(abi.encodePacked(node)),
        ensAlias: string(alias_),
        ensResolver: resolver_ != 0x0000000000000000000000000000000000000000
          ? Strings.toHexString(uint256(uint160(resolver_)), 20)
          : "",
        traits: traits_
      });
  }

  function _getExternalAvatar(address user, uint256 _tokenId)
    internal
    view
    returns (string memory)
  {
    /// @dev ENS PublicResolver must be in first slot. TODO: make better in V2
    SourceENS _resolverEns = SourceENS(_sources[0]);
    string memory avatar_ = _resolverEns.getValue(user, "avatar");
    (, string memory alias_, ) = _resolverEns.getMetadata(user);
    return _generateAvatar(avatar_, _tokenId, alias_);
  }

  function _getUnwrappedTraits(address user) internal view returns (string memory) {
    (string[] memory keys_, string[] memory values_) = _getSourcesData(user);
    return _generateTraits(keys_, values_);
  }

  function _getSourceData(uint256 _sourceIndex, address _user)
    internal
    view
    returns (string[] memory, string[] memory)
  {
    ISource _source = ISource(_sources[_sourceIndex]);
    uint256 count = _source.count(_user);

    string[] memory keys_ = new string[](count);
    string[] memory values_ = new string[](count);

    (string[] memory keys__, string[] memory values__) = _source.getData(_user);

    for (uint256 k = 0; k < count; k++) {
      keys_[k] = (keys__[k]);
      values_[k] = values__[k];
    }

    return (keys_, values_);
  }

  function _getSourcesData(address _user) internal view returns (string[] memory, string[] memory) {
    uint256 count = 0;
    address[] memory __sources = _sources;
    for (uint256 i = 0; i < __sources.length; i++) {
      ISource _source = ISource(__sources[i]);
      count = count + _source.count(_user);
    }

    string[] memory keys_ = new string[](count);
    string[] memory values_ = new string[](count);

    uint256 __start;
    for (uint256 i = 0; i < __sources.length; i++) {
      ISource _source = ISource(__sources[i]);
      (string[] memory keys__, string[] memory values__) = _source.getData(_user);
      for (uint256 k = __start; k < count; k++) {
        keys_[k] = (keys__[k]);
        values_[k] = values__[k];
      }
    }

    return (keys_, values_);
  }

  /* ===================================================================================== */
  /* Traits Functions                                                                      */
  /* ===================================================================================== */

  function _appendTrait(string memory _traits, string memory _traitAppending)
    internal
    pure
    returns (string memory)
  {
    return string.concat(_traits, bytes(_traits).length > 0 ? "," : "", _traitAppending);
  }

  function _generateTrait(string memory _key, string memory _value)
    internal
    pure
    returns (string memory __traits)
  {
    return string.concat('{"trait_type":' '"', _key, '",', '"value":', '"', _value, '"}');
  }

  function _generateTraits(string[] memory _keys, string[] memory _values)
    internal
    pure
    returns (string memory __traits)
  {
    string memory _traits = "";
    for (uint256 i = 0; i < _keys.length; i++) {
      if (bytes(_values[i]).length > 0) {
        _traits = string.concat(_traits, _generateTrait(_keys[i], _values[i]), ",");
      }
    }
    return _traits;
  }

  function _generateAvatar(
    string memory _avatar,
    uint256 tokenId,
    string memory alias_
  ) internal view returns (string memory) {
    if (bytes(_avatar).length == 0) {
      return
        string(
          abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(SVGRender(_svgRender).generate(tokenId, alias_)))
          )
        );
    }
    return _avatar;
  }

  function _generateImage(uint256 tokenId, string memory alias_)
    internal
    view
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          "data:image/svg+xml;base64,",
          Base64.encode(bytes(SVGRender(_svgRender).generate(tokenId, alias_)))
        )
      );
  }
}
