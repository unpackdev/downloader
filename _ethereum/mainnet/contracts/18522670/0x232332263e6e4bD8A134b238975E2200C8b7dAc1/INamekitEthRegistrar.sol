//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface INamekitEthRegistrar {
    
    error WithdrawError();
    error Unauthorized();

    function generateReservationNumber(
        string memory label,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        uint16 ownerControlledFuses
    ) view external returns(bytes32 reservationNumber);

    function requestPermissionToRegister(bytes32 reservationNumber) external;
    
    function completeRegistration(
        string memory label,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        uint16 ownerControlledFuses
    ) external payable;

    function extendRegistration(string calldata label, uint256 duration) external payable;

    function withdraw() external;
}
