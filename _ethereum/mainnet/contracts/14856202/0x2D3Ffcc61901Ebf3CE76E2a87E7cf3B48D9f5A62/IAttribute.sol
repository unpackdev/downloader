//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice a pool of tokens that users can deposit into and withdraw from
interface IAttribute {

    enum AttributeType {
        Unknown,
        String ,
        Bytes,
        Uint256,
        Uint8,
        Uint256Array,
        Uint8Array
    }
    enum TokenType {
        Claim,
        Gem
    }
    
    struct Attribute {
        string key;
        AttributeType attributeType;
        bytes value;
    }

    event AttributeSet(uint256 indexed tokenId, Attribute attribute);

    /// @notice get an attribute for a tokenid keyed by string
    function getAttribute(
        uint256 id,
        string memory key
    ) external view returns (Attribute calldata _attrib);

}
