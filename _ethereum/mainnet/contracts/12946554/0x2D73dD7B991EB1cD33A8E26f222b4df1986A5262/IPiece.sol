//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "./IERC20.sol";


interface IPiece is IERC20 {
    function burn(uint256 amount) external;
    function mint(address account, uint256 amount) external;
}
