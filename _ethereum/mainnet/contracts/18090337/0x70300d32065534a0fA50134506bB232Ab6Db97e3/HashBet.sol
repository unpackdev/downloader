// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./VRFV2WrapperConsumerBase.sol";
import "./AggregatorV2V3Interface.sol";
import "./ChainSpecificUtil.sol";

contract HashBet is Ownable, ReentrancyGuard, VRFV2WrapperConsumerBase {
    // Modulo is the number of equiprobable outcomes in a game:
    //  2 for coin flip
    //  6 for dice roll
    //  6*6 = 36 for double dice
    //  37 for roulette
    //  100 for hashroll
    uint constant MAX_MODULO = 100;

    // Modulos below MAX_MASK_MODULO are checked against a bit mask, allowing betting on specific outcomes.
    // For example in a dice roll (modolo = 6),
    // 000001 mask means betting on 1. 000001 converted from binary to decimal becomes 1.
    // 101000 mask means betting on 4 and 6. 101000 converted from binary to decimal becomes 40.
    // The specific value is dictated by the fact that 256-bit intermediate
    // multiplication result allows implementing population count efficiently
    // for numbers that are up to 42 bits, and 40 is the highest multiple of
    // eight below 42.
    uint constant MAX_MASK_MODULO = 40;

    // EVM BLOCKHASH opcode can query no further than 256 blocks into the
    // past. Given that settleBet uses block hash of placeBet as one of
    // complementary entropy sources, we cannot process bets older than this
    // threshold. On rare occasions dice2.win croupier may fail to invoke
    // settleBet in this timespan due to technical issues or extreme Ethereum
    // congestion; such bets can be refunded via invoking refundBet.
    uint constant BET_EXPIRATION_BLOCKS = 250;

    // This is a check on bet mask overflow. Maximum mask is equivalent to number of possible binary outcomes for maximum modulo.
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

    // These are constants taht make O(1) population count in placeBet possible.
    uint constant POPCNT_MULT =
        0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK =
        0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;

    uint256 private constant GRACE_PERIOD_TIME = 3600;

    // Sum of all historical deposits and withdrawals. Used for calculating profitability. Profit = Balance - cumulativeDeposit + cumulativeWithdrawal
    uint public cumulativeDeposit;
    uint public cumulativeWithdrawal;

    // In addition to house edge, wealth tax is added every time the bet amount exceeds a multiple of a threshold.
    // For example, if wealthTaxIncrementThreshold = 3000 ether,
    // A bet amount of 3000 ether will have a wealth tax of 1% in addition to house edge.
    // A bet amount of 6000 ether will have a wealth tax of 2% in addition to house edge.
    uint public wealthTaxIncrementThreshold = 3000 ether;
    uint public wealthTaxIncrementPercent = 1;

    // The minimum and maximum bets.
    uint public minBetAmount = 0.01 ether;
    uint public maxBetAmount = 10000 ether;

    // max bet profit. Used to cap bets against dynamic odds.
    uint public maxProfit = 300000 ether;

    // Funds that are locked in potentially winning bets. Prevents contract from committing to new bets that it cannot pay out.
    uint public lockedInBets;

    // The minimum larger comparison value.
    uint public minOverValue = 1;

    // The maximum smaller comparison value.
    uint public maxUnderValue = 98;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 constant callbackGasLimit = 1000000;

    // The default is 3, but you can set this higher.
    uint16 constant requestConfirmations = 3;

    // retrieve 1 random value in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 constant numWords = 1;

    // Address LINK
    address linkAddress;

    //Data Feed: LINK/NATIVE TOKEN
    AggregatorV2V3Interface internal dataFeed;
    //L2 sequencer feeds
    AggregatorV2V3Interface internal sequencerUptimeFeed;

    // Info of each bet.
    struct Bet {
        // Wager amount in wei.
        uint amount;
        // Modulo of a game.
        uint8 modulo;
        // Number of winning outcomes, used to compute winning payment (* modulo/rollEdge),
        // and used instead of mask for games with modulo > MAX_MASK_MODULO.
        uint8 rollEdge;
        // Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
        uint40 mask;
        // Block number of placeBet tx.
        uint placeBlockNumber;
        // Address of a gambler, used to pay out winning bets.
        address payable gambler;
        // Status of bet settlement.
        bool isSettled;
        // Outcome of bet.
        uint outcome;
        // Win amount.
        uint winAmount;
        // Random number used to settle bet.
        uint randomNumber;
        // Comparison method.
        bool isLarger;
        // VRF request id
        uint256 requestID;
    }

    // Each bet is deducted
    uint public defaultHouseEdgePercent = 2;

    uint256 public requestCounter;
    mapping(uint256 => uint256) s_requestIDToRequestIndex;
    // bet place time
    mapping(uint256 => uint256) betPlaceTime;
    // bet data
    mapping(uint256 => Bet) public bets;

    mapping(uint32 => uint32) public houseEdgePercents;

    // Events
    event BetPlaced(
        address indexed gambler,
        uint amount,
        uint indexed betID,
        uint8 indexed modulo,
        uint8 rollEdge,
        uint40 mask,
        bool isLarger
    );
    event BetSettled(
        address indexed gambler,
        uint amount,
        uint indexed betID,
        uint8 indexed modulo,
        uint8 rollEdge,
        uint40 mask,
        uint outcome,
        uint winAmount
    );
    event BetRefunded(address indexed gambler, uint amount);

    error OnlyCoordinatorCanFulfill(address have, address want);
    error NotAwaitingVRF();
    error AwaitingVRF(uint256 requestID);
    error RefundFailed();
    error InvalidValue(uint256 required, uint256 sent);
    error TransferFailed();
    error SequencerDown();
    error GracePeriodNotOver();

    constructor(
        address _linkAddress,
        address _vrfV2Wrapper,
        address _dataFeed,
        address _sequencerUptimeFeed
    ) VRFV2WrapperConsumerBase(_linkAddress, _vrfV2Wrapper) {
        linkAddress = _linkAddress;
        dataFeed = AggregatorV2V3Interface(_dataFeed);
        sequencerUptimeFeed = AggregatorV2V3Interface(_sequencerUptimeFeed);
        houseEdgePercents[2] = 1;
        houseEdgePercents[6] = 1;
        houseEdgePercents[36] = 1;
        houseEdgePercents[37] = 3;
        houseEdgePercents[100] = 5;
    }

    // Fallback payable function used to top up the bank roll.
    fallback() external payable {
        cumulativeDeposit += msg.value;
    }

    receive() external payable {
        cumulativeDeposit += msg.value;
    }

    // See ETH balance.
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    // Owner can withdraw funds not exceeding balance minus potential win prizes by open bets
    function withdrawFunds(uint withdrawAmount) external onlyOwner {
        require(
            withdrawAmount <= address(this).balance,
            "Withdrawal amount larger than balance."
        );
        require(
            withdrawAmount <= address(this).balance - lockedInBets,
            "Withdrawal amount larger than balance minus lockedInBets"
        );
        address payable beneficiary = payable(msg.sender);
        beneficiary.transfer(withdrawAmount);
        cumulativeWithdrawal += withdrawAmount;
    }

    function emitBetPlacedEvent(
        address gambler,
        uint amount,
        uint betID,
        uint8 modulo,
        uint8 rollEdge,
        uint40 mask,
        bool isLarger
    ) private {
        // Record bet in event logs
        emit BetPlaced(
            gambler,
            amount,
            betID,
            uint8(modulo),
            uint8(rollEdge),
            uint40(mask),
            isLarger
        );
    }

    // Place bet
    function placeBet(
        uint betAmount,
        uint betMask,
        uint modulo,
        bool isLarger
    ) external payable nonReentrant {
        address msgSender = _msgSender();

        checkVRFFee(betAmount, tx.gasprice);

        validateArguments(betAmount, betMask, modulo);

        uint rollEdge;
        uint mask;

        if (modulo <= MAX_MASK_MODULO) {
            // Small modulo games can specify exact bet outcomes via bit mask.
            // rollEdge is a number of 1 bits in this mask (population count).
            // This magic looking formula is an efficient way to compute population
            // count on EVM for numbers below 2**40.
            rollEdge = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = betMask;
        } else {
            // Larger modulos games specify the right edge of half-open interval of winning bet outcomes.
            rollEdge = betMask;
        }

        // Winning amount.
        uint possibleWinAmount = getDiceWinAmount(
            betAmount,
            modulo,
            rollEdge,
            isLarger
        );

        // Check whether contract has enough funds to accept this bet.
        require(
            lockedInBets + possibleWinAmount <= address(this).balance,
            "Unable to accept bet due to insufficient funds"
        );

        uint256 requestID = _requestRandomWords();

        // Update lock funds.
        lockedInBets += possibleWinAmount;

        s_requestIDToRequestIndex[requestID] = requestCounter;
        betPlaceTime[requestCounter] = block.timestamp;
        bets[requestCounter] = Bet({
            amount: betAmount,
            modulo: uint8(modulo),
            rollEdge: uint8(rollEdge),
            mask: uint40(mask),
            placeBlockNumber: ChainSpecificUtil.getBlockNumber(),
            gambler: payable(msgSender),
            isSettled: false,
            outcome: 0,
            winAmount: possibleWinAmount,
            randomNumber: 0,
            isLarger: isLarger,
            requestID: requestID
        });

        // Record bet in event logs
        emitBetPlacedEvent(
            msgSender,
            betAmount,
            requestCounter,
            uint8(modulo),
            uint8(rollEdge),
            uint40(mask),
            isLarger
        );

        requestCounter += 1;
    }

    // Get the expected win amount after house edge is subtracted.
    function getDiceWinAmount(
        uint amount,
        uint modulo,
        uint rollEdge,
        bool isLarger
    ) private view returns (uint winAmount) {
        require(
            0 < rollEdge && rollEdge <= modulo,
            "Win probability out of range."
        );
        uint houseEdge = (amount *
            (getModuloHouseEdgePercent(uint32(modulo)) +
                getWealthTax(amount))) / 100;
        uint realRollEdge = rollEdge;
        if (modulo == MAX_MODULO && isLarger) {
            realRollEdge = MAX_MODULO - rollEdge - 1;
        }
        winAmount = ((amount - houseEdge) * modulo) / realRollEdge;

        // round down to multiple 1000Gweis
        winAmount = (winAmount / 1e12) * 1e12;

        uint maxWinAmount = amount + maxProfit;

        if (winAmount > maxWinAmount) {
            winAmount = maxWinAmount;
        }
    }

    // Get wealth tax
    function getWealthTax(uint amount) private view returns (uint wealthTax) {
        wealthTax =
            (amount / wealthTaxIncrementThreshold) *
            wealthTaxIncrementPercent;
    }

    // Common settlement code for settleBet.
    function settleBetCommon(
        Bet storage bet,
        uint reveal
    ) private {
        // Fetch bet parameters into local variables (to save gas).
        uint amount = bet.amount;

        // Validation check
        require(amount > 0, "Bet does not exist."); // Check that bet exists
        require(bet.isSettled == false, "Bet is settled already"); // Check that bet is not settled yet

        // Fetch bet parameters into local variables (to save gas).
        uint modulo = bet.modulo;
        uint rollEdge = bet.rollEdge;
        address payable gambler = bet.gambler;
        bool isLarger = bet.isLarger;

        // The RNG - combine "reveal" and blockhash of placeBet using Keccak256. Miners
        // are not aware of "reveal" and cannot deduce it from "commit" (as Keccak256
        // preimage is intractable), and house is unable to alter the "reveal" after
        // placeBet have been mined (as Keccak256 collision finding is also intractable).
        bytes32 entropy = keccak256(abi.encodePacked(reveal));

        // Do a roll by taking a modulo of entropy. Compute winning amount.
        uint outcome = uint(entropy) % modulo;

        // Win amount if gambler wins this bet
        uint possibleWinAmount = bet.winAmount;

        // Actual win amount by gambler
        uint winAmount = 0;

        // Determine dice outcome.
        if (modulo <= MAX_MASK_MODULO) {
            // For small modulo games, check the outcome against a bit mask.
            if ((2 ** outcome) & bet.mask != 0) {
                winAmount = possibleWinAmount;
            }
        } else {
            // For larger modulos, check inclusion into half-open interval.
            if (isLarger) {
                if (outcome > rollEdge) {
                    winAmount = possibleWinAmount;
                }
            } else {
                if (outcome < rollEdge) {
                    winAmount = possibleWinAmount;
                }
            }
        }

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        // Update bet records
        bet.isSettled = true;
        bet.winAmount = winAmount;
        bet.randomNumber = reveal;
        bet.outcome = outcome;

        // Send win amount to gambler.
        if (bet.winAmount > 0) {
            gambler.transfer(bet.winAmount);
        }

        emitSettledEvent(bet);
    }

    function emitSettledEvent(Bet storage bet) private {
        uint amount = bet.amount;
        uint outcome = bet.outcome;
        uint winAmount = bet.winAmount;
        // Fetch bet parameters into local variables (to save gas).
        uint modulo = bet.modulo;
        uint rollEdge = bet.rollEdge;
        address payable gambler = bet.gambler;
        // Record bet settlement in event log.
        emit BetSettled(
            gambler,
            amount,
            s_requestIDToRequestIndex[bet.requestID],
            uint8(modulo),
            uint8(rollEdge),
            bet.mask,
            outcome,
            winAmount
        );
    }

    // Return the bet in extremely unlikely scenario it was not settled by Chainlink VRF.
    // In case you ever find yourself in a situation like this, just contact hashbet support.
    // However, nothing precludes you from calling this method yourself.
    function refundBet(uint256 betID) external payable nonReentrant {
        Bet storage bet = bets[betID];
        uint amount = bet.amount;
        uint betTime = betPlaceTime[betID];

        // Validation check
        require(amount > 0, "Bet does not exist."); // Check that bet exists
        require(bet.isSettled == false, "Bet is settled already."); // Check that bet is still open
        require(
            block.timestamp >= (betTime + 1 hours),
            "Wait after placing bet before requesting refund."
        );

        uint possibleWinAmount = bet.winAmount;

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        // Update bet records
        bet.isSettled = true;
        bet.winAmount = amount;

        // Send the refund.
        bet.gambler.transfer(amount);

        // Record refund in event logs
        emit BetRefunded(bet.gambler, amount);

        delete (s_requestIDToRequestIndex[bet.requestID]);
        delete (betPlaceTime[betID]);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    /**
     * @dev calculates in form of native token the fee charged by chainlink VRF
     * @return VRFfee amount of fee user has to pay
     */
    function getVRFFee(uint gasPrice) public view returns (uint256 VRFfee) {
        uint link = VRF_V2_WRAPPER.estimateRequestPrice(
            callbackGasLimit,
            gasPrice
        );
        VRFfee = (link * uint256(getLatestData())) / 1e18;
    }

    // Check the sequencer status (L2 networks) and return the latest data
    function getLatestData() public view returns (int) {
        if (sequencerUptimeFeed != AggregatorV2V3Interface(address(0))) {
            // prettier-ignore
            (
                /*uint80 roundID*/,
                int256 answer,
                uint256 startedAt,
                /*uint256 updatedAt*/,
                /*uint80 answeredInRound*/
            ) = sequencerUptimeFeed.latestRoundData();

            // Answer == 0: Sequencer is up
            // Answer == 1: Sequencer is down
            bool isSequencerUp = answer == 0;
            if (!isSequencerUp) {
                revert SequencerDown();
            }

            // Make sure the grace period has passed after the
            // sequencer is back up.
            uint256 timeSinceUp = block.timestamp - startedAt;
            if (timeSinceUp <= GRACE_PERIOD_TIME) {
                revert GracePeriodNotOver();
            }
        }

        // prettier-ignore
        (
            uint80 roundID,
            int256 price,
            , 
            ,
            uint80 answeredInRound
        ) = dataFeed.latestRoundData();
        require(answeredInRound >= roundID, "Stale price");
        require(price > 0, "Invalid price");

        return price;
    }

    // Check arguments
    function validateArguments(
        uint amount,
        uint betMask,
        uint modulo
    ) private view {
        // Validate input data.
        require(
            modulo == 2 ||
                modulo == 6 ||
                modulo == 36 ||
                modulo == 37 ||
                modulo == 100,
            "Modulo should be valid value."
        );
        require(
            amount >= minBetAmount && amount <= maxBetAmount,
            "Bet amount should be within range."
        );

        if (modulo <= MAX_MASK_MODULO) {
            require(
                betMask > 0 && betMask < MAX_BET_MASK,
                "Mask should be within range."
            );
        }

        if (modulo == MAX_MODULO) {
            require(
                betMask >= minOverValue && betMask <= maxUnderValue,
                "High modulo range, Mask should be within range."
            );
        }
    }

    /**
     * @dev function to send the request for randomness to chainlink
     */
    function _requestRandomWords() internal returns (uint256 requestID) {
        requestID = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256 requestID,
        uint256[] memory randomWords
    ) internal override {
        uint256 betID = s_requestIDToRequestIndex[requestID];
        Bet storage bet = bets[betID];
        if (bet.gambler == address(0)) revert();
        uint placeBlockNumber = bet.placeBlockNumber;
        uint betTime = betPlaceTime[betID];

        // Settle bet must be within one hour
        require(
            block.timestamp < (betTime + 1 hours),
            "settleBet has expired."
        );

        // Check that bet has not expired yet (see comment to BET_EXPIRATION_BLOCKS).
        require(
            ChainSpecificUtil.getBlockNumber() > placeBlockNumber,
            "settleBet before placeBet"
        );

        // Settle bet using reveal and blockHash as entropy sources.
        settleBetCommon(
            bet,
            randomWords[0]
        );

        delete (s_requestIDToRequestIndex[requestID]);
        delete (betPlaceTime[betID]);
    }

    /**
     * @dev returns to user the excess fee sent to pay for the VRF
     * @param refund amount to send back to user
     */
    function refundExcessValue(uint256 refund) internal {
        if (refund == 0) {
            return;
        }
        (bool success, ) = payable(msg.sender).call{value: refund}("");
        if (!success) {
            revert RefundFailed();
        }
    }

    function checkVRFFee(uint betAmount, uint gasPrice) internal {
        uint256 VRFfee = getVRFFee(gasPrice);

        if (msg.value < betAmount + VRFfee) {
            revert InvalidValue(betAmount + VRFfee, msg.value);
        }
        refundExcessValue(msg.value - (VRFfee + betAmount));
    }

    function getModuloHouseEdgePercent(
        uint32 modulo
    ) internal view returns (uint32 houseEdgePercent) {
        houseEdgePercent = houseEdgePercents[modulo];
        if (houseEdgePercent == 0) {
            houseEdgePercent = uint32(defaultHouseEdgePercent);
        }
    }
}
