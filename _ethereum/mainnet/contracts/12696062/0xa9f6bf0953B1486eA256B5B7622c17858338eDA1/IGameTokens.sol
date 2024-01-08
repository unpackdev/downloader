pragma solidity ^0.8.0;

interface IGameTokens {
    function createCardAndMintToken(
        uint32 playerId,
        uint16 season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId,
        address to
    ) external returns (uint256);

    function mintToken(uint256 cardId, address to) external returns (uint256);
    function setMinter (address minter) external returns (bool);
}
