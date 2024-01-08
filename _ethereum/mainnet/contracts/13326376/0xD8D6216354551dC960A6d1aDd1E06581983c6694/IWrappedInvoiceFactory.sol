// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWrappedInvoiceFactory {
    function create(
        address _client,
        address[] calldata _providers,
        uint256 _splitFactor,
        uint8 _resolverType,
        address _resolver,
        address _token,
        uint256[] calldata _amounts,
        uint256 _terminationTime,
        bytes32 _details
    ) external returns (address);
}
