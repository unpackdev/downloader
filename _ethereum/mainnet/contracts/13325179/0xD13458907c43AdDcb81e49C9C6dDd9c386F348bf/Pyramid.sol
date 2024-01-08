//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./AddressUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./Usecase.sol";

// import "./console.sol";

contract Pyramid is Usecase, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    // library
    using AddressUpgradeable for address;
    using SafeCastUpgradeable for uint256;

    // contract environment
    enum Environment {
        Maintaince,
        Opening
    }

    Environment private env;

    //enum for event
    enum TableEventState {
        Create,
        PlayerJoin,
        FinishGame
    }

    enum PlayerEventState {
        Create,
        JoinTable,
        ChaingTable,
        LeaveTable,
        QuitGame
    }

    enum GainReasonType {
        Introducer,
        Replay,
        Winner
    }

    enum WithdrawType {
        Bonus,
        Income
    }

    //contract income
    uint256 internal income;

    //player bonus amount..
    struct Withdraw {
        uint256 limitBlockNumber; //after block number could be withdraw
        uint256 amount;
    }

    mapping(address => Withdraw) public pendingWithdrawals;

    //---------- event -------------------------
    /// @notice received ether event
    /// @param addr sender address
    /// @param amount amount
    event LogReceived(address indexed addr, uint256 amount);

    /// @notice emitted on table change
    /// @param tableNo table number
    /// @param state TableEventState enum
    /// @param player join player
    event LogTable(uint32 indexed tableNo, TableEventState indexed state, address indexed player);

    /// @notice emitted on player data change
    /// @param player player address
    /// @param upline upline address
    /// @param state event state
    /// @param tableNo playing table
    event LogPlayer(
        address indexed player,
        address indexed upline,
        PlayerEventState indexed state,
        uint32 tableNo
    );

    /// @notice player gain trophy event
    /// @param taker recipient player address
    /// @param giver giver trophy address
    /// @param reason gain reason
    event LogGainTrophy(
        address indexed taker,
        address indexed giver,
        GainReasonType indexed reason
    );

    /// @notice new introduce bonus event
    /// @param player taker address
    /// @param reason downline address
    /// @param amount bonus amount
    /// @param table  winner table no
    /// @param downline introduce downline address
    /// @param price  ref price
    event LogGainBonus(
        address indexed player,
        GainReasonType indexed reason,
        uint256 indexed amount,
        uint32 table,
        address downline,
        TablePrice price
    );

    /// @notice withdraw bonus event
    /// @param player player address
    /// @param withdrawType type enum
    /// @param amount amount
    event LogWithdraw(address indexed player, WithdrawType indexed withdrawType, uint256 amount);

    /// @notice finish game event
    /// @param tableNo table number
    /// @param winner winner address
    /// @param second second address
    /// @param third third address
    event LogFinishGame(
        uint32 indexed tableNo,
        address indexed winner,
        address second,
        address third
    );

    /// @notice emitted on received handling fee
    /// @param player player address
    /// @param amount income amount
    event LogIncome(address indexed player, uint256 amount);
    //---------- error --------------------------------

    /// @notice error
    /// @param code error code
    /// @dev
    ///    --- 1xx Account error ----
    ///    110 Unfound account
    ///    111 Account already exist
    ///    121 Unfound introducer
    ///    113 Account playing
    ///    114 Account not playing
    ///    --- 3xx Game error --------
    ///    301 Table closed
    ///    --- 4xx Withdraw error ----
    ///    401 Income not enough
    ///    402 Bonus not enough
    ///    403 Not yet up to limit block
    ///    --- 5xx Maybe tried to attack -----
    ///    500 Unmatch price.
    ///    501 Unknown environment
    ///    502 Only account can call this
    ///    503 Only can call when system maintenance
    ///    504 System maintenance
    /// @param message error message
    error RequestError(uint256 code, bytes32 message);

    //----------replace modifier -----------------------------
    /// @notice check payd amount
    /// @dev price should 0.1 ether or 0.5 ether
    function __matchPrice(uint256 _amount) internal pure {
        if (_amount != 0.1 ether && _amount != 0.5 ether)
            revert RequestError(500, "Unmatch price.");
    }

    /// @notice check caller address is an account
    /// @dev use "@openzeppelin/contracts/utils/Address.sol"
    function __onlyAccount(address _addr) internal view {
        if (_addr.isContract()) revert RequestError(502, "Only account can call this");
    }

    /// @notice check environment not maintaince
    function __onlyMaintaince() internal view {
        if (env != Environment.Maintaince)
            revert RequestError(503, "Only can call when maintenance");
    }

    /// @notice check environment not maintaince
    function __blockingMaintaince() internal view {
        if (env == Environment.Maintaince) revert RequestError(504, "System maintenance");
    }

    //---------- function -----------------------------

    /// @dev replace constructor
    /// https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    function initialize() public virtual override initializer {
        Usecase.initialize();
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    }

    /// @dev generate first player then open to the public
    function startGame() external onlyOwner returns (bool) {
        __onlyMaintaince();

        address owner = owner();
        if (getPlayerRegisetr(owner)) {
            return false;
        }

        newPlayer(msg.sender, msg.sender);
        uint256 no;
        no = newTable(TablePrice.High, TableType.Original);
        joinTable(no, msg.sender, TablePrice.High);

        no = newTable(TablePrice.Medium, TableType.Original);
        joinTable(no, msg.sender, TablePrice.Medium);

        env = Environment.Opening;

        return true;
    }

    /// receive ether
    receive() external payable {
        emit LogReceived(msg.sender, msg.value);
    }

    /// fallback
    fallback() external {}

    /// @notice withdraw imcome use for owner
    function withdrawIncome() external onlyOwner nonReentrant {
        if (income <= 0) revert RequestError(401, "Income not enough");
        uint256 thisAmount = income;
        income = 0;
        payable(owner()).transfer(income);
        emit LogWithdraw(owner(), WithdrawType.Income, thisAmount);
    }

    /// @notice withdraw bonus use for players
    /// @dev Remember to zero the pending refund before sending to prevent re-entrancy attacks
    function withdrawBonus() external nonReentrant {
        __blockingMaintaince();
        __onlyAccount(msg.sender);

        if (pendingWithdrawals[msg.sender].limitBlockNumber > block.number)
            revert RequestError(403, "Not yet up to limit block");

        uint256 amount = pendingWithdrawals[msg.sender].amount;
        if (amount <= 0) revert RequestError(402, "Bonus not enough");
        pendingWithdrawals[msg.sender].amount = 0;

        payable(msg.sender).transfer(amount);
        emit LogWithdraw(msg.sender, WithdrawType.Bonus, amount);
    }

    /// @notice apply play game
    /// @dev new player join to play handler
    /// @param _introducer introducer address
    /// @param _autoplay automatically next game when win
    function play(address _introducer, bool _autoplay) external payable nonReentrant {
        __blockingMaintaince();
        __onlyAccount(msg.sender);
        __matchPrice(msg.value);

        if (getPlayerRegisetr(msg.sender)) revert RequestError(111, "Account already exist");
        if (!getPlayerRegisetr(_introducer)) revert RequestError(121, "Unfound introducer");

        TablePrice price = _transfromPriceType(msg.value);

        //create new player and bind upline
        newPlayer(msg.sender, _introducer);

        assignTable(msg.sender, _introducer, price);

        uint256 maxPlayCount = _autoplay ? 10 : 1;
        _setAutoplayCount(msg.sender, price, uint256(1), maxPlayCount);

        giveIntBonus(msg.sender, _introducer, price);

        giverIntTrophy(msg.sender, price);

        emit LogReceived(msg.sender, msg.value);
    }

    /// @notice replay game
    /// @dev similar Play() but not introduce code param
    /// @param _autoplay automatically next game when win
    function replay(bool _autoplay) public payable nonReentrant {
        __blockingMaintaince();
        __onlyAccount(msg.sender);
        __matchPrice(msg.value);

        (
            uint8 register,
            ,
            ,
            ,
            ,
            ,
            ,
            uint32 playingHigh,
            uint32 playingMedium
        ) = PlayerDeserializing(players[msg.sender]);

        bool reg = register == 1;
        if (!reg) revert RequestError(110, "Unfound account");

        uint256 pno = msg.value == 0.5 ether ? uint256(playingHigh) : uint256(playingMedium);
        if (pno > 0) revert RequestError(113, "Account playing");

        address upline = upline[msg.sender];

        //just buy insurance
        if (upline == address(0)) {
            upline = owner();
        }

        //save autoplay count
        TablePrice price = _transfromPriceType(msg.value);
        uint256 maxPlayCount = _autoplay ? 10 : 1;
        _setAutoplayCount(msg.sender, price, uint256(1), maxPlayCount);

        assignTable(msg.sender, upline, price);
        giveIntBonus(msg.sender, upline, price);
        giveReplayTrophy(msg.sender, price);

        emit LogReceived(msg.sender, msg.value);
    }

    // //======== getter & setter ============

    /// @notice get income amount
    /// @dev only owner can call it
    function getIncome() external view onlyOwner returns (uint256) {
        return income;
    }

    /// @notice env setter
    /// @dev only owner can call it
    /// @param _env env number 0 => dev 1 => prod
    function setEnv(uint256 _env) external onlyOwner {
        if (_env < 0 || _env > 1) revert RequestError(501, "Unknown environment");
        env = Environment(_env);
    }

    /// @notice env getter
    /// @dev only owner can call it
    /// @return env number 0 => dev 1 => prod
    function getEnv() external view onlyOwner returns (Environment) {
        return env;
    }

    /// @notice get player information
    /// @param _addr player address
    /// @return PlayerInfo struct
    function fetchPlayer(address _addr) external view returns (PlayerInfo memory) {
        return _getPlayerInfo(_addr);
    }

    /// @notice get table information
    /// @param _no table no
    /// @return tableInfo struct
    function fetchTable(uint256 _no) external view returns (TableInfo memory) {
        return _getTableInfo(_no);
    }

    // //=========== intrnal & private ==============

    // ///@notice create new table
    // ///@param _price TablePrice join price
    // ///@param _type TableType table type
    function newTable(TablePrice _price, TableType _type) private returns (uint256 tableNo) {
        tableNo = _createTable(_price, _type);
        emit LogTable(tableNo.toUint32(), TableEventState.Create, address(0));

        return tableNo;
    }

    /// @notice player join table
    /// @param _tableNo table number
    /// @param _player player address
    /// @param _price table price
    function joinTable(
        uint256 _tableNo,
        address _player,
        TablePrice _price
    ) private {
        _joinTable(_tableNo, _player, _price);
        EmitLogPlayer(_player, PlayerEventState.JoinTable, _tableNo);
        emit LogTable(_tableNo.toUint32(), TableEventState.PlayerJoin, _player);
    }

    /// @notice assign player on upline table
    /// @param _player player address
    /// @param _upline upline address
    /// @param _price player paids amount
    function assignTable(
        address _player,
        address _upline,
        TablePrice _price
    ) private returns (uint256 tableNo) {
        tableNo = _getUplineGameTable(_upline, owner(), _price);

        if (tableNo != 0 && getTableSeats(tableNo).length < 7) {
            joinTable(tableNo, _player, _price);

            //check table is can be close
            finishGame(tableNo, _price);
            return tableNo;
        }

        //can't find in rule table..
        tableNo = newTable(_price, TableType.Split);
        joinTable(tableNo, _player, _price);
        return tableNo;
    }

    /// @notice check seats if sit full. close table
    /// @dev setting table state to close..then kick winner and split table
    /// @param _tableNo table number
    /// @param _price table price
    /// @return bool
    function finishGame(uint256 _tableNo, TablePrice _price) private returns (bool) {
        address[] storage seats = getTableSeats(_tableNo);
        if (seats.length < 7) {
            //seats not full
            return false;
        }

        //order by trophy amount
        address[] memory rank = _calcRanking(seats, _price);

        emit LogFinishGame(_tableNo.toUint32(), rank[0], rank[1], rank[2]);

        _closeTable(_tableNo);
        emit LogTable(_tableNo.toUint32(), TableEventState.FinishGame, address(0));

        //1st add giver bonus and clean trophy
        winnerHandler(rank[0], _tableNo, _price);

        //2nd. 3rd split new table with other player
        splitTable(rank, _price);

        return true;
    }

    /// @notice winner handler when finish game
    /// @param _winner winner aaddress
    /// @param _tableNo finish table no
    /// @param _price table price enum
    function winnerHandler(
        address _winner,
        uint256 _tableNo,
        TablePrice _price
    ) private {
        (bool autoplay, address upline) = _setWinner(_winner, _price);
        EmitLogPlayer(_winner, PlayerEventState.LeaveTable, _tableNo);
        giveWinnerBonus(_winner, _tableNo, _price, autoplay);

        if (autoplay) {
            assignTable(_winner, upline, _price);
            giveIntBonus(_winner, upline, _price);
            giveReplayTrophy(_winner, _price);
        }
    }

    /// @notice split table when finish game
    /// @param _players players address
    /// @param _price table price enum
    function splitTable(address[] memory _players, TablePrice _price) private {
        address[3] memory atb = [_players[1], _players[3], _players[4]];
        address[3] memory btb = [_players[2], _players[5], _players[6]];
        uint256 ano = _changeTable(atb, _price);
        uint256 bno = _changeTable(btb, _price);

        //log new table
        emit LogTable(ano.toUint32(), TableEventState.Create, address(0));
        emit LogTable(bno.toUint32(), TableEventState.Create, address(0));

        //log player change table
        EmitLogPlayer(_players[1], PlayerEventState.ChaingTable, ano);
        EmitLogPlayer(_players[3], PlayerEventState.ChaingTable, ano);
        EmitLogPlayer(_players[4], PlayerEventState.ChaingTable, ano);

        EmitLogPlayer(_players[2], PlayerEventState.ChaingTable, bno);
        EmitLogPlayer(_players[5], PlayerEventState.ChaingTable, bno);
        EmitLogPlayer(_players[6], PlayerEventState.ChaingTable, bno);
    }

    /// @notice create new player
    /// @param _player player address
    /// @param _upline introducer address
    function newPlayer(address _player, address _upline) private {
        _createPlayer(_player, _upline);
        EmitLogPlayer(_player, PlayerEventState.Create, 0);
    }

    /// @notice log introducer bonus info
    /// @dev table price 50%
    /// @param _downline downline's address
    /// @param _upline recipient player
    /// @param _price player paid amount
    /// @return bool
    function giveIntBonus(
        address _downline,
        address _upline,
        TablePrice _price
    ) private returns (bool) {
        uint256 amt = _transfromPriceAmount(_price) / 2;
        pendingWithdrawals[_upline].amount += amt;
        pendingWithdrawals[_upline].limitBlockNumber = block.number + 12;

        emit LogGainBonus(_upline, GainReasonType.Introducer, amt, 0, _downline, _price);

        return true;
    }

    /// @notice record winner bonus info
    /// @dev table's price 200% - 10% handling fee = 190%
    /// @param _winner winner address
    /// @param _tableNo table number
    /// @param _price player paid amount
    /// @param _autoplay automatically next game
    /// @return bool
    function giveWinnerBonus(
        address _winner,
        uint256 _tableNo,
        TablePrice _price,
        bool _autoplay
    ) private returns (bool) {
        uint256 priceWei = _transfromPriceAmount(_price);
        uint256 handlingFee = (priceWei / 10); //10% for handling fee
        uint256 amt;

        if (_autoplay) {
            //return 90% bonus when auto replay.
            amt = priceWei - handlingFee;
        } else {
            //return 190% bonus when final game.
            amt = (priceWei * 2) - handlingFee;
        }

        income += handlingFee;

        pendingWithdrawals[_winner].amount += amt;
        pendingWithdrawals[_winner].limitBlockNumber = block.number + 12; //can be withdrawls after 12 block

        emit LogGainBonus(
            _winner,
            GainReasonType.Winner,
            amt,
            _tableNo.toUint32(),
            address(0),
            _price
        );

        emit LogIncome(_winner, handlingFee);

        return true;
    }

    /// @notice assign trophy for introducer
    /// @param _player player address
    /// @return bool
    function giverIntTrophy(address _player, TablePrice _price) private returns (bool) {
        (address taker, address giver) = _assignIntroducerTrophy(_player, _price);

        //no one recive
        if (taker == address(0) || giver == address(0)) {
            return false;
        }

        emit LogGainTrophy(taker, giver, GainReasonType.Introducer);

        return true;
    }

    /// @notice assign trophy for replay
    /// @param _player downline's address
    /// @return bool
    function giveReplayTrophy(address _player, TablePrice _price) private returns (bool) {
        (address taker, address giver) = _assignReplayTrophy(_player, _price);

        //no one recive
        if (taker == address(0) || giver == address(0)) {
            return false;
        }

        emit LogGainTrophy(taker, giver, GainReasonType.Replay);

        return true;
    }

    //@notice emit player record event
    function EmitLogPlayer(
        address _player,
        PlayerEventState _state,
        uint256 _tableNo
    ) private {
        address uplien = getPlayerUpline(_player);

        emit LogPlayer(_player, uplien, _state, _tableNo.toUint32());
    }

    /// @notice player quit game
    /// @param _tableNo quit table no
    function quit(uint256 _tableNo) external {
        uint256 returnPrice = _quitTable(_tableNo, msg.sender);
        pendingWithdrawals[msg.sender].amount += returnPrice;
        pendingWithdrawals[msg.sender].limitBlockNumber = block.number + 12;

        EmitLogPlayer(msg.sender, PlayerEventState.QuitGame, _tableNo);
    }
}
