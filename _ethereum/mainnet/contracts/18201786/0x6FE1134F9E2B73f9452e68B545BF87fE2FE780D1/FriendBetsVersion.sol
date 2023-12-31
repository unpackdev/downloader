// SPDX-License-Identifier: MIT

/*
🎲 Bet on the key prices of your favorite twitter users

Twitter: https://twitter.com/friendbet_tech
Telegram: https://t.me/FriendBetPortal
Website: https://friendbet.tech/
Docs: https://docs.friendbet.tech/
*/
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract FriendTechBetting is ReentrancyGuard, Ownable {
    enum States {
        Open,
        Closed,
        Resolved
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               STORAGE                                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    IERC20 public xbetsToken;
    address public botAddress;
    uint256 public totalEarned;
    uint256 public totalVolume;
    uint256 public totalBetsPlayed;

    struct BetInfo {
        uint8 prediction;
        uint256 amount;
    }

    struct ReturnIdData {
        uint256 totalBet;
        BetInfo[] bets;
        RoundInfo round;
    }

    struct RoundInfo {
        address targetAddress;
        address otherAddress;
        States state;
        uint256 totalOther;
        uint256 totalTarget;
        uint256 winningOutcome;
        uint256 totalUsersOther;
        uint256 totalUsersTarget;
    }

    struct ReturnInfo {
        bytes32 id;
        States state;
        uint256 totalBet;
        uint8 prediction;
    }

    mapping(bytes32 => bool) public isOpen;
    mapping(bytes32 => bool) public isClosed;
    mapping(bytes32 => uint256) public latestVersion;
    mapping(uint256 => ReturnInfo[]) public openBets;
    mapping(uint256 => mapping(bytes32 => uint256)) public total;
    mapping(uint256 => mapping(bytes32 => RoundInfo)) public rounds;
    mapping(uint256 => mapping(bytes32 => address[])) public betUsers;
    mapping(address => mapping(address => bytes32)) public addressToId;
    mapping(uint256 => mapping(bytes32 => address[])) public roundBettors;
    mapping(uint256 => mapping(bytes32 => mapping(address => BetInfo)))
        public bets;

    bytes32[] public allIds;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               EVENTS                                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    event BetPlaced(
        bytes32 id,
        address indexed user,
        uint256 prediction,
        uint256 amount,
        uint256 version
    );
    event BetResolved(bytes32 id, uint256 winningOutcome, uint256 version);
    event Claimed(
        bytes32 id,
        address indexed user,
        uint256 amount,
        uint256 version
    );
    event BettingOpened(bytes32 id, uint256 version);
    event BettingClosed(bytes32 id, uint256 version);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               ERRORS                                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    error Bet_Closed();
    error Bet_InvalidId();
    error Bet_NotResolved();
    error Bet_InvalidState();
    error Bet_NotClaimable();
    error Bet_AmountToSmall();
    error Bet_InvalidAddress();
    error Bet_InvalidPrediction();
    error Bet_OnlyOnePrediction();
    error Bet_ContractInsufficientTokens();

    constructor(IERC20 _xbetsToken) {
        _initializeOwner(msg.sender);
        xbetsToken = _xbetsToken;
    }

    receive() external payable {}

    modifier onlyOwnerBot() {
        require(
            (msg.sender == owner()) || (msg.sender == botAddress),
            "Only Owner or Bot"
        );
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               PUBLIC NON-PAYABLE FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Function to place a bet on whether the price of a specific address will go up or down
     * @param _id The Id of the betting pool
     * @param _prediction The prediction made by the bettor (1 for Target, 2 for Other)
     * @param _amount The bet amount
     */
    function friendBet(
        bytes32 _id,
        uint8 _prediction,
        uint256 _amount
    ) public nonReentrant {
        if (_id == bytes32(0)) {
            revert Bet_InvalidId();
        }
        if (_prediction != 1 && _prediction != 2) {
            revert Bet_InvalidPrediction();
        }
        if (_amount < 1000 * 1e18) {
            revert Bet_AmountToSmall();
        }

        uint256 version = latestVersion[_id];

        RoundInfo storage _rounds = rounds[version][_id];
        BetInfo storage _bets = bets[version][_id][msg.sender];
        if (_rounds.state != States.Open) {
            revert Bet_Closed();
        }

        uint256 prediction = _bets.prediction;
        if (prediction != 0 && prediction != _prediction) {
            revert Bet_OnlyOnePrediction();
        }

        xbetsToken.transferFrom(msg.sender, address(this), _amount);

        totalBetsPlayed += 1;
        totalVolume += _amount;

        betUsers[version][_id].push(msg.sender);

        roundBettors[version][_id].push(msg.sender);

        _rounds.totalUsersTarget += _prediction == 1 ? 1 : 0;
        _rounds.totalUsersOther += _prediction == 2 ? 1 : 0;
        _rounds.totalTarget += _prediction == 1 ? _amount : 0;
        _rounds.totalOther += _prediction == 2 ? _amount : 0;

        _bets.prediction = _prediction;
        _bets.amount += _amount;

        total[version][_id] += _amount;

        emit BetPlaced(_id, msg.sender, _prediction, _amount, version);
    }

    /**
     * @notice Function to claim winnings for a specific bet on an address
     * @param _id The Id of the betting pool
     * @param _version The version of the betting pool to claim (default 0 to get latest)
     */
    function claimRewards(bytes32 _id, uint256 _version) public nonReentrant {
        if (_id == bytes32(0)) {
            revert Bet_InvalidId();
        }
        uint256 version = _version;
        if (version == 0) {
            version = latestVersion[_id];
        }
        if (rounds[version][_id].state != States.Resolved) {
            revert Bet_NotResolved();
        }

        BetInfo storage _bets = bets[version][_id][msg.sender];
        RoundInfo memory _rounds = rounds[version][_id];
        uint256 currentOutcome = _rounds.winningOutcome;
        uint256 totalCurrent = _rounds.winningOutcome == 1
            ? _rounds.totalTarget
            : _rounds.totalOther;

        if (_bets.prediction != currentOutcome) {
            revert Bet_NotClaimable();
        }
        uint256 amount = (_bets.amount * total[version][_id]) / totalCurrent;

        if (xbetsToken.balanceOf(address(this)) < amount) {
            revert Bet_ContractInsufficientTokens();
        }

        xbetsToken.transfer(msg.sender, amount);
        totalEarned += amount;
        _bets.amount = 0;
        _bets.prediction = 0;

        emit Claimed(_id, msg.sender, amount, version);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC VIEW FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Function to get the total bet amount for a particular outcome
     * @param _id The Id of the betting pool
     * @param _version The version to check
     * @param _outcome The outcome to check
     * @return The total bet amount for the outcome
     */
    function getTotalBetsForOutcome(
        bytes32 _id,
        uint256 _version,
        uint256 _outcome
    ) public view returns (uint256) {
        uint256 version = _version;
        if (version == 0) {
            version = latestVersion[_id];
        }
        RoundInfo memory _rounds = rounds[version][_id];
        uint256 totalCurrent = _outcome == 1
            ? _rounds.totalTarget
            : _rounds.totalOther;
        return totalCurrent;
    }

    /**
     * @notice Function to get the total bet amount a user has placed for a particular outcome
     * @param _user The user to check
     * @param _id The Id of the betting pool
     * @param _version The version to check
     * @param _outcome The outcome to check
     * @return The total bet amount the user has placed for the outcome
     */
    function getUserPredictionForOutcome(
        address _user,
        bytes32 _id,
        uint256 _version,
        uint8 _outcome
    ) public view returns (uint256) {
        uint256 version = _version;
        if (version == 0) {
            version = latestVersion[_id];
        }
        BetInfo memory _bets = bets[version][_id][_user];
        uint8 outcome = _bets.prediction;
        uint256 amount = _bets.amount;
        return _outcome == outcome ? amount : 0;
    }

    /**
     * @notice Function to get all outcomes a user has bet on
     * @param _user The address of the user
     * @param _id The Id of the betting pool
     * @param _version The version to check
     * @return An array of outcomes the user has bet on
     */
    function getUserOutcomes(
        address _user,
        bytes32 _id,
        uint256 _version
    ) public view returns (uint8) {
        uint256 version = _version;
        if (version == 0) {
            version = latestVersion[_id];
        }
        BetInfo memory _bets = bets[version][_id][_user];
        return _bets.prediction;
    }

    /**
     * @notice Function to get amount to claim for current version
     * @return amount The amount to claim
     * @param _id The Id of the betting pool
     * @param _version The version to check
     */
    function getAmountToClaim(
        bytes32 _id,
        uint256 _version
    ) public view returns (uint256) {
        uint256 version = _version;
        if (version == 0) {
            version = latestVersion[_id];
        }
        BetInfo memory _bets = bets[version][_id][msg.sender];
        RoundInfo memory _rounds = rounds[version][_id];
        uint256 totalCurrent = _rounds.winningOutcome == 1
            ? _rounds.totalTarget
            : _rounds.totalOther;
        if (_bets.prediction == _rounds.winningOutcome) {
            uint256 amount = (_bets.amount * total[version][_id]) /
                totalCurrent;

            return amount;
        }
        return 0;
    }

    /**
     * @notice Function to get amount to claim for current version
     * @return amount The amount to claim
     * @param _userAddress The user Address to check
     * @param _id The Id of the betting pool
     * @param _version The version to check
     */
    function getAmountToClaimUser(
        address _userAddress,
        bytes32 _id,
        uint256 _version
    ) public view returns (uint256) {
        uint256 version = _version;
        if (version == 0) {
            version = latestVersion[_id];
        }
        BetInfo memory _bets = bets[version][_id][_userAddress];
        RoundInfo memory _rounds = rounds[version][_id];
        uint256 totalCurrent = _rounds.winningOutcome == 1
            ? _rounds.totalTarget
            : _rounds.totalOther;
        if (_bets.prediction == _rounds.winningOutcome) {
            uint256 amount = (_bets.amount * total[version][_id]) /
                totalCurrent;

            return amount;
        }
        return 0;
    }

    /**
     * @notice Function to get a list of users by betting pool
     * @return ReturnInfo[] An array of ReturnInfo Structs with user betting information
     * @param _id The Id of the betting pool
     * @param _version The version to check
     */
    function getUsersBetList(
        bytes32 _id,
        uint256 _version
    ) public view returns (ReturnInfo[] memory) {
        uint256 version = _version;
        if (version == 0) {
            version = latestVersion[_id];
        }
        address[] memory bettors = roundBettors[version][_id];
        ReturnInfo[] memory returnInfoList = new ReturnInfo[](bettors.length);

        for (uint i = 0; i < bettors.length; i++) {
            address userAddress = bettors[i];
            BetInfo memory userBet = bets[version][_id][userAddress];
            RoundInfo memory roundInfo = rounds[version][_id];

            returnInfoList[i] = ReturnInfo({
                id: _id,
                state: roundInfo.state,
                totalBet: userBet.amount,
                prediction: userBet.prediction
            });
        }

        return returnInfoList;
    }

    /**
     * @notice Function to get total users for either outcome
     * @param _id The Id of the betting pool
     * @param _version The version to check
     * @return uint256 Total amount the user has bet on the outcome
     */
    function getTotalUserOutcome(
        bytes32 _id,
        uint256 _version,
        uint8 _outcome
    ) public view returns (uint256) {
        if (_outcome != 1 && _outcome != 2) {
            revert Bet_InvalidPrediction();
        }

        uint256 version = _version;
        if (version == 0) {
            version = latestVersion[_id];
        }

        RoundInfo memory _rounds = rounds[version][_id];
        return
            _outcome == 1 ? _rounds.totalUsersTarget : _rounds.totalUsersOther;
    }

    /**
     * @notice Function to get relevent data by id and version
     * @param _id The Id of the betting pool
     * @param _version The version to check
     * @return ReturnIdData Struct with all the data
     */
    function getBetData(
        bytes32 _id,
        uint256 _version
    ) public view returns (ReturnIdData memory) {
        uint256 version = _version;
        if (version == 0) {
            version = latestVersion[_id];
        }
        RoundInfo memory roundInfo = rounds[version][_id];
        address[] memory users = betUsers[version][_id];
        BetInfo[] memory betInfoList = new BetInfo[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            betInfoList[i] = bets[version][_id][users[i]];
        }

        uint256 totalBet = total[version][_id];

        return
            ReturnIdData({
                totalBet: totalBet,
                bets: betInfoList,
                round: roundInfo
            });
    }

    /**
     * @notice Function to get all open ids
     * @return bytes32[] Array with all ids
     */
    function getAllBets() public view returns (bytes32[] memory) {
        uint256 openCount = 0;
        for (uint256 i = 0; i < allIds.length; i++) {
            if (isOpen[allIds[i]]) {
                openCount++;
            }
        }

        bytes32[] memory openIds = new bytes32[](openCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allIds.length; i++) {
            if (isOpen[allIds[i]]) {
                openIds[index] = allIds[i];
                index++;
            }
        }
        return openIds;
    }

    /**
     * @notice Function to get all closed ids
     * @return bytes32[] Array with all ids
     */
    function getClosedBets() public view returns (bytes32[] memory) {
        uint256 closedCount = 0;
        for (uint256 i = 0; i < allIds.length; i++) {
            if (isClosed[allIds[i]]) {
                closedCount++;
            }
        }

        bytes32[] memory closedIds = new bytes32[](closedCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allIds.length; i++) {
            if (isClosed[allIds[i]]) {
                closedIds[index] = allIds[i];
                index++;
            }
        }
        return closedIds;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               EXTERNAL ONLY-OWNER FUNCTIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function setBotAddress(address _botAddress) external onlyOwner {
        botAddress = _botAddress;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               EXTERNAL ONLY-OWNERBOT FUNCTIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    /**
     * @notice Function to open betting
     * @param _targetAddress The target address to initialize
     * @param _otherAddress The target address to initialize
     */
    function openBetting(
        address _targetAddress,
        address _otherAddress
    ) external onlyOwnerBot {
        if (_targetAddress == address(0)) {
            revert Bet_InvalidAddress();
        }
        if (_otherAddress == address(0)) {
            revert Bet_InvalidAddress();
        }
        bytes32 id = addressToId[_targetAddress][_otherAddress];
        if (id == bytes32(0)) {
            id = keccak256(abi.encodePacked(_targetAddress, _otherAddress));
            allIds.push(id);
            addressToId[_targetAddress][_otherAddress] = id;
        }
        isClosed[id] = false;
        latestVersion[id] += 1;
        uint256 version = latestVersion[id];

        RoundInfo storage _rounds = rounds[version][id];
        _rounds.state = States.Open;
        isOpen[id] = true;
        _rounds.targetAddress = _targetAddress;
        _rounds.otherAddress = _otherAddress;
        emit BettingOpened(id, version);
    }

    /**
     * @notice Function to close betting and resolve
     * @param _id The Id of the betting pool
     */
    function closeBetting(bytes32 _id) external onlyOwnerBot {
        uint256 version = latestVersion[_id];
        RoundInfo storage _rounds = rounds[version][_id];
        if (_rounds.state != States.Open) {
            revert Bet_InvalidState();
        }
        _rounds.state = States.Closed;
        isOpen[_id] = false;
        isClosed[_id] = true;
        emit BettingClosed(_id, version);
    }

    /**
     * @notice Function to resolve a bet
     * @param _winningOutcome The winning outcome
     * @param _id The Id of the betting pool
     */
    function resolveBet(
        uint256 _winningOutcome,
        bytes32 _id
    ) external onlyOwnerBot {
        uint256 version = latestVersion[_id];
        RoundInfo storage _rounds = rounds[version][_id];
        if (_rounds.state != States.Closed) {
            revert Bet_InvalidState();
        }
        _rounds.state = States.Resolved;
        _rounds.winningOutcome = _winningOutcome;

        emit BetResolved(_id, _winningOutcome, version);
    }

    /**
     * @notice Function to withdraw Tokens Stuck in CA.
     * @param _recipient Address to receive the withdrawn Tokens
     * @param _amount Amount to withdraw
     */
    function withdrawStuckTokens(
        address _recipient,
        uint256 _amount
    ) external onlyOwner {
        xbetsToken.transfer(_recipient, _amount);
    }

    /**
     * @notice Function to withdraw contract Eth
     * @param _recipient Address to receive the withdrawn Eth
     */
    function withdraw(address _recipient) external onlyOwner {
        (bool success, ) = address(_recipient).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
