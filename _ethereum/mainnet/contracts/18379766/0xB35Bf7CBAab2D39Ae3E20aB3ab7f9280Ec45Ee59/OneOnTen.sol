// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 * @title OneOnTen
 *
 *
 * Decentralized gaming room contract that allows players to join rooms and compete.
 * 
 *
 * Two modes available : 
 * - 1v1 gives you 50% probability of winning ( you win 80% of the total pledge of all players ). This mode finishes as soon as the second player enter the room.
 * - 1v10 gives you 10% probability of winning ( you win 80% of the total pledge of all players ). This mode finishes as soon as the 10th player enters the room, or after around 1200 mined blocks - around 4h ( you are refunded after the timer ends if no other player's joined ).
 *
 *
 * In order to access a gaming room you just need to enter the desired ETH amount you want to play and select the game mode.
 *
 * Different rooms fees : 
 * - 0.01 ETH --> you win :
 * - - - - - - - - 0.016 ETH in 1v1
 * - - - - - - - - 0.08 ETH in 1v10
 *
 * - 0.03 ETH --> you win :
 * - - - - - - - - 0.048 ETH in 1v1
 * - - - - - - - - 0.24 ETH in 1v10
 *
 * - 0.1 ETH --> you win :
 * - - - - - - - - 0.16 ETH in 1v1
 * - - - - - - - - 0.8 ETH in 1v10
 *
 * - 1 ETH --> you win :
 * - - - - - - - - 1.6 ETH in 1v1
 * - - - - - - - - 8 ETH in 1v10
 *
 * - 10 ETH --> you win :
 * - - - - - - - - 16 ETH in 1v1
 * - - - - - - - - 80 ETH in 1v10
 *
 */
contract OneOnTen {
    struct Room {
        uint256 entryFee;
        uint8 maxPlayers;
        address[] players;
        uint256 startTimeBlock;
        bool isActive;
    }

    uint256 public constant BLOCKS_FOR_4_HOURS = 1200;
    uint256 public constant MAX_PLAYERS_1v1 = 2;
    uint256 public constant MAX_PLAYERS_1v10 = 10;
    uint256[] public activeRoomIds;

    Room[] internal rooms;
    mapping(uint8 => uint256) public roomTypeToEntryFee;

    event PlayerJoined(uint256 roomId, address player);
    event RoomCreated(uint256 roomId, uint256 entryFee, uint8 maxPlayers);
    event TimerStarted(uint256 roomId, uint256 startBlock);
    event TimerEnded(uint256 roomId);
    event PlayerRefunded(address player, uint256 amount);
    event WinnerPaid(address winner, uint256 amount);
    event RoomDeactivated(uint256 roomId);
    event MissingBlocks(uint256 roomId, uint256 missingBlocks);
    event Debug(string message, uint256 value);


    constructor() {
        roomTypeToEntryFee[1] = 0.01 ether;
        roomTypeToEntryFee[2] = 0.03 ether;
        roomTypeToEntryFee[3] = 0.1 ether;
        roomTypeToEntryFee[4] = 1 ether;
        roomTypeToEntryFee[5] = 10 ether;
    }

    /**
     * @dev External function allowing a player to enter a 1v1 room.
     *      This function is payable, meaning it can accept ether.
     *      It calls the internal {enterRoom} function with MAX_PLAYERS_1v1 as the parameter.
     *
     * @notice The transaction must include the required entry fee in ether.
     *
     * Emits all events through {enterRoom}.
     */
    function enterRoom1v1() external payable {
        enterRoom(uint8(MAX_PLAYERS_1v1));
    }

    /**
     * @dev External function allowing a player to enter a 1v10 room.
     *      This function is payable, meaning it can accept ether.
     *      It calls the internal {enterRoom} function with MAX_PLAYERS_1v10 as the parameter.
     *
     * @notice The transaction must include the required entry fee in ether.
     *
     * Emits all events through {enterRoom}.
     */
    function enterRoom1v10() external payable {
        enterRoom(uint8(MAX_PLAYERS_1v10));
    }



    /**
     * @dev Internal function to handle the logic for a player to enter a room.
     *      This function will either find an active room or create one if none are available.
     *
     * @param maxPlayers The maximum number of players that the room can have.
     *
     * The sent ether must be enough for the entry fee.
     *
     * Emits a {PlayerJoined} event.
     * Calls {endTimer} to check and conclude any filled or expired rooms.
     * Calls {startTimer} to initiate the timer for a new room.
     *
     * Debug events are for testing and can be removed later.
     */
    function enterRoom(uint8 maxPlayers) internal {

        endTimer();

        uint256 entryFee = getRoomTypeBasedOnValue(msg.value);
        emit Debug("Entry fee calculated", entryFee);
        require(entryFee > 0, "Entry fee must be greater than 0");

        uint256 roomId = getOrCreateActiveRoom(entryFee, maxPlayers);
        emit Debug("Room ID received", roomId);
        
        Room storage room = rooms[roomId];
        room.players.push(msg.sender);
        emit PlayerJoined(roomId, msg.sender);

        if (room.players.length == 1) {
            startTimer(roomId);
        }

        endTimer();

    }

    /**
     * @dev Starts the timer for the room by setting the room's `startTimeBlock` to the current block number.
     * @param roomId The ID of the room for which the timer is to be started.
     * @notice This function emits a `TimerStarted` event after successfully starting the timer.
     */
    function startTimer(uint256 roomId) internal {
        Room storage room = rooms[roomId];
        room.startTimeBlock = block.number;
        emit TimerStarted(roomId, block.number);
    }

    /**
     * @dev Ends the timer for active rooms based on certain conditions.
     *      - If a 1v1 room has 2 players.
     *      - If a 1v10 room has 10 players.
     *      - If the room's timer has exceeded a 4-hour block time.
     *      
     * After the timer ends, the function handles the payout or refund logic.
     * It also deactivates the room and removes it from the active rooms list.
     * 
     * @notice This function emits a `TimerEnded` event for each room whose timer is ended.
     * It also emits a `RoomDeactivated` event for rooms that are deactivated.
     * Further events may be emitted for payouts and refunds (see `payout` and `refundPlayer`).
     */
    function endTimer() internal {
        uint256 i = 0;
        while (i < activeRoomIds.length) {
            uint256 roomId = activeRoomIds[i];
            Room storage room = rooms[roomId];
            if (room.isActive) {
                if ((room.maxPlayers == MAX_PLAYERS_1v1 && room.players.length == MAX_PLAYERS_1v1) || 
                    (room.maxPlayers == MAX_PLAYERS_1v10 && room.players.length == MAX_PLAYERS_1v10) || 
                    (block.number >= room.startTimeBlock + BLOCKS_FOR_4_HOURS)) {
                    
                    emit TimerEnded(roomId);
                    if (room.players.length == 1) {
                        address solePlayer = room.players[0];
                        refundPlayer(solePlayer, room.entryFee);
                    } else if (room.players.length > 1) {  
                        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender)));
                        address winner = room.players[randomness % room.players.length];
                        uint256 totalPayout = room.players.length * room.entryFee;
                        uint256 winnerPayout = (totalPayout * 8) / 10;
                        payout(winner, winnerPayout);
                    }

                    room.isActive = false;
                    emit RoomDeactivated(roomId);
                    
                    activeRoomIds[i] = activeRoomIds[activeRoomIds.length - 1];
                    activeRoomIds.pop();
                } else {
                    i++;
                }
            }
        }
    }

    /**
     * @dev Searches for an active room that matches the given entry fee and maximum players.
     *      If no such room exists, a new room is created.
     * 
     * @param entryFee The entry fee to search or create a room with.
     * @param maxPlayers The maximum number of players allowed in the room.
     * 
     * @return uint256 The ID of the room that was found or created.
     * 
     * @notice This function emits a `RoomCreated` event if a new room is created.
     * It also emits Debug events for debugging purposes; these can be removed in production.
     */
    function getOrCreateActiveRoom(uint256 entryFee, uint8 maxPlayers) internal returns (uint256) {
        emit Debug("Entering getOrCreateActiveRoom", entryFee);
        for (uint256 i = 0; i < activeRoomIds.length; i++) {
            uint256 roomId = activeRoomIds[i];
            Room storage room = rooms[roomId];
            require(room.isActive && room.players.length < room.maxPlayers, "Room conditions changed");
            emit Debug("Checking room with ID", roomId);
            if (room.entryFee == entryFee && room.isActive && room.players.length < room.maxPlayers && room.maxPlayers == maxPlayers) {
                return roomId;
            }
        }
        Room memory newRoom = Room(entryFee, maxPlayers, new address[](0), 0, true);
        rooms.push(newRoom);
        uint256 newRoomId = rooms.length - 1;
        activeRoomIds.push(newRoomId);
        emit Debug("New room created with ID", newRoomId);
        emit RoomCreated(newRoomId, entryFee, maxPlayers);
        return newRoomId;
    }

    /**
     * @dev Determines the appropriate room entry fee based on the provided value.
     *
     * @param value The value in Ether to be checked against predefined entry fee thresholds.
     * 
     * @return uint256 The entry fee that matches the provided value based on predefined thresholds.
     * 
     * @notice This function does not perform any external calls or state modifications, thus it is marked as pure.
     */
    function getRoomTypeBasedOnValue(uint256 value) internal pure returns (uint256) {
        if (value >= 10 ether) {
            return 10 ether;
        } else if (value >= 1 ether) {
            return 1 ether;
        } else if (value >= 0.1 ether) {
            return 0.1 ether;
        } else if (value >= 0.03 ether) {
            return 0.03 ether;
        } else {
            return 0.01 ether;
        }
    }

    /**
     * @dev Refunds the specified amount of Ether to the provided player address.
     *
     * @param playerAddress The address of the player to be refunded.
     * @param amount The amount of Ether in Wei to refund.
     * 
     * @notice This function performs a state-changing operation by transferring funds.
     * 
     * Emits a {PlayerRefunded} event.
     */
    function refundPlayer(address playerAddress, uint256 amount) internal {
        payable(playerAddress).transfer(amount);
        emit PlayerRefunded(playerAddress, amount);
    }

    /**
     * @dev Pays out the specified amount of Ether to the provided winner address.
     *
     * @param winner The address of the player who won.
     * @param amount The amount of Ether in Wei to be paid out.
     *
     * @notice This function performs a state-changing operation by transferring funds.
     *
     * Emits a {WinnerPaid} event.
     */
    function payout(address winner, uint256 amount) internal {
        payable(winner).transfer(amount);
        emit WinnerPaid(winner, amount);
    }

    /**
     * @dev Retrieves the number of blocks remaining before the timer for a given room expires.
     *
     * @param roomId The ID of the room for which to retrieve the missing blocks.
     *
     * The room must be active.
     *
     * @notice This function is a view function and does not modify state.
     *
     * Emits a {MissingBlocks} event.
     */
    function getMissingBlocks(uint256 roomId) external  {
        Room storage room = rooms[roomId];
        require(room.isActive, "Room is not active");
        uint256 missingBlocks = (room.startTimeBlock + BLOCKS_FOR_4_HOURS) - block.number;
        emit MissingBlocks(roomId, missingBlocks);
    }
}