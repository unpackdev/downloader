//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IGameDB.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./Initializable.sol";

contract GameDB is IGameDB, AccessControlEnumerableUpgradeable {

	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct Player {
        // The name of the actual football player
        string name;
        // The year of birth of the actual football player.
        uint16 yearOfBirth;
        // The month of birth of the actual football player.
        // January is 1.
        uint8 monthOfBirth;
        // The day of birth of the actual football player.
        uint8 dayOfBirth;
    }

    struct Club {
        // Name of the club, leave blank for national team
        string name;
        // Country of the club or national team
        string country;
        // City of the club, leave blank for national team
        string city;
        // Year founded of the club, leave blank for national team
        uint16 yearFounded;
    }

    /// @dev PlayerAdded is fired whenever a new player is added.
    event PlayerAdded(
        uint32 indexed playerId,
        string playerName,
        uint16 yearOfBirth,
        uint8 monthOfBirth,
        uint8 dayOfBirth
    );

    event ClubAdded(
        uint16 indexed clubId,
        string name,
        string country,
        string city,
        uint16 yearFounded
    );

    /// @dev A mapping of player hashs to player id
    mapping(uint256 => uint32) public playerIds;

    /// @dev A mapping of club hashes to club id
    mapping(uint256 => uint16) public clubIds;

    /// @dev An array containing all the Clubs
    Club[] public clubs;

    /// @dev An array containing all the Players
    Player[] public players;

    function init() public initializer  {      
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    /// @dev Creates a new Player. 
    function createPlayer(
        string calldata name,
        uint16 yearOfBirth,
        uint8 monthOfBirth,
        uint8 dayOfBirth
    ) external override returns (uint32) {
    	require(hasRole(MINTER_ROLE, _msgSender()), "GameDB: must have minter role to mint");

        require(
            monthOfBirth >= 1 &&
                monthOfBirth <= 12 &&
                dayOfBirth >= 1 &&
                dayOfBirth <= 31,
            "GameDB: Invalid birth date"
        );

        require(players.length < 4294967295, "GameDB: Too many players");

        uint256 playerHash = uint256(
            keccak256(
                abi.encodePacked(name, yearOfBirth, monthOfBirth, dayOfBirth)
            )
        );

        require(playerIds[playerHash] == 0, "GameDB: Player already exists");

        Player memory player = Player({
            name: name,
            dayOfBirth: dayOfBirth,
            monthOfBirth: monthOfBirth,
            yearOfBirth: yearOfBirth
        });

        players.push(player);
        uint32 playerId = uint32(players.length);
        playerIds[playerHash] = playerId;

        emit PlayerAdded(playerId, name, yearOfBirth, monthOfBirth, dayOfBirth);

        return playerId;
    }
 
    function createClub(
        string calldata name,
        string calldata country,
        string calldata city,
        uint16 yearFounded
    ) external override  returns (uint16) {
    	require(hasRole(MINTER_ROLE, _msgSender()), "GameDB: must have minter role to mint");
        require(bytes(country).length > 0, "GameDB: Country is required");
        require(clubs.length < 65535, "GameDB: Too many clubs");

        uint256 clubHash = uint256(
            keccak256(abi.encodePacked(name, country, city, yearFounded))
        );

        require(clubIds[clubHash] == 0, "GameDB: Club already exists");

        Club memory club = Club({
            name: name,
            country: country,
            city: city,
            yearFounded: yearFounded
        });

        clubs.push(club);
        uint16 clubId = uint16(clubs.length);
        clubIds[clubHash] = clubId;

        emit ClubAdded(clubId, name, country, city, yearFounded);

        return clubId;
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
        require(playerId <= players.length, "GameDB: playerId out of range");
        Player storage p = players[playerId - 1];
        name = p.name;
        yearOfBirth = p.yearOfBirth;
        monthOfBirth = p.monthOfBirth;
        dayOfBirth = p.dayOfBirth;
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
        require(clubId <= clubs.length, "GameDB: clubId out of range");
        Club storage c = clubs[clubId - 1];
        name = c.name;
        country = c.country;
        city = c.city;
        yearFounded = c.yearFounded;
    }
  
    function playerExists(uint32 playerId) external override view returns(bool) {
        require(playerId <= players.length, "GameDB: playerId out of range");
        Player storage player = players[playerId-1];
        return player.yearOfBirth > 0;
    }
 
    function clubExists(uint16 clubId) external override view returns (bool) {
        return clubId <= clubs.length;
    }

    function setMinter (address minter) external override returns (bool) {
    	require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GameDB: must have Admin role to set minter");
    	_setupRole (MINTER_ROLE, minter);
    	return true;
    }
}