// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface CurveToken {
    // solhint-disable-next-line
    function get_virtual_price() external view returns (uint256);
    function minter() external view returns (address);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}
