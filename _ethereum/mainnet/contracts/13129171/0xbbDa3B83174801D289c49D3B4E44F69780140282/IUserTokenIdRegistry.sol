// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";


interface IUserTokenIdRegistry {

    function update(uint16 _id) external;

    function get(address _address) external view returns ( uint16 );

    function getTokenOrRevert(address _address) external view returns ( uint16 );
}