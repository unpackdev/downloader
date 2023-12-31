// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import "./ERC20.sol";
import "./Ownable.sol";
import "./INameWrapper.sol";
import "./IERC1155Receiver.sol";
import "./ERC165.sol";

/// This proxy contract is used to handle the creations of the subdomains by handling the ownership of the parent
/// subdomain. With the ownership, it calls the setSubnodeRecord to create the subdomain. This function creates the
/// subdomain and mints an NFT thank to the NameWrapper contract.
contract NameWrapperProxy is ERC165, IERC1155Receiver, Ownable {
    INameWrapper public nameWrapper;

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
    ) public returns (bytes32) {
        require(parentNode != bytes32(0), "Parent node cannot be empty");
        require(bytes(label).length > 0, "Label cannot be empty");
        bytes32 node = getNode(label, parentNode);
        require(keccak256(getNodeName(node)) == keccak256(hex""), "Subdomain already exists");
        return nameWrapper.setSubnodeRecord(parentNode, label, owner, resolver, ttl, fuses, expiry);
    }

    function transferENSOwnership(
        address to,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        return nameWrapper.safeTransferFrom(address(this), to, id, amount, "");
    }

    function getNodeName(bytes32 node) public view returns (bytes memory) {
        return nameWrapper.names(node);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /// Gets the namehash of a subdomain, for example, `areo.2718.eth`:
    function getNode(string calldata subdomain, bytes32 parentNode) public pure returns (bytes32) {
        require(bytes(subdomain).length > 0, "Subdomain cannot be empty");
        return keccak256(abi.encodePacked(parentNode, keccak256(bytes(subdomain))));
    }

    /// Gets the namehash of a domain, valid for resolvers and other ens functionalities, for example, gets the namehash
    /// of the domain `2718.eth`:
    function getParentNode(string calldata domain) public pure returns (bytes32) {
        require(bytes(domain).length > 0, "Domain cannot be empty");
        string memory parentDomain = "eth";
        bytes32 subnode = keccak256(abi.encodePacked(bytes32(0), keccak256(bytes(parentDomain))));
        return keccak256(abi.encodePacked(subnode, keccak256(bytes(domain))));
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
