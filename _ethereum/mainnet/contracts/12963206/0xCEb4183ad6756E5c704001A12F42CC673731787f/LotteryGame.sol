// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./provableAPI_0.6.sol";
import "./ILotteryGame.sol";
import "./ILotteryToken.sol";

contract LotteryGame is
    ILotteryGame,
    OwnableUpgradeSafe,
    usingProvable,
    ReentrancyGuardUpgradeSafe
{
    using SafeMath for uint256;
    using Address for address;

    ILotteryToken public lotteryToken;

    uint256 public participationFee;

    string public oracleIpfsHash;
    uint256 public provableGasLimit;

    address public marketingFeeCollector;
    uint256 public marketingFeePercents;
    uint256 public marketingFeeDivider;

    bytes32 internal oraclizeCallbackId;

    uint256 public gameDuration;
    uint256 public firstTimelock;
    bool public stateKey;

    uint256 internal restartTimelock;
    uint256 public provableLimitUnder;
    mapping(bytes32 => address) internal validIds;
    bytes32[] internal oraclizeIds;

    event MarketingFeePaid(address feeCollector, uint256 amount);
    event GameStarted(uint256 id, uint256 startedAt);
    event GameFinished(
        uint256 id,
        uint256 startedAt,
        uint256 finishedAt,
        uint256 participants,
        address winner,
        uint256 participationFee,
        uint256 winningPrize
    );

    function initialize(
        address _lotteryToken,
        address _marketingFeeCollector,
        uint256 _participationFee
    ) public initializer {
        lotteryToken = ILotteryToken(_lotteryToken);

        marketingFeeCollector = _marketingFeeCollector;
        marketingFeePercents = 2000;
        marketingFeeDivider = 100000;

        provableGasLimit = 400000;

        participationFee = _participationFee;

        __ReentrancyGuard_init();
        __Ownable_init();
    }

    function setOracleIpfsHash(string memory _hash) public onlyOwner {
        oracleIpfsHash = _hash;
    }

    function setParticipationFee(uint256 _participationFee) public onlyOwner {
        participationFee = _participationFee;
    }

    function setMarketingFeePercents(uint256 _amount) public onlyOwner {
        require(
            _amount < marketingFeeDivider,
            "Marketing fee cannot be bigger than 100%"
        );
        marketingFeePercents = _amount;
    }

    function setGameDuration(uint256 _gameDuration, uint256 _firstTimelock)
        public
        onlyOwner
    {
        gameDuration = _gameDuration;
        firstTimelock = _firstTimelock;
    }

    function lockTransfer() public override onlyOwner {
        lotteryToken.lockTransfer();
    }

    function unlockTransfer() public override onlyOwner {
        lotteryToken.unlockTransfer();
    }

    function startGame(uint256 _gasPrice, uint256 _provableGasLimit)
        public
        payable
        override
        nonReentrant
    {
        require(
            _gasPrice >= tx.gasprice && _provableGasLimit >= provableLimitUnder,
            "Invalid gas price or gas limit"
        );
        provableGasLimit = _provableGasLimit;
        provable_setCustomGasPrice(_gasPrice);

        ILotteryToken.Lottery memory lastLotteryGame =
            lotteryToken.lastLottery();

        if (lastLotteryGame.id > 0) {
            require(
                block.timestamp >= firstTimelock &&
                    block.timestamp <= firstTimelock + gameDuration &&
                    lastLotteryGame.startedAt < firstTimelock,
                "The game is not ready to start!"
            );
            stateKey = !stateKey;
        }

        ILotteryToken.Lottery memory startedLotteryGame =
            lotteryToken.startLottery(participationFee);

        marketingFeeCollector = msg.sender;
        emit GameStarted(startedLotteryGame.id, block.timestamp);

        _callProvable_query(startedLotteryGame.id);
        restartTimelock = block.timestamp + 10 minutes;
        msg.sender.call{value: address(this).balance}("");
    }

    function restartProvableQuery(uint256 _gasPrice, uint256 _provableGasLimit)
        public
        payable
        override
        nonReentrant
    {
        require(
            _gasPrice >= tx.gasprice && _provableGasLimit >= provableLimitUnder,
            "Invalid gas price or gas limit"
        );
        provableGasLimit = _provableGasLimit;
        provable_setCustomGasPrice(_gasPrice);

        ILotteryToken.Lottery memory lastLotteryGame =
            lotteryToken.lastLottery();

        require(
            lastLotteryGame.finishedAt == 0,
            "Can be invoked only when the last game not finished"
        );

        require(block.timestamp > restartTimelock);
        restartTimelock = block.timestamp + 10 minutes;

        _callProvable_query(lastLotteryGame.id);

        msg.sender.call{value: address(this).balance}("");
    }

    function _callProvable_query(uint256 _id) internal {
        require(
            provable_getPrice("computation", provableGasLimit) <
                address(this).balance,
            "Provable query was NOT sent, please add some ETH to cover for the query fee"
        );

        lotteryToken.lockTransfer();

        oraclizeCallbackId = provable_query(
            "computation",
            [oracleIpfsHash, toAsciiString(address(this)), uint2str(_id)],
            provableGasLimit
        );
        validIds[oraclizeCallbackId] = msg.sender;
        oraclizeIds.push(oraclizeCallbackId);
    }

    function __callback(bytes32 _queryId, string memory _result)
        public
        override
    {
        require(
            isProvableCallback(_queryId),
            "Allowed to be invoked only by Provable"
        );
        ILotteryToken.Lottery memory lastLotteryGame =
            lotteryToken.lastLottery();

        address winner = parseAddr(string(abi.encodePacked("0x", _result)));
        int256 separatorIndex = indexOf(_result, "|");

        uint256 eligibleParticipants =
            safeParseInt(substring(_result, 41, uint256(separatorIndex)));
        _result = substring(
            _result,
            uint256(separatorIndex) + 1,
            bytes(_result).length
        );
        separatorIndex = indexOf(_result, "|");
        uint256 gameId =
            safeParseInt(substring(_result, 0, uint256(separatorIndex)));
        _result = substring(
            _result,
            uint256(separatorIndex) + 1,
            bytes(_result).length
        );
        separatorIndex = indexOf(_result, "|");
        participationFee = safeParseInt(
            substring(_result, 0, uint256(separatorIndex))
        );
        firstTimelock = safeParseInt(
            substring(
                _result,
                uint256(separatorIndex) + 1,
                bytes(_result).length
            )
        );

        require(lastLotteryGame.id == gameId, "Unexpected game id");

        require(lastLotteryGame.isActive, "Game is not active");

        uint256 totalWinningPrize =
            lastLotteryGame.participationFee.mul(eligibleParticipants);
        uint256 marketingFee =
            totalWinningPrize.mul(marketingFeePercents).div(
                marketingFeeDivider
            );
        uint256 winningPrizeExludingFees = totalWinningPrize.sub(marketingFee);
        address rewardReciever = validIds[_queryId];
        ILotteryToken.Lottery memory finishedLotteryGame =
            lotteryToken.finishLottery(
                eligibleParticipants,
                winner,
                rewardReciever,
                winningPrizeExludingFees,
                marketingFee
            );

        lotteryToken.unlockTransfer();

        emit GameFinished(
            finishedLotteryGame.id,
            finishedLotteryGame.startedAt,
            finishedLotteryGame.finishedAt,
            finishedLotteryGame.participants,
            finishedLotteryGame.winner,
            finishedLotteryGame.participationFee,
            finishedLotteryGame.winningPrize
        );
        for (uint256 i = 0; i < oraclizeIds.length; i++) {
            validIds[oraclizeIds[i]] = address(0);
        }
        delete oraclizeIds;
        provableLimitUnder = provableGasLimit.sub(gasleft()).add(50000);
    }

    function toAsciiString(address _addr) public pure returns (string memory) {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(_addr) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i + 2] = char(hi);
            s[2 * i + 3] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function isProvableCallback(bytes32 _queryId)
        internal
        virtual
        returns (bool)
    {
        return
            msg.sender == provable_cbAddress() &&
            validIds[_queryId] != address(0);
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}
