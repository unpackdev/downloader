//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./Controllable.sol";
import "./INameWrapper.sol";
import "./Encoder.sol";

contract NameWrapperDelegate is Controllable {
    INameWrapper nameWrapper;

    constructor(INameWrapper _nameWrapper) {
        nameWrapper = _nameWrapper;
    }

    function setSubnodeRecord(
        bytes32 parentNode,
        string calldata label,
        address owner,
        address resolver,
        uint64 ttl,
        uint32 fuses,
        uint64 expiry
    ) external onlyController returns (bytes32 subnameNode) {
        // can only be called when minting a new subname
        require(
            nameWrapper.ownerOf(uint256(_getSubnameNode(parentNode, label))) ==
                address(0),
            "Subdomain already has an owner"
        );

        subnameNode = nameWrapper.setSubnodeRecord(
            parentNode,
            label,
            owner,
            resolver,
            ttl,
            fuses,
            expiry
        );
    }

    function setFuses(bytes32 node, uint16 fuse) external onlyController {
        nameWrapper.setFuses(node, fuse);
    }

    function _getSubnameNode(
        bytes32 parentNode,
        string calldata label
    ) private pure returns (bytes32) {
        bytes32 labelHash = keccak256(bytes(label));
        return Encoder.encodeNode(parentNode, labelHash);
    }
}
