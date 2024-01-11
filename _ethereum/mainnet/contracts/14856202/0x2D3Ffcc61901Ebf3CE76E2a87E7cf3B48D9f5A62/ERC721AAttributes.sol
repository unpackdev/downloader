//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IAttribute.sol";


/// @title ERC721AAttributes
/// @notice the total balance of a token type
abstract contract ERC721AAttributes {

    event AttributeSet(uint256 indexed tokenId, string indexed key, uint256 value);

    mapping(uint256 => mapping(string => IAttribute.Attribute)) private _attributes;

    /// @notice get an attribute for a tokenid keyed by string
    function getAttribute(
        uint256 id,
        string memory key
    ) external view returns (IAttribute.Attribute memory) {
        return _attributes[id][key];
    }
    
    /// @notice set an attribute for a tokenid keyed by string
    function _getAttribute(
        uint256 id,
        string memory key
    ) internal view returns (IAttribute.Attribute memory) {
        return _attributes[id][key];
    }
    
    /// @notice set an attribute to a tokenid keyed by string
    function _setAttribute(
        uint256 id,
        IAttribute.Attribute memory attribute
    ) internal virtual {
        _attributes[id][attribute.key] = attribute;
        emit AttributeSet(id, attribute.key, uint256(bytes32(attribute.value)));
    }

    /// @notice remove the attribute for a tokenid keyed by string
    function _removeAttribute(
        uint256 id,
        string memory key
    ) internal virtual {
        delete _attributes[id][key];
    }

}  
