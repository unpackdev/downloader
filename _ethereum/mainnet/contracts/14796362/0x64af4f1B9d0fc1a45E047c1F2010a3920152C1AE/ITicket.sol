// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ITicket {
   function claimAllowlistSpot(bytes calldata _signature, address user, uint256 spotId) external;
}
