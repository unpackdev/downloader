// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface ENS {
    function setSubnodeRecord(
        bytes32 parentNode,
        string memory label,
        address owner,
        address resolver,
        uint64 ttl,
        uint32 fuses,
        uint64 expiry
    ) external;
}

contract DummyENSOwner {
    mapping (bytes32 => bool) ownershipGranted;
    address owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function nameHash(string memory mainDomain) public pure returns(bytes32) {
        bytes32 nameHashEth = bytes32(0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae);
        return keccak256(abi.encodePacked(nameHashEth, keccak256(bytes(mainDomain))));
    }

    function setNewSubOwner(string memory mainDomain, string memory sub, address newOwner) public {
        require(msg.sender == owner, "not owner");

        bytes32 key = keccak256(abi.encode(mainDomain, sub));
        require(! ownershipGranted[key], "ownership was already granted");

        ENS(0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401).setSubnodeRecord(
            nameHash(mainDomain),
            sub,
            newOwner,
            0x231b0Ee14048e9dCcD1d247744d114a4EB5E8E63,
            0,
            0,
            0
        );

        ownershipGranted[key] = true;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }    
}