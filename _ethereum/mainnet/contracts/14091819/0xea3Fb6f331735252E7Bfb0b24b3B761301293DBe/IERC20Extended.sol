// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later

pragma solidity =0.8.9;

import "./IERC20.sol";

interface IERC20Extended is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}
