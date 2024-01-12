// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./base64.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./SVG.sol";
import "./SVGUtils.sol";
import "./SVGColor.sol";
import "./CitizenAlpha.sol";
import "./ENS.sol";
import "./NameEncoder.sol";
import "./IReverseRegistrar.sol";
import "./ITextResolver.sol";
import "./IDefaultReverseResolver.sol";

contract CitizenAlphaMetadata is Ownable {
  using NameEncoder for string;
  using Strings for address;
  using Strings for uint256;
  using Strings for uint8;

  CitizenAlpha private token;
  SVGColor public svgColor;
  address private ens = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
  address private resolver = 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41;
  address private reverseRegistrar = 0x084b1c3C81545d370f3634392De611CaaBFf8148;
  address private defaultReverseResolver = 0xA2C122BE93b0074270ebeE7f6b7292C7deB45047;

  string[] private traitKeys;

  constructor(SVGColor _svgColor) public {
    svgColor = _svgColor;
    traitKeys.push("avatar");
    traitKeys.push("url");
    traitKeys.push("description");
    traitKeys.push("com.github");
    traitKeys.push("com.twitter");
    traitKeys.push("org.telegram");
    traitKeys.push("did");
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    return _constructTokenURI(tokenId);
  }

  function setToken(CitizenAlpha _token) external onlyOwner {
    token = _token;
  }

  function pushTraitField(string calldata _key) external onlyOwner {
    traitKeys.push(_key);
  }

  function setTraitField(uint256 _index, string calldata _key) external onlyOwner {
    traitKeys[_index] = _key;
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _constructTokenURI(uint256 _tokenId) internal view returns (string memory) {
    address citizen_ = token.ownerOf(_tokenId);
    (string memory alias_, bytes32 node_, ITextResolver res_) = _resolveOwner(citizen_);
    string memory name_ = string(abi.encodePacked("Citizen #", _tokenId.toString()));
    string memory description_ = bytes(alias_).length > 0
      ? alias_
      : Strings.toHexString(uint256(uint160(citizen_)), 20);
    string memory avatar_ = _generateImage(res_.text(node_, "avatar"), _tokenId, alias_);
    (string[] memory keys_, string[] memory values_) = _fetchNodeTextFields(traitKeys, node_, res_);
    address link_ = token.getLink(citizen_);
    bool isFounder_ = token.isFounder(citizen_);
    string memory traits_ = _generateTraits(keys_, values_);

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
                string.concat(
                  traits_,
                  _generateTrait("isFounder", isFounder_ ? "true" : "false"),
                  ",",
                  _generateTrait("link", Strings.toHexString(uint256(uint160(link_)), 20))
                ),
                "]",
                "}"
              )
            )
          )
        )
      );
  }

  function _appendTrait(string memory _traits, string memory _traitAppending)
    internal
    view
    returns (string memory)
  {
    return string.concat(_traits, bytes(_traits).length > 0 ? "," : "", _traitAppending);
  }

  function _generateImage(
    string memory _avatar,
    uint256 tokenId,
    string memory alias_
  ) internal view returns (string memory) {
    if (bytes(_avatar).length == 0) {
      return
        string(
          abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(_generate(tokenId, alias_)))
          )
        );
    }
    return _avatar;
  }

  function _generateTrait(string memory _key, string memory _value)
    internal
    view
    returns (string memory __traits)
  {
    return string.concat('{"trait_type":' '"', _key, '",', '"value":', '"', _value, '"}');
  }

  function _generateTraits(string[] memory _keys, string[] memory _values)
    internal
    view
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

  function _resolveOwner(address owner_)
    internal
    view
    returns (
      string memory,
      bytes32,
      ITextResolver
    )
  {
    bytes32 node_ = IReverseRegistrar(reverseRegistrar).node(owner_);
    string memory _name = IDefaultReverseResolver(defaultReverseResolver).name(node_);
    (, bytes32 _node) = _name.dnsEncodeName();
    ITextResolver _resolver = ITextResolver(resolver);
    return (_name, _node, _resolver);
  }

  function _fetchNodeTextFields(
    string[] memory _traits,
    bytes32 _node,
    ITextResolver _resolver
  ) internal view returns (string[] memory keys_, string[] memory values_) {
    string[] memory __keys = new string[](_traits.length);
    string[] memory __values = new string[](_traits.length);
    for (uint256 i = 0; i < _traits.length; i++) {
      __keys[i] = _traits[i];
      __values[i] = _resolver.text(_node, _traits[i]);
    }
    return (__keys, __values);
  }

  function _generate(uint256 _tokenId, string memory _alias) internal view returns (string memory) {
    string memory _bgDef = svgUtils.getDefURL("charcoal");

    return
      string(
        abi.encodePacked(
          svg.start(),
          _getDefs(),
          svg.rect(
            string.concat(
              svg.prop("fill", _bgDef),
              svg.prop("x", "0"),
              svg.prop("y", "0"),
              svg.prop("width", "100%"),
              svg.prop("height", "100%")
            ),
            svgUtils.NULL
          ),
          svg.text(
            string.concat(
              svg.prop("x", "50%"),
              svg.prop("y", "50%"),
              svg.prop("dominant-baseline", "middle"),
              svg.prop("text-anchor", "middle"),
              svg.prop("font-size", "48px"),
              svg.prop("fill", "white")
            ),
            string.concat("CIV #", _tokenId.toString())
          ),
          svg.text(
            string.concat(
              svg.prop("x", "50%"),
              svg.prop("y", "60%"),
              svg.prop("dominant-baseline", "middle"),
              svg.prop("text-anchor", "middle"),
              svg.prop("font-size", "22px"),
              svg.prop("fill", "white")
            ),
            _alias
          ),
          svg.end()
        )
      );
  }

  function _getDefs() internal view returns (string memory) {
    return
      svg.defs(
        string.concat(
          svg.linearGradient(
            string.concat(svg.prop("id", "charcoal"), svg.prop("gradientTransform", "rotate(140)")),
            string.concat(
              svg.stop(
                string.concat(
                  svg.prop("offset", "0%"),
                  svg.prop("stop-color", svgColor.getRgba("Dark1"))
                )
              ),
              svg.stop(
                string.concat(
                  svg.prop("offset", "70%"),
                  svg.prop("stop-color", svgColor.getRgba("Dark2"))
                )
              )
            )
          )
        )
      );
  }
}
