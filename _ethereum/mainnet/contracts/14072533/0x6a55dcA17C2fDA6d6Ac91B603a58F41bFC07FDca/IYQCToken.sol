// SPDX-License-Identifier: GPL-3.0

/// @title Interface for YQCToken

pragma solidity ^0.8.6;

import "./IERC721.sol";

interface IYQCToken is IERC721 {
    event QueenCreated(uint256 indexed tokenId);

    event QueenBurned(uint256 indexed tokenId);

    event QueenersDAOUpdated(address queenersDAO);

    event MinterUpdated(address minter);

    event MinterLocked();

    function isQueenersQueen(uint256 queenId) external pure returns (bool);

    function mint(uint256 queenId, address to) external returns (uint256);

    function burn(uint256 tokenId) external;

    function exists(uint256 tokenId) external view returns (bool);

    function setQueenersDAO(address queenersDAO) external;

    function setMinter(address minter) external;

    function lockMinter() external;
}
