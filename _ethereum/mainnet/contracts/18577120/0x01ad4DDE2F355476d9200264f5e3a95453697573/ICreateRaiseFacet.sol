// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// Local imports - Structs
import "./RequestTypes.sol";
import "./CrossChainRequestTypes.sol";

interface ICreateRaiseFacet {
    function createRaise(
        RequestTypes.CreateRaiseRequest calldata _request,
        bytes32 _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        CrossChainRequestTypes.CrossChainData calldata _crossChainData
    ) external payable;
}
