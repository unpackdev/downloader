//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGameCards {
    function createCard(
        uint32 playerId,
        uint16 season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId
    ) external returns (uint256);

    function getCard(uint256 _cardId)
        external
        view
        returns (
            uint32 playerId,
            uint16 season,
            uint256 scarcity,
            uint16 serialNumber,
            bytes memory metadata,
            uint16 clubId
        );

    function getPlayer(uint32 playerId)
        external
        view
        returns (
            string memory name,
            uint16 yearOfBirth,
            uint8 monthOfBirth,
            uint8 dayOfBirth
        );

    function getClub(uint16 clubId)
        external
        view
        returns (
            string memory name,
            string memory country,
            string memory city,
            uint16 yearFounded
        );

    function cardExists(uint256 cardId) external view returns (bool);
    function getMinter () external view returns (address); 
    function setMinter (address minter) external returns (bool);
}
