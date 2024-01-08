//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./SafeCastUpgradeable.sol";

// import "./console.sol";

contract Repository is Initializable {
    using SafeCastUpgradeable for uint256;

    /// player struct for internal pass on
    struct Player {
        bool register;
        address upline;
        uint256 playingHigh;
        uint256 playingMedium;
        uint256 playCountHigh;
        uint256 playCountMedium;
        uint256 maxPlayCountHigh;
        uint256 maxPlayCountMedium;
        uint256 trophyHigh;
        uint256 trophyMedium;
    }

    // playing table data struct
    struct PlayingTable {
        TablePrice price;
        uint8 trophy;
        uint8 playCount;
        uint8 maxCount;
        uint32 no;
    }

    // player information for getter
    struct PlayerInfo {
        bool register;
        bool playing;
        address account;
        address upline;
        address[] downlines;
        PlayingTable[] playingTable;
    }

    //original => system create
    //split => split from original
    enum TableType {
        Original,
        Split
    }

    //High => 0.5 ether
    //Medium => 0.1 ether
    enum TablePrice {
        High,
        Medium
    }

    /// table struct for internal pass on
    /// @dev also the order of the bytes
    struct Table {
        bool isOpen;
        TableType tableType;
        TablePrice price;
        uint256 index; //index at opening
    }

    // player information for getter
    struct TableInfo {
        bool isOpen;
        TableType tableType;
        TablePrice priceType;
        uint32 tableNo;
        uint256 price;
        address[] seats;
    }

    uint256 internal playerCount; //total player count
    uint256 internal tableCount; //total table count
    mapping(address => bytes32) internal players; //player address =>  encoded Player struct; 1:1
    mapping(address => address) internal upline; //player address =>  upline address; 1:1
    mapping(uint256 => bytes32) internal tables; //table no => encoded Table struct; 1:1

    //binding player and his downlines
    mapping(address => address[]) downlines; //player address => downlines address; 1:N

    //relation price and opening tables..
    mapping(uint256 => uint256[]) internal opening; //TablePrice => tables no; 1:N

    // seats arranged:
    //      0
    //     1 2
    //   3 4 5 6
    mapping(uint256 => address[]) seats; //table no => players adderss; 1:N

    //------------- functions ----------------------

    /// @dev replace constructor
    /// https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    function initialize() public virtual initializer {
        tableCount = 1;
    }

    /// @notice Serialization Player struct
    /// @dev bytes32 assign 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f 20
    /// 0x20 _register
    /// 0x1f _trophyHigh
    /// 0x1e _trophyMedium
    /// 0x1d _playCountHigh
    /// 0x1c _playCountMedium
    /// 0x1b _maxPlayCountHigh
    /// 0x1a _maxPlayCountMedium
    /// 0x19 ~ 0x16 _playingHigh
    /// 0x15 ~ 0x12 _playingMedium
    /// @param _register register
    /// @param _trophyHigh trophy amount for High price type table
    /// @param _trophyMedium trophy amount for Medium price type table
    /// @param _playCountHigh autoplay count now
    /// @param _playCountMedium autoplay count now
    /// @param _maxPlayCountHigh max autoplay count for high
    /// @param _maxPlayCountMedium max autoplay count for medium
    /// @param _playingHigh High price type table no
    /// @param _playingMedium Medium price type table no
    /// @return bytecode struct field data encode
    function PlayerSerializing(
        uint8 _register,
        uint8 _trophyHigh,
        uint8 _trophyMedium,
        uint8 _playCountHigh,
        uint8 _playCountMedium,
        uint8 _maxPlayCountHigh,
        uint8 _maxPlayCountMedium,
        uint32 _playingHigh,
        uint32 _playingMedium
    ) internal pure returns (bytes32 bytecode) {
        assembly {
            mstore(0x20, _register)
            mstore(0x1f, _trophyHigh)
            mstore(0x1e, _trophyMedium)
            mstore(0x1d, _playCountHigh)
            mstore(0x1c, _playCountMedium)
            mstore(0x1b, _maxPlayCountHigh)
            mstore(0x1a, _maxPlayCountMedium)
            mstore(0x19, _playingHigh)
            mstore(0x15, _playingMedium)

            bytecode := mload(0x20)
        }
    }

    /// @notice Deserialization player data from bytes32
    /// @param _bytecode struct field data encode
    /// @return register trophyHigh trophyMedium playingHigh  playingMedium upline
    function PlayerDeserializing(bytes32 _bytecode)
        internal
        pure
        returns (
            uint8 register,
            uint8 trophyHigh,
            uint8 trophyMedium,
            uint8 playCountHigh,
            uint8 playCountMedium,
            uint8 maxPlayCountHigh,
            uint8 maxPlayCountMedium,
            uint32 playingHigh,
            uint32 playingMedium
        )
    {
        assembly {
            register := _bytecode
            mstore(0x20, _bytecode)
            trophyHigh := or(mload(0x1f), 0)
            trophyMedium := or(mload(0x1e), 0)
            playCountHigh := or(mload(0x1d), 0)
            playCountMedium := or(mload(0x1c), 0)
            maxPlayCountHigh := or(mload(0x1b), 0)
            maxPlayCountMedium := or(mload(0x1a), 0)
            playingHigh := or(mload(0x19), 0)
            playingMedium := or(mload(0x15), 0)
        }
    }

    /// @notice increment player count
    /// @return count before addition count
    function incrementPlayer() internal returns (uint256 count) {
        count = playerCount;
        playerCount++;
    }

    /// @notice get player register field
    /// @param _addr player address
    /// @return register bool
    function getPlayerRegisetr(address _addr) internal view returns (bool) {
        (uint8 register, , , , , , , , ) = PlayerDeserializing(players[_addr]);
        return register == 1;
    }

    /// @notice player trophy field getter
    /// @param _addr player address
    /// @return trophy trophy amount
    function getPlayerTrophy(address _addr, TablePrice _price) internal view returns (uint256) {
        (, uint8 trophyHigh, uint8 trophyMedium, , , , , , ) = PlayerDeserializing(players[_addr]);
        return _price == TablePrice.High ? uint256(trophyHigh) : uint256(trophyMedium);
    }

    /// @notice player trophy field setter
    /// @param _addr player address
    /// @param _addr player address
    function setPlayerTrophy(
        address _addr,
        uint256 _amount,
        TablePrice _price
    ) internal {
        assert(_amount <= 2); //maximum 2
        (
            uint8 register,
            uint8 trophyHigh,
            uint8 trophyMedium,
            uint8 playCountHigh,
            uint8 playCountMedium,
            uint8 maxPlayCountHigh,
            uint8 maxPlayCountMedium,
            uint32 playingHigh,
            uint32 playingMedium
        ) = PlayerDeserializing(players[_addr]);

        uint8 amt = _amount.toUint8();
        _price == TablePrice.High ? trophyHigh = amt : trophyMedium = amt;

        players[_addr] = PlayerSerializing(
            register,
            trophyHigh,
            trophyMedium,
            playCountHigh,
            playCountMedium,
            maxPlayCountHigh,
            maxPlayCountMedium,
            playingHigh,
            playingMedium
        );
    }

    /// @notice get player address field
    /// @param _addr player address
    /// @return upline upline address
    function getPlayerUpline(address _addr) internal view returns (address) {
        return upline[_addr];
    }

    /// @notice get playing table by player address and TablePrice enum
    /// @param _addr player address
    /// @param _price TablePrice enum
    /// @return no table no
    function getPlayingTable(address _addr, TablePrice _price) internal view returns (uint256 no) {
        (, , , , , , , uint32 playingHigh, uint32 playingMedium) = PlayerDeserializing(
            players[_addr]
        );
        return _price == TablePrice.High ? uint256(playingHigh) : uint256(playingMedium);
    }

    /// @notice playingTable setter
    /// @param _no table no
    /// @param _price table price
    /// @param _addr player address
    function setPlayingTable(
        address _addr,
        TablePrice _price,
        uint256 _no
    ) internal {
        (
            uint8 register,
            uint8 trophyHigh,
            uint8 trophyMedium,
            uint8 playCountHigh,
            uint8 playCountMedium,
            uint8 maxPlayCountHigh,
            uint8 maxPlayCountMedium,
            uint32 playingHigh,
            uint32 playingMedium
        ) = PlayerDeserializing(players[_addr]);

        uint32 no = _no.toUint32();

        _price == TablePrice.High ? playingHigh = no : playingMedium = no;

        players[_addr] = PlayerSerializing(
            register,
            trophyHigh,
            trophyMedium,
            playCountHigh,
            playCountMedium,
            maxPlayCountHigh,
            maxPlayCountMedium,
            playingHigh,
            playingMedium
        );
    }

    
    //---------- tables -------------------

    /// @notice Serialization Table struct
    /// @dev bytes32 assign 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f 20
    /// 0x20 _isOpen
    /// 0x1f _tableType
    /// 0x1e _price
    /// 0x1d ~ 0x1a _playCountHigh
    /// @param _isOpen table is open flag
    /// @param _tableType table type
    /// @param _price table price
    /// @param _index table index at opening
    /// @return bytecode struct field data encode
    function TableSerializing(
        uint8 _isOpen,
        uint8 _tableType,
        uint8 _price,
        uint32 _index
    ) internal pure returns (bytes32 bytecode) {
        assembly {
            mstore(0x20, _isOpen)
            mstore(0x1f, _tableType)
            mstore(0x1e, _price)
            mstore(0x1d, _index)

            bytecode := mload(0x20)
        }
    }

    /// @notice Deserialization Table struct
    /// @param _bytecode struct field data encode
    /// @return isOpen table is open flag
    /// @return tableType table type
    /// @return price table price
    /// @return index table index at opening
    function TableDeserializing(bytes32 _bytecode)
        internal
        pure
        returns (
            uint8 isOpen,
            uint8 tableType,
            uint8 price,
            uint32 index
        )
    {
        assembly {
            isOpen := _bytecode
            mstore(0x20, _bytecode)
            tableType := or(mload(0x1f), 0)
            price := or(mload(0x1e), 0)
            index := or(mload(0x1d), 0)
        }
    }

    /// @notice get opening data
    function getOpening(TablePrice _price, uint256 _index) internal view returns (uint256 no) {
        uint256 price = uint256(_price);
        no = opening[price][_index];
        return no;
    }

    /// @notice push table no to opening mapping
    function pushOpening(TablePrice _price, uint256 _no) internal returns (uint256 index) {
        uint256 price = uint256(_price);
        opening[price].push(_no);
        index = index > 0 ? index - 1 : 0;
        return index;
    }

    /// @notice delete opening data by price and index
    /// @param _price table price
    /// @param _index array index
    /// @param _no table no for require
    function deleteOpening(
        TablePrice _price,
        uint256 _index,
        uint256 _no
    ) internal returns (bool) {
        uint256 price = uint256(_price);
        uint256 no = opening[price][_index];
        if (no == _no) {
            delete (opening[price][_index]);
            return true;
        }

        //shit..index dirty..
        uint256[] storage open = opening[price];
        for (uint256 i = 0; i < open.length; i++) {
            if (open[i] == _no) {
                delete (open[i]);
                return true;
            }
            if (i == 20) {
                //limit number of iterations...because block gas limit rule
                break;
            }
        }
        return false;
    }

    /// @notice increment table count
    /// @return count before addition count
    function incrementTable() internal returns (uint256 count) {
        count = tableCount;
        tableCount++;
    }

    /// @notice get table isOpen field
    /// @param _no table no
    /// @return isOpen bool
    function getTableIsOpen(uint256 _no) internal view returns (bool) {
        (uint8 isOpen, , , ) = TableDeserializing(tables[_no]);
        return isOpen == 1;
    }

    /// @notice set table isOpen field
    /// @param _no table no
    /// @param _isOpen isOpen
    function setTableIsOpen(uint256 _no, bool _isOpen) internal {
        (uint8 isOpen, uint8 tableType, uint8 price, uint32 index) = TableDeserializing(
            tables[_no]
        );
        isOpen = _isOpen ? 1 : 0;
        tables[_no] = TableSerializing(isOpen, tableType, price, index);
    }

    /// @notice get table price field
    /// @param _no table no
    /// @return price TablePrice enum
    function getTablePrice(uint256 _no) internal view returns (TablePrice) {
        (, , uint8 price, ) = TableDeserializing(tables[_no]);
        return TablePrice(price);
    }

    /// @notice table index field getter
    /// @param _no table no
    /// @return index uint32
    function getTableIndex(uint256 _no) internal view returns (uint256) {
        (, , , uint32 index) = TableDeserializing(tables[_no]);
        return uint256(index);
    }

    /// @notice table index field setter
    /// @param _no table no
    /// @param _index opening index
    function setTableIndex(uint256 _no, uint256 _index) internal {
        (uint8 isOpen, uint8 tableType, uint8 price, uint32 index) = TableDeserializing(
            tables[_no]
        );
        index = _index.toUint32();
        tables[_no] = TableSerializing(isOpen, tableType, price, index);
    }

    /// @notice table seats field getter
    /// @param _no table no
    /// @return seats address[]
    function getTableSeats(uint256 _no) internal view returns (address[] storage) {
        return seats[_no];
    }

    /// @notice push player to table seats field
    /// @param _no table no
    /// @param _addr player address
    function pushTableSeats(uint256 _no, address _addr) internal {
        assert(seats[_no].length < 7);
        seats[_no].push(_addr);
    }

    /// @notice delete player from table seats field
    /// @dev v2 add; re sort sequence
    /// @param _no table no
    /// @param _addr player address
    function deleteTableSeats(uint256 _no, address _addr) internal {
        address[] storage tbSeats = seats[_no];
        bool exist = false;
        uint256 inx = 0;

        //check the _addr exist
        for (uint256 i = 0; i < tbSeats.length; i++) {
            if (i > 7) {
                break;
            }
            if (tbSeats[i] != _addr) {
                tbSeats[inx] = tbSeats[i];
                inx++;
            } else {
                exist = true;
            }
        }

        if (exist) {
            tbSeats.pop();
        }
    }
}
