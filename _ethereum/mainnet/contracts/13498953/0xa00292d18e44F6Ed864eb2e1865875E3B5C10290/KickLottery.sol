// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./IERC1363Receiver.sol";
import "./ERC1363.sol";
import "./IERC20Burnable.sol";

contract KickLottery is Ownable, IERC1363Receiver {
    struct LotteryRound {
        uint256 endBlock;
        address[] members;
        mapping(address => uint256) balances;
        address[] winners;
        uint256 jackpot;
        bytes32 hash;
    }
    LotteryRound[] public history;
    uint256 public roundNumber;

    IERC20Burnable public immutable token;

    uint8 public payPercent;
    uint8 public burnPercent;
    uint256 public playPeriodBlocks;
    uint256 public minBidValue;
    uint256 public constant RND_BASE = uint256(10e9); // Base of randomizer
    uint256 public maxMembers = 1000;
    uint256 public constant MAX_WINNERS = 100;

    bool public active = true;

    event BetAccepted(address account, uint256 value);
    event RoundFinalized(address[] winners, uint256 prize, uint256 roundNumber);
    event HashSaved(bytes32 hash, uint256 roundNumber);
    event PayPercentChanged(uint8 value);
    event BurnPercentChanged(uint8 value);
    event PlayPeriodBlocksChanged(uint256 value);
    event MinBidValueChanged(uint256 value);
    event MaxMembersChanged(uint256 value);

    modifier isActive() {
        require(active, "Lottery is not active");
        _;
    }

    constructor(
        address _token,
        uint256 _playPeriodBlock,
        uint8 _payPercent,
        uint8 _burnPercent,
        uint256 _minBidValue
    ) {
        token = IERC20Burnable(_token);
        playPeriodBlocks = _playPeriodBlock;
        require(_payPercent + _burnPercent <= 100, "Not valid percents");
        payPercent = _payPercent;
        burnPercent = _burnPercent;
        minBidValue = _minBidValue;
        createRound();
    }

    // create round logic -----------------------------------------------------
    // ------------------------------------------------------------------------

    function createRound() private isActive {
        LotteryRound storage round = history.push();
        round.endBlock = block.number + playPeriodBlocks;
    }

    // join logic -------------------------------------------------------------
    // ------------------------------------------------------------------------

    function isRoundFinished() public view returns (bool) {
        LotteryRound storage round = history[roundNumber];
        return block.number > round.endBlock;
    }

    function _join(address user, uint256 amount) private {
        LotteryRound storage round = history[roundNumber];

        require(round.members.length < maxMembers, "Too many members");

        if (round.balances[user] == 0) {
            round.members.push(user);
        }
        round.balances[user] += amount;

        emit BetAccepted(user, amount);
    }

    function join(uint256 amount) public isActive {
        require(!isRoundFinished(), "Current round is finished");
        // redundant in case KICKV8: minBid > totalSupply/RND_BASE
        // require(amount >= jackpot()/RND_BASE, "Amount less than jackpot/RND_BASE");
        require(amount >= minBidValue, "Amount less than minBid");

        // burning and distribution of token transfer is not accounted
        // amount = sendAmount + burnAmount + distributionAmount
        // so user's chances a bit more than sendAmount/jackpot in case KICKV8
        _join(msg.sender, amount);

        token.transferFrom(msg.sender, address(this), amount);
    }

    function onTransferReceived(
        address,
        address user,
        uint256 amount,
        bytes memory
    ) public override isActive returns (bytes4) {
        require(msg.sender == address(token), "Call can do only token");
        require(!isRoundFinished(), "Current round is finished");
        // redundant in case KICKV8: minBid > totalSupply/RND_BASE
        // require(amount >= jackpot()/RND_BASE, "Amount less than jackpot/RND_BASE");
        require(amount >= minBidValue, "Amount less than minBid");

        // burning and distribution of token transfer is not accounted
        // amount = sendAmount + burnAmount + distributionAmount
        // so user's chances a bit more than sendAmount/jackpot in case KICKV8
        _join(user, amount);

        return this.onTransferReceived.selector;
    }

    // finish round logic -----------------------------------------------------
    // ------------------------------------------------------------------------

    function saveRoundHash() external isActive {
        LotteryRound storage round = history[roundNumber];
        require(round.hash == bytes32(0), "Hash already saved");
        require(block.number > round.endBlock, "Current round is not finished");
        bytes32 bhash = blockhash(round.endBlock);
        require(bhash != bytes32(0), "Too far from end round block");

        round.hash = bhash;
        emit HashSaved(bhash, roundNumber);
    }

    function _checkWinners(
        LotteryRound storage round,
        bytes32 _hash,
        uint256 _jackpot
    ) private view isActive returns (address[] memory) {
        uint256 rnd = uint256(_hash);

        address[] memory winners = new address[](round.members.length);
        uint256 winnerNumber;
        for (uint256 i = 0; i < round.members.length; i++) {
            address userAddr = round.members[i];
            uint256 userRnd = (uint256(uint160(userAddr)) + rnd) % RND_BASE;
            uint256 betAmount = round.balances[round.members[i]];
            // win percent is betAmount / jackpot
            bool isWinner = userRnd < (betAmount * RND_BASE) / _jackpot;

            if (isWinner) {
                winners[winnerNumber] = userAddr;
                winnerNumber += 1;
            }
        }

        address[] memory realWinners = new address[](winnerNumber);
        if (winnerNumber > MAX_WINNERS) {
            winnerNumber = MAX_WINNERS;
        }
        for (uint256 i = 0; i < winnerNumber; i++) {
            realWinners[i] = winners[i];
        }
        return realWinners;
    }

    function checkWinners(uint256 _roundNumber, bytes32 _hash)
        external
        view
        returns (address[] memory, uint256)
    {
        require(_roundNumber == roundNumber, "Incorrect round number");
        require(_hash != bytes32(0), "Empty hash");

        LotteryRound storage round = history[_roundNumber];
        require(block.number > round.endBlock, "Round is not finished");

        if (round.hash != bytes32(0)) {
            require(_hash == round.hash, "Incorrect block hash");
        }
        bytes32 bhash = blockhash(round.endBlock);
        if (bhash != bytes32(0)) {
            require(_hash == bhash, "Incorrect block hash");
        }

        return (_checkWinners(round, _hash, jackpot()), jackpot());
    }

    function _payPrize(address[] memory winners, uint256 _jackpot)
        private
        returns (uint256)
    {
        uint256 prize = (_jackpot * payPercent) / 100 / winners.length;
        for (uint256 i = 0; i < winners.length; i++) {
            token.transfer(winners[i], prize);
        }
        token.burn((_jackpot * burnPercent) / 100);
        return prize;
    }

    function finalizeRound() external isActive {
        LotteryRound storage round = history[roundNumber];
        require(block.number > round.endBlock, "Current round is not finished");

        if (round.hash == bytes32(0)) {
            bytes32 bhash = blockhash(round.endBlock);
            require(bhash != bytes32(0), "Too far from end round block");
            round.hash = bhash;
            emit HashSaved(bhash, roundNumber);
        }

        round.jackpot = jackpot();
        address[] memory winners = _checkWinners(
            round,
            round.hash,
            round.jackpot
        );

        roundNumber++;
        createRound();

        uint256 prize;
        if (winners.length > 0) {
            round.winners = winners;
            prize = _payPrize(winners, round.jackpot);
        }

        emit RoundFinalized(winners, prize, roundNumber);
    }

    function finalizeRoundAdmin(
        uint256 _roundNumber,
        bytes32 _hash,
        address[] memory winners,
        uint256 _jackpot
    ) external onlyOwner isActive {
        require(_roundNumber == roundNumber, "Incorrect round number");
        uint256 curJackpot = jackpot();
        require(
            curJackpot / 2 <= _jackpot && _jackpot <= curJackpot,
            "Incorrect jackpot value"
        );

        LotteryRound storage round = history[roundNumber];
        require(block.number > round.endBlock, "Current round is not finished");

        bytes32 rhash = round.hash;
        if (rhash == bytes32(0)) {
            bytes32 bhash = blockhash(round.endBlock);
            if (bhash != bytes32(0)) {
                rhash = bhash;
            } else {
                rhash = _hash;
            }
            round.hash = rhash;
            emit HashSaved(rhash, roundNumber);
        }
        require(rhash == _hash, "Incorrect block hash");

        round.jackpot = _jackpot;
        uint256 prize;
        if (winners.length > 0) {
            round.winners = winners;
            prize = _payPrize(winners, _jackpot);
        }

        emit RoundFinalized(winners, prize, roundNumber);

        roundNumber++;
        createRound();
    }

    function challengeRound(uint256 _roundNumber) external isActive {
        if (!challengeRoundView(_roundNumber, bytes32(0))) {
            _kill(msg.sender);
        }
    }

    function challengeRoundView(uint256 _roundNumber, bytes32 _hash)
        public
        view
        returns (bool)
    {
        require(
            _roundNumber < roundNumber,
            "Can't challenge unfinalized round"
        );

        LotteryRound storage round = history[_roundNumber];

        if (_hash == bytes32(0)) {
            _hash = round.hash;
        }

        address[] memory realWinners = _checkWinners(
            round,
            _hash,
            round.jackpot
        );

        if (realWinners.length != round.winners.length) {
            return false;
        }

        for (uint256 i = 0; i < round.winners.length; i++) {
            if (realWinners[i] != round.winners[i]) {
                return false;
            }
        }
        return true;
    }

    // setters ----------------------------------------------------------------
    // ------------------------------------------------------------------------

    function setPlayPeriodBlocks(uint256 value) external onlyOwner {
        require(value > 0, "wrong playPeriodBlock");
        playPeriodBlocks = value;
        emit PlayPeriodBlocksChanged(value);
    }

    function setPayPercent(uint8 value) external onlyOwner {
        require(value + burnPercent <= 100, "Not valid percents");
        payPercent = value;
        emit PayPercentChanged(value);
    }

    function setBurnPercent(uint8 value) external onlyOwner {
        require(value + payPercent <= 100, "Not valid percents");
        burnPercent = value;
        emit BurnPercentChanged(value);
    }

    function setMinBidValue(uint256 value) external onlyOwner {
        require(value > 0, "Not valid minBidValue");
        minBidValue = value;
        emit MinBidValueChanged(value);
    }

    function setMaxMembers(uint256 value) external onlyOwner {
        require(value > 0, "Not valid maxMemebers");
        maxMembers = value;
        emit MaxMembersChanged(value);
    }

    // getters ----------------------------------------------------------------
    // ------------------------------------------------------------------------

    function roundWinners(uint256 _roundNumber)
        external
        view
        returns (address[] memory)
    {
        require(_roundNumber < history.length - 1, "Not valid round number");
        return history[_roundNumber].winners;
    }

    function roundMembers(uint256 _roundNumber)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        require(_roundNumber < history.length, "Not valid round number");

        LotteryRound storage round = history[_roundNumber];
        uint256[] memory balances = new uint256[](round.members.length);
        for (uint256 i = 0; i < round.members.length; i++) {
            balances[i] = round.balances[round.members[i]];
        }
        return (round.members, balances);
    }

    function memberBet(uint256 _roundNumber, address member)
        external
        view
        returns (uint256)
    {
        require(_roundNumber < history.length, "Not valid round number");
        return history[_roundNumber].balances[member];
    }

    function jackpot() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function totalPlayedJackpot() external view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < roundNumber; i++) {
            LotteryRound storage round = history[i];
            if (round.winners.length > 0) {
                total += history[i].jackpot;
            }
        }
        return total;
    }

    function memberBetHistory(address member) 
        external 
        view 
        returns (uint256[] memory, uint256[] memory, uint256[] memory) 
    {
        uint256 count;
        for (uint256 i = 0; i < roundNumber; i++) {
            LotteryRound storage round = history[i];
            if (round.balances[member] > 0) {
                count++;
            }
        }

        uint256[] memory rounds = new uint256[](count);
        uint256[] memory bets = new uint256[](count);
        uint256[] memory results = new uint256[](count);
        uint256 j;
        for (uint256 i = 0; i < roundNumber; i++) {
            LotteryRound storage round = history[i];
            if (round.balances[member] > 0) {
                rounds[j] = i;
                bets[j] = round.balances[member];
                results[j] = 0;
                for (uint256 k = 0; k < round.winners.length; k++) {
                    if (round.winners[k] == member) {
                        results[j] = (round.jackpot * payPercent) / 100 / round.winners.length;
                    }
                }
                j++;
            }
        }
        return (rounds, bets, results);
    }

    // kill lottery logic -----------------------------------------------------
    // ------------------------------------------------------------------------

    function _kill(address to) private {
        active = false;
        token.transfer(to, token.balanceOf(address(this)));
    }

    function kill(address to) external onlyOwner isActive {
        _kill(to);
    }

    // stuck funds ------------------------------------------------------------
    // ------------------------------------------------------------------------

    function stuckFundsTransfer(
        address _token,
        address to,
        uint256 amount
    ) external onlyOwner returns (bool) {
        require(_token != address(token), "Can't withdraw lottery token");
        return IERC20(_token).transfer(to, amount);
    }
}
