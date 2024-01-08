//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IGameDB.sol";
import "./IGameCards.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./Initializable.sol";


contract GameCards is IGameCards, AccessControlEnumerableUpgradeable  {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct Card {
        // The id of the football Player
        uint32 playerId;
        bytes32 metadata;
        // The football season represented by the first year of the season: Season 2020/2021 is 2020.
        uint16 season;
        // Card serial number
        uint16 serialNumber;
        // Card scarcity
        uint8 scarcity;
        // Id of the football club
        uint16 clubId;
    }

    /// @dev The CardAdded is fired whenever a new Card is minted.
    event CardAdded(
        uint256 indexed cardId,
        uint32 indexed playerId,
        uint16 indexed season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId
    );

    IGameDB private gameData;

    /// @dev The limit number of cards that can be minted depending on their Scarcity Level.
    uint256[] public scarcityLimitByLevel;

    /// @dev Specifies if production of cards of a given season and scarcity has been stopped
    mapping(uint16 => mapping(uint256 => bool)) internal stoppedProductionBySeasonAndScarcityLevel;

    /// @dev A mapping of club hashes to card id
    mapping(uint256 => uint256) public cardIds;

    /// @dev An array containing all the Cards
    Card[] public cards;

    function init(address gameDataAddress) public initializer  {
        require(
            gameDataAddress != address(0),
            "GameCards: gameData address is required"
        );
        gameData = IGameDB(gameDataAddress);

        scarcityLimitByLevel.push(1);           //Unique 
        scarcityLimitByLevel.push(10);          //VIP
        scarcityLimitByLevel.push(100);         //Standard 
        scarcityLimitByLevel.push(1000);        //Special Edition 

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /// @dev Init the maximum number of cards that can be created for a scarcity level.
    function setScarcityLimit(uint256 limit) public  {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GameCards: must have Admin role to set scarcity limit");
        uint256 editedScarcities = scarcityLimitByLevel.length - 1;
        require(
            limit >= scarcityLimitByLevel[editedScarcities] * 2,
            "Limit not large enough"
        );

        scarcityLimitByLevel.push(limit);
    }

    /// @dev Stop the production of cards for a given season and scarcity level
    function stopProductionForSeasonAndScarcityLevel(uint16 season, uint8 level)
        public
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "GameCards: must have minter role to stopProductionForSeasonAndScarcityLevel");
        stoppedProductionBySeasonAndScarcityLevel[season][level] = true;
    }

    /// @dev Returns true if the production has been stopped for a given season and scarcity level
    function productionStoppedForSeasonAndScarcityLevel(
        uint16 season,
        uint8 level
    ) public view returns (bool) {
        return stoppedProductionBySeasonAndScarcityLevel[season][level];
    }

    function createCard(
        uint32 playerId,
        uint16 season,
        uint8 scarcity,
        uint16 serialNumber,
        bytes32 metadata,
        uint16 clubId
    ) 
        public 
        override
        returns (
            uint256
        )
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "GameCards: must have minter role to mint");
        require(gameData.playerExists(playerId), "GameCards: Player does not exist");
        require(gameData.clubExists(clubId), "GameCards: Club does not exist");

        require(
            serialNumber >= 1 && serialNumber <= scarcityLimitByLevel[scarcity],
            "GameCards: Invalid serial number"
        );
        require(
            stoppedProductionBySeasonAndScarcityLevel[season][scarcity] ==
                false,
            "GameCards: Production has been stopped"
        );

        Card memory card;
        card.playerId = playerId;
        card.season = season;
        card.scarcity = scarcity;
        card.serialNumber = serialNumber;
        card.metadata = metadata;
        card.clubId = clubId;
        uint256 cardHash = uint256(
            keccak256(
                abi.encodePacked(
                    playerId,
                    season,
                    uint256(scarcity),
                    serialNumber
                )
            )
        );

        require(cardIds[cardHash] == 0, "GameCards: Card already exists");

        cards.push(card);
        uint256 cardId = uint256(cards.length);
        cardIds[cardHash] = cardId;

        emit CardAdded(
            cardId,
            playerId,
            season,
            scarcity,
            serialNumber,
            metadata,
            clubId
        );

        return cardId;
    }

    function getCard(
        uint256 cardId 
    )
        external
        override
        view
        returns (
            uint32 playerId,
            uint16 season,
            uint256 scarcity,
            uint16 serialNumber,
            bytes memory metadata,
            uint16 clubId
        )
    {
        require(cardId <= cards.length, "GameCards: cardId out of range");
        Card storage c = cards[cardId-1];
        playerId = c.playerId;
        season = c.season;
        scarcity = c.scarcity;
        serialNumber = c.serialNumber;
        metadata = sha256Bytes32ToBytes(c.metadata);
        clubId = c.clubId;
    }

    function getPlayer(uint32 playerId)
        external
        override
        view
        returns (
            string memory name,
            uint16 yearOfBirth,
            uint8 monthOfBirth,
            uint8 dayOfBirth
        )
    {
        (name, yearOfBirth, monthOfBirth, dayOfBirth) = gameData.getPlayer(playerId);
    }

    function getClub(uint16 clubId)
        external
        override
        view
        returns (
            string memory name,
            string memory country,
            string memory city,
            uint16 yearFounded
        )
    {
        (name, country, city, yearFounded) = gameData.getClub(clubId);
    }

    function cardExists(uint256 cardId) external override view returns(bool) {
        require(cardId <= cards.length, "GameCards: cardId out of range");
        Card storage card = cards[cardId-1];
        return card.season > 0;
    }

    function sha256Bytes32ToBytes(bytes32 _bytes32)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return bytesArray;
    }

    function getMinter () external override view returns (address)
    {
        require (getRoleMemberCount(MINTER_ROLE) > 0, "GameCards: No minter role member");
        return getRoleMember(MINTER_ROLE, 0);
    }

    function setMinter (address minter) external override returns (bool) 
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GameCards: must have Admin role to set minter");
        _setupRole (MINTER_ROLE, minter);
        return true;
    }
}