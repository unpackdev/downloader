// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./Strings.sol";
import "./base64.sol";
import "./NFTSVG.sol";

contract OnChainMeta {
    using Strings for uint256;

    /// @dev A mask for isolating an item's group ID.
    uint256 private constant GROUP_MASK = uint256(type(uint128).max) << 128;

    string public metaDescription = 'You have to be a sea in order to absorb a dirty stream without getting dirty.';

    function _buildMeta(uint256 _tokenId, address _owner) internal view returns (string memory) {

      string memory imageDat = string(abi.encodePacked(
        '{"name":"',
           _buildName(_tokenId),
          '",',
          '"description":"',
             metaDescription,
          '",',
          '"image":"',
          'data:image/svg+xml;base64,',
            Base64.encode(bytes(_generateSVGImage(_tokenId, _owner))),
          '", "attributes":[',
             _getMetadata(_tokenId),
          ']',
        '}')
      );

      string memory image = string(abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(bytes(imageDat))
      ));

      return image;
    }

    function _buildName(uint256 _tokenId) internal view returns (string memory) {
      uint256 groupId = (_tokenId & GROUP_MASK) >> 128;
      uint256 id = _tokenId << 128 >> 128;
      return string(abi.encodePacked("SEAGLASS #", id.toString()));
    }

    function _getMetadata(uint256 _tokenId) internal view returns (string memory) {
      uint256 groupId = (_tokenId & GROUP_MASK) >> 128;
      uint256 id = _tokenId << 128 >> 128;
      string memory metadata = string(abi.encodePacked(
        _wrapTrait("Generation", groupId.toString()),',',
        _wrapTrait("Identifier", id.toString())
      ));

      return metadata;
    }

    function _wrapTrait(string memory trait, string memory value) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }

    function _generateSVGImage(uint256 _tokenId, address _owner) internal view returns (string memory svg) {
      NFTSVG.SVGParams memory svgParams =
        NFTSVG.SVGParams({
          tokenId: _tokenId,
          block: block.number,
          owner: _owner
        });

      return NFTSVG.generateSVG(svgParams);
    }
}
