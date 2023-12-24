// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

interface IENSRegistrarController {
    function makeCommitment(
        string memory name,
        address owner,
        bytes32 secret
    ) external pure returns (bytes32);

    function makeCommitmentWithConfig(
        string memory name,
        address owner,
        bytes32 secret,
        address resolver,
        address addr
    ) external pure returns (bytes32);

    function rentPrice(
        string memory name,
        uint duration
    ) external view returns (uint);

    function commit(bytes32 commitment) external;

    function register(
        string calldata name,
        address owner,
        uint duration,
        bytes32 secret
    ) external payable;
}
