// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IUniversalResolver {
    function reverse(
        bytes calldata reverseName
    ) external view returns (string memory, address, address, address);

    /**
     * @dev Performs ENS name reverse resolution for the supplied reverse name.
     * @param reverseName The reverse name to resolve, in normalised and DNS-encoded form. e.g. b6E040C9ECAaE172a89bD561c5F73e1C48d28cd9.addr.reverse
     * @return The resolved name, the resolved address, the reverse resolver address, and the resolver address.
     */
    function reverse(
        bytes calldata reverseName,
        string[] memory gateways
    ) external view returns (string memory, address, address, address);

    /**
     * @dev Performs ENS name resolution for the supplied name and resolution data.
     * @param name The name to resolve, in normalised and DNS-encoded form.
     * @param data The resolution data, as specified in ENSIP-10.
     * @return The result of resolving the name.
     */
    function resolve(
        bytes calldata name,
        bytes memory data
    ) external view returns (bytes memory, address);

    function resolve(
        bytes calldata name,
        bytes[] memory data
    ) external view returns (bytes[] memory, address);
}

interface ITextResolver {
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
}