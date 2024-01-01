// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.18;

import "./Owned.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";
import "./IHotWheels.sol";

// Errors
error NoActiveRace();
error ActiveRace();
error RaceDataMismatch();
error BettingStillActive();
error AlreadyPlacedBet();
error AlreadyClaimed();
error DidntParticipate();
error DidntWin();
error InvalidLane();
error MissingTokenApproval();
error NotEnoughTokens();
error BettingEndedAlready();
error InvalidRaceId();
error InvalidToken();
error InvalidHouse();
error NotEnoughInPool();

// Data structures
struct BetData {
    bool claimed;
    uint8 lane;
    uint256 amount;
}

struct RaceData {
    bool active;
    bool bettingActive;
    bool houseWithdrew;
    uint8 winningLane;
    uint256 totalBet;
}

contract RaceManager is Owned {
    // Constants
    IHotWheels public immutable token;
    address public immutable house;

    // Race data
    uint32 public currentRace = 0;
    uint32 public lastRace = 0;
    RaceData[] public raceData;

    // Betting data
    mapping(uint32 => mapping(address => BetData)) public betData;
    mapping(uint32 => address[]) public bettors;
    mapping(address => uint32) public totalBetsMade;
    mapping(uint32 => mapping(uint8 => uint256)) public betPerRacePerLane;

    // Winnings data
    uint256 public totalAmountWon = 0;

    // Events
    event RaceStarted(uint32 raceId);
    event BetAdded(uint32 raceId, address addr, uint8 lane, uint256 amount);
    event BettingEnded(uint32 raceId);
    event RaceEnded(uint32 raceId, uint8 winningLane);

    // Modifiers
    modifier needsActiveRace() {
        if (currentRace == 0) revert NoActiveRace();
        _;
    }

    modifier noActiveRace() {
        if (currentRace > 0) revert ActiveRace();
        _;
    }

    // Functionality
    constructor(address tokenContract, address houseWallet) Owned(msg.sender) {
        if (tokenContract == address(0x0)) revert InvalidToken();
        if (houseWallet == address(0x0)) revert InvalidHouse();

        // Initialize bettors to fix slither uninitialized-state
        bettors[0] = [address(0)];

        token = IHotWheels(payable(tokenContract));
        house = houseWallet;
    }

    receive() external payable {}
    fallback() external payable {}

    function betRace(uint8 lane, uint256 amount) external needsActiveRace {
        if (token.balanceOf(msg.sender) < amount) revert NotEnoughTokens();
        if (token.allowance(msg.sender, address(this)) < amount) revert MissingTokenApproval();
        if (lane == 0 || lane > 6) revert InvalidLane();

        address bettor = msg.sender;
        uint32 raceId = currentRace;

        address[] storage raceBettors = bettors[raceId - 1];
        BetData storage data = betData[raceId - 1][bettor];
        RaceData storage race = raceData[raceId - 1];

        if (!race.bettingActive) revert BettingEndedAlready();
        if (data.lane > 0 || data.amount > 0) revert AlreadyPlacedBet();

        betData[raceId - 1][bettor] = BetData(false, lane, amount);
        betPerRacePerLane[raceId - 1][lane] += amount;
        race.totalBet += amount;

        totalBetsMade[msg.sender] += 1;
        raceBettors.push(msg.sender);

        SafeTransferLib.safeTransferFrom(ERC20(address(token)), bettor, address(this), amount);

        emit BetAdded(raceId, bettor, lane, amount);
    }

    function claimWinnings(uint32 raceId) public {
        if (raceId > raceData.length) revert InvalidRaceId();

        address bettor = msg.sender;
        BetData storage data = betData[raceId - 1][bettor];
        RaceData storage race = raceData[raceId - 1];

        uint8 lane = data.lane;

        if (data.claimed) revert AlreadyClaimed();
        if (data.amount == 0) revert DidntParticipate();
        if (data.lane != race.winningLane) revert DidntWin();

        data.claimed = true;

        uint256 totalWinBet = betPerRacePerLane[raceId - 1][lane];
        uint256 totalLoseBet = 0;
        for (uint8 otherLane = 1; otherLane <= 6; otherLane++) {
            if (otherLane == lane) continue;

            totalLoseBet += betPerRacePerLane[raceId - 1][otherLane];
        }

        uint256 winnings = _calculateWinnings(data.amount, totalLoseBet, totalWinBet);

        // This only triggers costly-loop warning if called from claimAllWinnings
        //slither-disable-next-line costly-loop
        totalAmountWon += winnings;

        // pay out tokens for race
        SafeTransferLib.safeTransfer(ERC20(address(token)), bettor, winnings);
    }

    function claimAllWinnings() external {
        address bettor = msg.sender;
        for (uint32 raceId = 1; raceId <= raceData.length; raceId++) {
            RaceData storage race = raceData[raceId - 1];
            BetData storage data = betData[raceId - 1][bettor];

            if (data.amount == 0) continue;
            if (data.claimed) continue;
            if (data.lane != race.winningLane) continue;

            claimWinnings(raceId);
        }
    }

    // Admin functions
    function startRace() external onlyOwner noActiveRace {
        currentRace = lastRace + 1;

        uint32 raceId = currentRace;

        raceData.push(RaceData(true, true, false, 0, 0));

        if (raceData.length != raceId) revert RaceDataMismatch();

        emit RaceStarted(raceId);
    }

    function endBetting() external onlyOwner needsActiveRace {
        uint32 raceId = currentRace;
        RaceData storage data = raceData[raceId - 1];

        if (!data.bettingActive) revert BettingEndedAlready();

        data.bettingActive = false;

        emit BettingEnded(raceId);
    }

    function endRace(uint8 winningLane) external onlyOwner needsActiveRace {
        uint32 raceId = currentRace;
        RaceData storage data = raceData[raceId - 1];

        if (data.bettingActive) revert BettingStillActive();

        data.active = false;
        data.winningLane = winningLane;
        lastRace = raceId;
        currentRace = 0;

        emit RaceEnded(raceId, winningLane);
    }

    function sweep() external onlyOwner noActiveRace {
        // Transfer all funds into the house wallet
        SafeTransferLib.safeTransfer(ERC20(address(token)), house, token.balanceOf(address(this)));
        // if for some reason there are native tokens in the contract
        SafeTransferLib.safeTransferETH(house, address(this).balance);
    }

    function swapTokensForEth(address wallet, uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = token.uniswapV2Router().WETH();
        token.approve(address(token.uniswapV2Router()), tokenAmount);
        // make the swap
        token.uniswapV2Router().swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            wallet,
            block.timestamp
        );
    }

    // Withdraw house winnings, this is going to be expensive.
    function houseWithdraw(uint32 raceId) external onlyOwner {
        if (raceId > raceData.length) revert InvalidRaceId();

        RaceData storage race = raceData[raceId - 1];
        if (race.active) revert ActiveRace();
        if (race.houseWithdrew) revert AlreadyClaimed();

        uint8 lane = race.winningLane;
        uint256 totalLoseBet = 0;
        for (uint8 otherLane = 1; otherLane <= 6; otherLane++) {
            if (otherLane == lane) continue;

            totalLoseBet += betPerRacePerLane[raceId - 1][otherLane];
        }

        uint256 houseWinnings = totalLoseBet / 10;

        swapTokensForEth(house, houseWinnings);

        race.houseWithdrew = true;
    }

    // View functions
    function unclaimedWinnings(address bettor) public view returns (uint32[] memory) {
        uint32[] memory unclaimed;
        uint256 length = raceData.length;

        for (uint32 raceId; raceId < length; raceId++) {
            BetData storage data = betData[raceId][bettor];
            RaceData storage race = raceData[raceId];

            if (race.active) continue;
            if (race.winningLane != data.lane) continue;
            if (data.amount == 0) continue;
            if (data.claimed) continue;

            unclaimed[unclaimed.length] = raceId;
        }

        return unclaimed;
    }

    function getUnclaimedBalance(address bettor) public view returns (uint256) {
        uint256 unclaimed = 0;
        uint256 length = raceData.length;

        for (uint32 raceId; raceId < length; raceId++) {
            BetData storage data = betData[raceId][bettor];
            RaceData storage race = raceData[raceId];

            uint8 lane = data.lane;

            if (race.active) continue;
            if (race.winningLane != lane) continue;
            if (data.amount == 0) continue;
            if (data.claimed) continue;

            uint256 totalWinBet = betPerRacePerLane[raceId][lane];
            uint256 totalLoseBet = 0;
            for (uint8 otherLane = 1; otherLane <= 6; otherLane++) {
                if (otherLane == lane) continue;

                totalLoseBet += betPerRacePerLane[raceId][otherLane];
            }

            unclaimed += _calculateWinnings(data.amount, totalLoseBet, totalWinBet);
        }

        return unclaimed;
    }

    function participatedInRaces(address bettor) public view returns (uint32[] memory) {
        uint32 counter = 0;
        uint32[] memory participated = new uint32[](totalBetsMade[bettor]);
        uint256 length = raceData.length;

        for (uint32 raceId; raceId < length; raceId++) {
            BetData storage data = betData[raceId][bettor];

            if (data.amount == 0) continue;

            participated[counter] = raceId;
            counter++;
        }

        return participated;
    }

    function _totalRaces() public view returns (uint256) {
        uint256 racesComplete = raceData.length;
        if (currentRace > 0) racesComplete -= 1;

        return racesComplete;
    }

    function getRaceBets(uint32 index) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            betPerRacePerLane[index][1],
            betPerRacePerLane[index][2],
            betPerRacePerLane[index][3],
            betPerRacePerLane[index][4],
            betPerRacePerLane[index][5],
            betPerRacePerLane[index][6]
        );
    }

    // Pure functions
    function _calculateWinnings(uint256 amount, uint256 totalLoseBet, uint256 totalWinBet)
        internal
        pure
        returns (uint256)
    {
        uint256 winAmount = 0;
        if (totalLoseBet > 0) {
            uint256 houseTax = totalLoseBet / 10; // Deduct from winnings 10% for house tax
            winAmount = (amount * (totalLoseBet - houseTax)) / totalWinBet;
        }

        return amount + winAmount;
    }
}
