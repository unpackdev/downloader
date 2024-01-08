//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./SafeCastUpgradeable.sol";
import "./Repository.sol";

// import "./console.sol";

contract Usecase is Repository {
    using SafeCastUpgradeable for uint256;

    function initialize() public virtual override {
        Repository.initialize();
    }

    /// @notice create new player
    /// @dev write player struct and binding upline and downline relaction
    /// @param _player player address
    /// @param _upline introduce address
    function _createPlayer(address _player, address _upline) internal {
        uint8 register = 1;
        uint8 trophyHigh;
        uint8 trophyMedium;
        uint8 playCountHigh;
        uint8 playCountMedium;
        uint32 playingHigh;
        uint32 playingMedium;

        //save player basic data
        players[_player] = PlayerSerializing(
            register,
            trophyHigh,
            trophyMedium,
            playCountHigh,
            playCountMedium,
            playCountHigh,
            playCountMedium,
            playingHigh,
            playingMedium
        );
        //save play upline
        upline[_player] = _upline;

        incrementPlayer();

        //upline bind downliner
        downlines[_upline].push(_player);
    }

    ///@notice create new table
    ///@dev write table struct data
    ///@param _price table price
    ///@param _type table type
    function _createTable(TablePrice _price, TableType _type) internal returns (uint256 tableNo) {
        tableNo = incrementTable();
        uint256 inx = pushOpening(_price, tableNo);
        tables[tableNo] = TableSerializing(uint8(1), uint8(_type), uint8(_price), uint16(inx));
        return tableNo;
    }

    /// @notice player join table
    /// @dev set table number to playingTable field
    /// @param _tableNo table number
    /// @param _player player address
    /// @param _price table price enum
    function _joinTable(
        uint256 _tableNo,
        address _player,
        TablePrice _price
    ) internal virtual {
        assert(seats[_tableNo].length < 7);

        uint256 pno = getPlayingTable(_player, _price);
        assert(pno == 0);

        setPlayingTable(_player, _price, _tableNo);
        pushTableSeats(_tableNo, _player);
    }

    /// @notice get player info by address
    /// @param _player player address
    /// @return PlayerInfo player info
    function _getPlayerInfo(address _player) internal view returns (PlayerInfo memory) {
        (uint8 register, , , , , , , , ) = PlayerDeserializing(players[_player]);

        PlayingTable[] memory playingTable = _getPlayingTable(_player);

        bool playing = _isPlaying(_player);

        address[] memory downlines = downlines[_player];
        address upline = getPlayerUpline(_player);
        return
            PlayerInfo({
                account: _player,
                register: register == 1,
                playing: playing,
                upline: upline,
                downlines: downlines,
                playingTable: playingTable
            });
    }

    /// @notice get playing table info
    /// @param _player player address
    /// @return array of info
    function _getPlayingTable(address _player) private view returns (PlayingTable[] memory) {
        (
            ,
            uint8 trophyHigh,
            uint8 trophyMedium,
            uint8 playCountHigh,
            uint8 playCountMedium,
            uint8 maxPlayCountHigh,
            uint8 maxPlayCountMedium,
            uint32 playingHigh,
            uint32 playingMedium
        ) = PlayerDeserializing(players[_player]);

        PlayingTable[] memory playingTable = new PlayingTable[](2);

        playingTable[0].price = TablePrice.High;
        playingTable[0].no = playingHigh;
        playingTable[0].trophy = trophyHigh;
        playingTable[0].playCount = playCountHigh;
        playingTable[0].maxCount = maxPlayCountHigh;

        playingTable[1].price = TablePrice.Medium;
        playingTable[1].no = playingMedium;
        playingTable[1].trophy = trophyMedium;
        playingTable[1].playCount = playCountMedium;
        playingTable[1].maxCount = maxPlayCountMedium;

        return playingTable;
    }

    /// @notice set player autoplay count
    /// @dev
    function _setAutoplayCount(
        address _player,
        TablePrice _price,
        uint256 _count,
        uint256 _maxCount
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
        ) = PlayerDeserializing(players[_player]);

        if (_price == TablePrice.High) {
            playCountHigh = _count.toUint8();
            maxPlayCountHigh = _maxCount.toUint8();
        } else {
            playCountMedium = _count.toUint8();
            maxPlayCountMedium = _maxCount.toUint8();
        }

        players[_player] = PlayerSerializing(
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

    /// @notice check player is playing
    /// @param _player player address
    /// @return tables and bool: playing tables number array and bool
    function _isPlaying(address _player) internal view returns (bool) {
        (, , , , , , , uint32 playingHigh, uint32 playingMedium) = PlayerDeserializing(
            players[_player]
        );
        return playingHigh != 0 || playingMedium != 0;
    }

    /// @notice get table informetion
    /// @param _tableNo table number
    /// @return info TableInfo struct
    function _getTableInfo(uint256 _tableNo) internal view returns (TableInfo memory info) {
        (uint8 isOpen, uint8 tableType, uint8 price, ) = TableDeserializing(tables[_tableNo]);
        address[] memory seats = getTableSeats(_tableNo);

        info = TableInfo({
            isOpen: isOpen == 1,
            tableType: TableType(tableType),
            price: _transfromPriceAmount(TablePrice(price)),
            seats: seats,
            tableNo: _tableNo.toUint16(),
            priceType: TablePrice(price)
        });
    }

    /// @notice close table by tableNo and price
    /// @param _tableNo table number
    function _closeTable(uint256 _tableNo) internal {
        (uint8 isOpen, uint8 tableType, uint8 price, uint32 index) = TableDeserializing(
            tables[_tableNo]
        );

        isOpen = 0;
        index = 0;
        deleteOpening(TablePrice(price), uint256(index), _tableNo);
        tables[_tableNo] = TableSerializing(isOpen, tableType, price, index);
    }

    /// @notice player change table
    /// @param _players player address
    /// @param _price table price
    function _changeTable(address[3] memory _players, TablePrice _price)
        internal
        returns (uint256 tableNo)
    {
        uint256 no = _createTable(_price, TableType.Split);
        seats[no] = _players;

        setPlayingTable(_players[0], _price, no);
        setPlayingTable(_players[1], _price, no);
        setPlayingTable(_players[2], _price, no);

        return no;
    }

    /// @notice get upline playing table no
    /// @dev if upline not playing same price game, just get the one more level upline
    /// @param _firstAddr player address
    /// @param _finalAddr his owner and final upline..
    /// @param _price player paids amount
    function _getUplineGameTable(
        address _firstAddr,
        address _finalAddr,
        TablePrice _price
    ) internal view returns (uint256 tableNo) {
        address nextUplineAddr = _firstAddr;
        tableNo = 0;
        uint256 pno;

        //should fixed number of iterations...because block gas limit rule
        for (uint256 i = 0; i < 5; i++) {
            pno = getPlayingTable(nextUplineAddr, _price);
            if (pno == 0) {
                if (nextUplineAddr == _finalAddr) {
                    //is final upline
                    return 0;
                }
                nextUplineAddr = getPlayerUpline(nextUplineAddr);
                continue;
            }

            if (!getTableIsOpen(pno)) {
                continue;
            }

            tableNo = pno;
            break;
        }
        //can't find upline table
        if (tableNo == 0) {
            tableNo = _getOpeningTable(_price);
        }
    }

    ///@notice get first opening table
    ///@param _price table price
    ///@return uint256
    function _getOpeningTable(TablePrice _price) private view returns (uint256) {
        address[] storage seats;
        //assign first has seat table
        uint256[] storage open = opening[uint256(_price)];
        for (uint256 i = 0; i < open.length; i++) {
            if (i == 10) {
                //limit max iteration
                break;
            }

            seats = getTableSeats(open[i]);
            if (seats.length < 7) {
                return open[i];
            }
        }

        return 0;
    }

    /// @notice calculate ranking
    /// @dev two trophy are winner.
    ///      if two or more player have two trophy. the top is winner.
    ///      next the left.. last right
    /// @param _seats players
    /// @param _price table price
    /// @return sorted address
    function _calcRanking(address[] memory _seats, TablePrice _price)
        internal
        view
        returns (address[] memory sorted)
    {
        uint256[] memory inx = new uint256[](7);
        sorted = new address[](_seats.length);
        uint256 cnt = 0;

        //first find have two trophy player
        for (uint256 i = 0; i < _seats.length; i++) {
            if (getPlayerTrophy(_seats[i], _price) == 2) {
                inx[cnt] = i;
                cnt++;
            }
        }

        //second find have one trophy player
        for (uint256 i = 0; i < _seats.length; i++) {
            if (getPlayerTrophy(_seats[i], _price) == 1) {
                inx[cnt] = i;
                cnt++;
            }
        }

        //finally add zero player trophy
        for (uint256 i = 0; i < _seats.length; i++) {
            if (getPlayerTrophy(_seats[i], _price) == 0) {
                inx[cnt] = i;
                cnt++;
            }
        }

        for (uint256 i = 0; i < inx.length; i++) {
            sorted[i] = _seats[inx[i]];
        }

        return sorted;
    }

    /// @notice assing trophy for introducer
    /// @dev first give introducer(upline).. if upline has two trophy..transfer to downline
    /// @param _player player address
    /// @param _price table price
    /// @return taker and giver
    function _assignIntroducerTrophy(address _player, TablePrice _price)
        internal
        returns (address taker, address giver)
    {
        address upline = getPlayerUpline(_player);
        if (_isCanGainTrophy(upline, _price)) {
            _giveTrophy(upline, _price);
            return (upline, _player);
        }

        //upline has two trophy or not playing
        //transfer to his downline
        address[] storage downlines = downlines[upline];
        for (uint256 i = 0; i < downlines.length; i++) {
            if (i > 19) {
                //downline max iteration twenty
                break;
            }

            if (_isCanGainTrophy(downlines[i], _price)) {
                _giveTrophy(downlines[i], _price);
                return (downlines[i], upline);
            }
        }

        //no one gain trophy
        return (address(0), address(0));
    }

    /// @notice assign replay trophy for introducer
    /// @dev first give introducer(upline), if upline has two trophy, transfer to one more level upline
    /// @param _player player address
    /// @return taker and giver
    function _assignReplayTrophy(address _player, TablePrice _price)
        internal
        returns (address taker, address giver)
    {
        taker = getPlayerUpline(_player);
        giver = _player;

        // max iteration twice
        for (uint256 i = 0; i < 2; i++) {
            if (_isCanGainTrophy(taker, _price)) {
                _giveTrophy(taker, _price);
                return (taker, giver);
            }

            giver = taker;
            taker = getPlayerUpline(giver);
        }

        //no one receive trophy
        return (address(0), address(0));
    }

    /// @notice table price -> enum transformer
    /// @param _amount price amount
    /// @return price enum
    function _transfromPriceType(uint256 _amount) internal pure returns (TablePrice price) {
        assert(_amount == 0.5 ether || _amount == 0.1 ether);

        return _amount == 0.5 ether ? TablePrice.High : TablePrice.Medium;
    }

    /// @notice table enum -> price transformer
    /// @param _price TablePrice enum
    /// @return amount price amount
    function _transfromPriceAmount(TablePrice _price) internal pure returns (uint256 amount) {
        return _price == TablePrice.High ? 0.5 ether : 0.1 ether;
    }

    /// @notice set winner struct field
    /// @dev clear trophy and playing table no then check
    /// @param _player player address
    /// @param _price TablePrice enum
    /// @return autoplay & introducer: automatically next game and upline
    function _setWinner(address _player, TablePrice _price)
        internal
        returns (bool autoplay, address introducer)
    {
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
        ) = PlayerDeserializing(players[_player]);

        //clear trophy and playing table no
        if (_price == TablePrice.High) {
            playingHigh = 0;
            trophyHigh = 0;
            autoplay = playCountHigh < maxPlayCountHigh ? true : false;
            playCountHigh = playCountHigh < maxPlayCountHigh ? playCountHigh++ : maxPlayCountHigh;
        } else {
            playingMedium = 0;
            trophyMedium = 0;
            autoplay = playCountMedium < maxPlayCountMedium ? true : false;
            playCountMedium = playCountMedium < maxPlayCountMedium
                ? playCountMedium++
                : maxPlayCountMedium;
        }

        players[_player] = PlayerSerializing(
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

        return (autoplay, upline[_player]);
    }

    /// @notice check this addresss player can be gain trophy
    /// @dev should playing and the trophy less then 2
    /// @param _player player address
    /// @return bool
    function _isCanGainTrophy(address _player, TablePrice _price) private view returns (bool) {
        (
            ,
            uint8 trophyHigh,
            uint8 trophyMedium,
            ,
            ,
            ,
            ,
            uint32 playingHigh,
            uint32 playingMedium
        ) = PlayerDeserializing(players[_player]);
        return
            _price == TablePrice.High
                ? playingHigh > 0 && trophyHigh < 2
                : playingMedium > 0 && trophyMedium < 2;
    }

    /// @notice check this addresss player can be gain trophy
    /// @dev should playing and the trophy less then 2
    /// @param _player player address
    function _giveTrophy(address _player, TablePrice _price) private {
        uint256 trophy = getPlayerTrophy(_player, _price);
        assert(trophy < 2);
        trophy += 1;
        setPlayerTrophy(_player, trophy, _price);
    }

    /// @notice player quit table
    /// @dev subtract introducer bonus and 10% handling fee
    /// @param _tableNo table no
    /// @param _player player address
    /// @return returnPrice return price
    function _quitTable(uint256 _tableNo, address _player) internal returns (uint256 returnPrice) {
        assert(getTableIsOpen(_tableNo) == true);
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
        ) = PlayerDeserializing(players[_player]);

        TablePrice priceType = getTablePrice(_tableNo);

        //remove playing table and trophy
        if (priceType == TablePrice.High) {
            playingHigh = 0;
            trophyHigh = 0;
            playCountHigh = 0;
        } else {
            playingMedium = 0;
            trophyMedium = 0;
            playCountMedium = 0;
        }

        //lock table
        setTableIsOpen(_tableNo, false);

        deleteTableSeats(_tableNo, _player);

        //unlock table
        setTableIsOpen(_tableNo, true);

        players[_player] = PlayerSerializing(
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

        uint256 price = _transfromPriceAmount(priceType);
        returnPrice = price - ((price / 2) + (price / 10));
    }
}
