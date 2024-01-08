// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";


/// @title A mintable NFT ticket for Coinburp Raffle
/// @author Valerio Leo @valerioHQ
interface IRaffleTicket is IERC1155 {
	function mint(address to, uint256 tokenId, uint256 amount) external;
}
