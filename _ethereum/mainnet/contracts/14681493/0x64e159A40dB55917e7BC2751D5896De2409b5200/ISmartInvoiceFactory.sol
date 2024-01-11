// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";

interface ISmartInvoiceFactory {
    function create(
        address _client,
        address _provider,
        address _dao,
        address _daoToken,
        address _resolver,
        address _token,
        uint256[] calldata _amounts,
        uint256 _terminationTime,
        uint256[4] calldata _rates,
        bytes32 _details
    ) external returns (address);

    function createDeterministic(
        address _client,
        address _provider,
        address _dao,
        address _daoToken,
        address _resolver,
        address _token,
        uint256[] calldata _amounts,
        uint256 _terminationTime,
        uint256[4] calldata _rates,
        bytes32 _details,
        bytes32 _salt
    ) external returns (address);

    function predictDeterministicAddress(bytes32 _salt)
        external
        returns (address);
}
