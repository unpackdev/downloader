// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

interface iERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface iERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external payable;
}

interface iENS {
    function owner(bytes32 node) external view returns (address);
}

interface iENSIP10 {
    error OffchainLookup(address _to, string[] _gateways, bytes _data, bytes4 _callbackFunction, bytes _extradata);

    function resolve(bytes memory _name, bytes memory _data) external view returns (bytes memory);

    function __callback(bytes calldata res, bytes calldata data) external view returns (bytes memory result);
}

interface iResolver {
    function contenthash(bytes32 node) external view returns (bytes memory);

    function addr(bytes32 node) external view returns (address payable);

    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);

    function text(bytes32 node, string calldata key) external view returns (string memory value);

    function name(bytes32 node) external view returns (string memory);

    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);

    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);

    function recordVersions(bytes32 node) external view returns (uint64);

    function zonehash(bytes32 node) external view returns (bytes memory);

    function dnsRecord(bytes32 node, bytes32 name, uint16 resource) external view returns (bytes memory);
}

interface iDev3 is iERC165, iERC173, iENSIP10 {
    function jsonFile(bytes calldata _request) external view returns (string memory);

    function getSigner(string calldata _msg, bytes calldata _signature) external pure returns (address _signer);

    function transferOwnership(address _newOwner) external payable;

    function setCoreDomain(bytes32 _node, string calldata _gateway, string calldata _fallback) external payable;
    function setCoreDomain(bytes32 _node, address _approver, string calldata _gateway, string calldata _fallback)
        external
        payable;

    function removeCoreDomain(bytes32 _node) external payable;

    function updateYourENS(bytes32 _node, string calldata _gateway, string calldata _fallback) external payable;

    function setupYourENS(bytes32 _node, address _signer, string calldata _gateway, string calldata _fallback)
        external
        payable;

    function setApprovedSigner(bytes32 _node, address _signer, bool _set) external payable;

    function setCoreApprover(bytes32 _node, address _approver, bool _set) external payable;

    function setWrapper(address _wrapper, bool _set) external payable;

    function setChainID() external;

    function withdraw(address _token, uint256 _balance) external;

    function withdraw() external;
}

interface iOverloadResolver {
    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory);

    function dnsRecord(bytes32 node, bytes memory name, uint16 resource) external view returns (bytes memory);
}

interface iToken {
    function ownerOf(uint256 id) external view returns (address);

    function transfer(address to, uint256 bal) external;
}

interface iCallbackType {
    function signedRecord(
        address recordSigner, // Manager OR On-Chain Manager OR Off-Chain Manager
        bytes memory recordSignature, // Signature from signer for result value
        bytes memory approvedSignature, // Signature to approve record signer
        bytes memory result // ABI-encoded result
    ) external pure returns (bytes memory);
}
