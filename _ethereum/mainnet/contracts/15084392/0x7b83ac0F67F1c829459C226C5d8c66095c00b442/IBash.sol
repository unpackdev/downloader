
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IERC20.sol";

interface IERC20Mintable {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;
}

interface IERC20Burnable {
    function burnFrom(address account_, uint256 amount_) external;
}

interface IBash is IERC20, IERC20Mintable { }