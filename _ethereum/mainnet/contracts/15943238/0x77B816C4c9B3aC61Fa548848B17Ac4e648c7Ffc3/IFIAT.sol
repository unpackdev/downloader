// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./draft-IERC20Permit.sol";
import "./IERC20Metadata.sol";

interface IFIATExcl {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

interface IFIAT is IFIATExcl, IERC20, IERC20Permit, IERC20Metadata {}
