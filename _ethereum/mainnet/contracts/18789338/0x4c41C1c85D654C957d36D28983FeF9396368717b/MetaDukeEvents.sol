// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MetaDukeEvents {
    event SetRound(
        address indexed operator,
        uint256 indexed roundId,
        bool isActive,
        uint256 start,
        uint256 end,
        uint256 limit,
        uint256 supply,
        uint256 cap,
        uint256 price
    );
    event SetRoundStatus(address indexed operator, uint256 indexed roundId, bool status);

    event Minted(address indexed minter, uint256 indexed roundId, uint256 indexed id);
    event PrivateMinted(address operator, address indexed receiver, uint256 indexed roundId, uint256 indexed id);
    event MarketMinted(address indexed operator, address indexed receiver, uint256 indexed id);
}
