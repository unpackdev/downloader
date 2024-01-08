pragma solidity ^0.7.0;


interface TraitsOnChain {
    function hasTrait(uint16 traitID, uint16 tokenId) external view returns (bool);
    function setTrait(uint16 traitID, uint16 tokenId, bool _value) external;
}

