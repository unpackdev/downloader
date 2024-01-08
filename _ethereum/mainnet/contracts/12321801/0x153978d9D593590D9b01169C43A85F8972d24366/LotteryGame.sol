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

contract LotteryGame is ILotteryGame, OwnableUpgradeSafe, usingProvable, ReentrancyGuardUpgradeSafe {
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

    function setProvableGasLimit(uint256 _amount) public onlyOwner {
        provableGasLimit = _amount;
    }

    function setParticipationFee(uint256 _participationFee) public onlyOwner {
        require(participationFee != _participationFee, "new participation fee is same");

        participationFee = _participationFee;
    }

    function setMarketingFeePercents(uint256 _amount) public onlyOwner {
        require(_amount < marketingFeeDivider, "Marketing fee cannot be bigger than 100%");
        marketingFeePercents = _amount;
    }

    function setGameDuration(uint256 _gameDuration, uint256 _firstTimelock) public onlyOwner {
        gameDuration = _gameDuration;
        firstTimelock = _firstTimelock;
    }
    
    function lockTransfer() override public onlyOwner {
        lotteryToken.lockTransfer();
    }

    function unlockTransfer() override public onlyOwner {
        lotteryToken.unlockTransfer();
    }

    function setGasPrice(uint256 _gasPrice) public onlyOwner returns (bool) {
        provable_setCustomGasPrice(_gasPrice);
        return true;
    }

    function startGame() public payable override nonReentrant {

        ILotteryToken.Lottery memory lastLotteryGame =
            lotteryToken.lastLottery();

        uint256 secondsOver = block.timestamp.sub(lastLotteryGame.startedAt);

        if (lastLotteryGame.id > 0) {
            require(
                stateKey 
                    ? secondsOver >= gameDuration
                    : secondsOver >= firstTimelock,
                "The game is not ready to start, it can't be started since the previous game still running"
            );            
            stateKey = !stateKey;
        }

        ILotteryToken.Lottery memory startedLotteryGame =
            lotteryToken.startLottery(participationFee);

        emit GameStarted(startedLotteryGame.id, block.timestamp);

        _callProvable_query(startedLotteryGame.id);

        msg.sender.transfer(address(this).balance);
    }

    function restartProvableQuery()
        public
        payable
        override
        onlyOwner
        nonReentrant
    {
        ILotteryToken.Lottery memory lastLotteryGame =
            lotteryToken.lastLottery();

        require(
            lastLotteryGame.finishedAt == 0,
            "Can be invoked only when the last game not finished"
        );
        uint256 secondsOver = block.timestamp.sub(lastLotteryGame.startedAt);

        if (lastLotteryGame.id > 0) {
            require(
                stateKey 
                    ? secondsOver <= gameDuration
                    : secondsOver <= firstTimelock,
                "Can be invoked only before the next game will be ready to start"
            );            
        }

        _callProvable_query(lastLotteryGame.id);

        msg.sender.transfer(address(this).balance);
    }

    function _callProvable_query(uint256 _id) internal {
        require(
            provable_getPrice("computation", provableGasLimit) < address(this).balance,
            "Provable query was NOT sent, please add some ETH to cover for the query fee"
        );

        lotteryToken.lockTransfer();

        oraclizeCallbackId = provable_query(
            "computation",
            [
                oracleIpfsHash,
                toAsciiString(address(this)),
                uint2str(_id)
            ],
            provableGasLimit
        );
    } 

    function __callback(
        bytes32 _queryId,
        string memory _result
    ) public override {
        require(isProvableCallback(_queryId), "Allowed to be invoked only by Provable");

        ILotteryToken.Lottery memory lastLotteryGame = lotteryToken.lastLottery();

        address winner = parseAddr(string(abi.encodePacked('0x', _result)));
        int256 separatorIndex = indexOf(_result, "|");

        require(separatorIndex > -1, "Callback from Provable has incorrect format");
        
        string memory eligibleParticipantsStr = substring(_result, 41, uint256(separatorIndex));
        string memory gameIdStr = substring(_result, uint256(separatorIndex) + 1, bytes(_result).length);
        uint256 eligibleParticipants = safeParseInt(eligibleParticipantsStr);
        uint256 gameId = safeParseInt(gameIdStr);

        require(lastLotteryGame.id == gameId, "Unexpected game id, is this game running in parallel");

        require(lastLotteryGame.isActive, "Game is not active");

        uint256 totalWinningPrize = lastLotteryGame.participationFee.mul(eligibleParticipants);
        uint256 marketingFee = totalWinningPrize.mul(marketingFeePercents).div(marketingFeeDivider);
        uint256 winningPrizeExludingFees = totalWinningPrize.sub(marketingFee);

        ILotteryToken.Lottery memory finishedLotteryGame = lotteryToken.finishLottery(
            eligibleParticipants,
            winner,
            marketingFeeCollector,
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
    }

    function toAsciiString(address _addr) public pure returns (string memory) {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(_addr) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i+2] = char(hi);
            s[2*i+3] = char(lo);            
        }
        return string(s);
    }

    function char(byte b) internal pure returns (byte c) {
        if (uint8(b) < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }

    function isProvableCallback(bytes32 _queryId) internal virtual returns (bool) {
        return msg.sender == provable_cbAddress() && _queryId == oraclizeCallbackId;
    }

    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
}