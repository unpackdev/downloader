// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./IERC721Upgradeable.sol";

interface INounsToken is IERC721Upgradeable {
	function minter() external view returns (address);
}
