// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ILazyInitCapableElement.sol";

interface ISubDAOsManager is ILazyInitCapableElement {

    struct SubDAOEntry {
        bytes32 key;
        address location;
        address newHost;
    }

    function keyOf(address subdaoAddress) external view returns(bytes32);
    function history(bytes32 key) external view returns(address[] memory subdaosAddresses);
    function batchHistory(bytes32[] calldata keys) external view returns(address[][] memory subdaosAddresses);

    function get(bytes32 key) external view returns(address subdaoAddress);
    function list(bytes32[] calldata keys) external view returns(address[] memory subdaosAddresses);
    function exists(address subject) external view returns(bool);
    function keyExists(bytes32 key) external view returns(bool);

    function set(bytes32 key, address location, address newHost) external returns(address replacedSubdaoAddress);
    function batchSet(SubDAOEntry[] calldata) external returns (address[] memory replacedSubdaoAddresses);

    function submit(bytes32 key, bytes calldata payload, address restReceiver) external payable returns(bytes memory response);

    event SubDAOSet(bytes32 indexed key, address indexed from, address indexed to);
}