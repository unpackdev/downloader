// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21;

import "./IUniswapV2Pair.sol";
import "./Math.sol";
import "./Time.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./VRFConsumerBaseV2.sol";
import "./SafeCast.sol";
import "./ERC1155.sol";
import "./IReferralStorage.sol";
import "./Checkpoints.sol";
import "./SafeERC20.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./ERC1155Supply.sol";
import "./ERC1155URIStorage.sol";

contract Lottery is Ownable, ERC1155Supply, ERC1155URIStorage, VRFConsumerBaseV2 {
    using Math for uint256;
    using SafeERC20 for ERC20;
    using Checkpoints for Checkpoints.Trace208;

    ///////////////////////////////////////////
    ////////// CONSTANTS //////////////////////
    ///////////////////////////////////////////

    /// @dev The max buyback and burn percentage to take from prize pot.
    uint256 constant MAX_BUYBACK_BURN = 2e17;

    /// @dev Chainlink VRF Keyhash.
    bytes32 constant VRF_KEYHASH = 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92;

    ///////////////////////////////////////////
    ////////// IMMUTABLES AND MISC ////////////
    ///////////////////////////////////////////

    /// @dev The VRF Coordinator.
    address immutable vrfCoordinator;

    /// @dev The 888 token.
    address immutable lucky8Token;

    /// @dev The 888/USDC LP token.
    address immutable lucky8LpToken;

    /// @dev USDC Token.
    address immutable usdcToken;

    /// @dev The buyback and burn address.
    address buybackBurnAddress;

    /// @dev Referral storage.
    IReferralStorage public referralStorage;

    /// @dev Chainlink VRF Subscription ID.
    uint64 public chainlinkSubscriptionId;

    /// @dev Chainlink VRF minimum request confirmations.
    uint16 chainlinkMinimumRequestConfirmations = 70;

    /// @dev Chainlink VRF callback gas limit.
    uint32 chainlinkCallbackGas = 500_000;

    ///////////////////////////////////////////
    ////////// DEPOSITS STATE /////////////////
    ///////////////////////////////////////////

    /// @dev Amount of locked tokens using a certain referral code.
    mapping(bytes32 => Checkpoints.Trace208) private _lockedTokensPerReferralCode;

    /// @dev Amount of locked LP tokens using a certain referral code.
    mapping(bytes32 => Checkpoints.Trace208) private _lockedLpTokensPerReferralCode;

    /// @dev Maps address to snapshots of locked tokens.
    mapping(address => Checkpoints.Trace208) private _lockedTokens;

    /// @dev Maps address to snapshots of locked LP tokens.
    mapping(address => Checkpoints.Trace208) private _lockedLpTokens;

    /// @dev Snapshot of total locked tokens.
    Checkpoints.Trace208 private _totalTokenCheckpoint;

    /// @dev Snapshot of total locked LP tokens.
    Checkpoints.Trace208 private _totalLpTokenCheckpoint;

    ///////////////////////////////////////////
    ////////// ROUND STORAGE VARS /////////////
    ///////////////////////////////////////////

    /// @dev Indicates whether the round is ongoing.
    bool public isRoundOngoing;

    /// @dev Last round.
    uint256 public roundNumber;

    /// @dev Round info struct
    struct RoundInfo {
        // Indicates whether the raffle has been executed.
        bool isRaffleExecuted;
        // Number of winners.
        uint8 nWinners;
        // Start timepoint.
        uint48 startTimepoint;
        // Raffle execution timepoint.
        uint48 raffleExecutionTimepoint;
        // Minting window duration.
        uint48 mintingWindowDuration;
        // Claiming window duration.
        uint48 claimingWindowDuration;
        // Chainlink VRF request id.
        uint256 reqId;
        // Prize pot.
        uint256 prizePot;
        // $888 amount per LP wei.
        uint256 tokensPerLpWei;
        // Winning numbers.
        uint256[] winningNumbers;
    }

    /// @dev Round info for each round.
    RoundInfo[] public roundInfo;

    /// @dev Maps a round id to a Chainlink VRF request id.
    mapping(uint256 => uint256) public requestIdToRound;

    /// @dev Tickets ranges for users.
    /// @dev The first mapping is the round number.
    mapping(uint256 => mapping(address => uint256[2])) public userTicketsRanges;

    ///////////////////////////////////////////
    ////////// EVENTS /////////////////////////
    ///////////////////////////////////////////

    /// @dev Emitted when the referral storage is set.
    event SetReferralStorage(address indexed referralStorage);

    /// @dev Emitted when the buyback and burn address is set.
    event SetBuybackBurnAddress(address indexed buybackBurnAddress);

    /// @dev Emitted when tokens are locked.
    event TokensLocked(address indexed account, uint256 amount, bytes32 referralCode);

    /// @dev Emitted when LP tokens are locked.
    event LpTokensLocked(address indexed account, uint256 amount, bytes32 referralCode);

    /// @dev Emitted when tokens are unlocked.
    event TokensUnlocked(address indexed account, uint256 amount, bytes32 referralCode);

    /// @dev Emitted when LP tokens are unlocked.
    event LpTokensUnlocked(address indexed account, uint256 amount, bytes32 referralCode);

    /// @dev Emitted when tickets are minted.
    event TicketsMinted(address indexed account, uint256 round, uint256 amount);

    /// @dev Emitted when the prize is claimed.
    event PrizeClaimed(address indexed account, uint256 round, uint256 amount);

    /// @dev Emitted when a round is started.
    event RoundStarted(
        uint256 indexed round,
        uint256 prizePot,
        uint256 nWinners,
        uint48 mintingWindowDuration,
        uint48 claimingWindowDuration,
        uint256 buyBackPct,
        uint256 tokensPerLpWei
    );

    /// @dev Emitted when a raffle is made.
    event RaffleExecuted(uint256 indexed round, uint256[] winningNumbers);

    /// @dev Emitted when a round is finalized.
    event RoundFinalized(uint256 indexed round);

    /// @dev Emitted when tickets are burned.
    event TicketsBurned(address indexed account, uint256 round, uint256 amount);

    // solhint-disable-next-line empty-blocks
    constructor(
        address _lucky8Token,
        address _lucky8LpToken,
        address _usdcToken,
        address _buyBackBurnAddress,
        string memory _uri,
        IReferralStorage _referralStorage,
        address _vrfCoordinator,
        uint64 _chainlinkSubscriptionId
    )
        Ownable(msg.sender)
        ERC1155(_uri)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        // Initialize immutables and miscs

        lucky8Token = _lucky8Token;
        lucky8LpToken = _lucky8LpToken;
        usdcToken = _usdcToken;
        buybackBurnAddress = _buyBackBurnAddress;
        referralStorage = _referralStorage;
        vrfCoordinator = _vrfCoordinator;
        chainlinkSubscriptionId = _chainlinkSubscriptionId;
    }

    /// @dev Clock used for flagging checkpoints.
    function clock() public view virtual returns (uint48) {
        return Time.timestamp();
    }

    /// @dev Machine-readable description of the clock as specified in EIP-6372.
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public view virtual returns (string memory) {
        require(clock() == Time.timestamp(), "Lottery: inconsistent clock");
        return "mode=timestamp";
    }

    ///////////////////////////////////////////
    ///////////// VIEW FUNCTIONS /////////////
    //////////////////////////////////////////

    /// @dev Method used to get the amount of $888 tokens per LP wei.
    function tokensPerLpWei() external view returns (uint256) {
        return _tokensPerLpWei();
    }

    /// @dev Method used to get the amount of locked tokens.
    function totalLockedTokens() external view returns (uint256) {
        return _totalTokenCheckpoint.upperLookupRecent(clock());
    }

    /// @dev Method used to get the amount of locked LP tokens.
    function totalLockedLpTokens() external view returns (uint256) {
        return _totalLpTokenCheckpoint.upperLookupRecent(clock());
    }

    /// @dev Method used to get the amount of locked tokens for a given time.
    function totalLockedTokensForTime(uint48 time) external view returns (uint256) {
        return _totalTokenCheckpoint.upperLookupRecent(time);
    }

    /// @dev Method used to get the amount of locked lp tokens for a given time.
    function totalLockedLpTokensForTime(uint48 time) external view returns (uint256) {
        return _totalLpTokenCheckpoint.upperLookupRecent(time);
    }

    /// @dev Method used to get the amount of mintable tickets for an account.
    /// @dev This method is used by the frontend to display the amount of tickets that can be minted by the user.
    function mintableTicketsForAccount(address _account)
        external
        view
        returns (
            uint256 ticketsAmount,
            uint256 lockedTokensTicketsAmount,
            uint256 lockedLpTokensTicketsAmount,
            uint256 bonusAmount
        )
    {
        if (!isRoundOngoing) {
            (ticketsAmount, lockedTokensTicketsAmount, lockedLpTokensTicketsAmount, bonusAmount) =
                _mintableTicketsForAccount(_account, clock(), _tokensPerLpWei());
        } else {
            // Get current round info.
            uint256 currentRound = roundNumber;
            RoundInfo memory currentRoundInfo = roundInfo[currentRound - 1];

            // Check that the round is in still in minting phase.
            if (clock() <= currentRoundInfo.startTimepoint + currentRoundInfo.mintingWindowDuration) {
                (ticketsAmount, lockedTokensTicketsAmount, lockedLpTokensTicketsAmount, bonusAmount) =
                _mintableTicketsForAccount(_account, currentRoundInfo.startTimepoint, currentRoundInfo.tokensPerLpWei);
            }
        }
    }

    /// @dev Method used to infos about users.
    function getUserInfo(address account)
        external
        view
        returns (
            uint256 tokensLocked,
            uint256 lpTokensLocked,
            uint256 referredTokensLocked,
            uint256 referredLpTokensLocked
        )
    {
        // Get current clock.
        uint48 currentClock = clock();

        tokensLocked = _lockedTokens[account].upperLookupRecent(currentClock);
        lpTokensLocked = _lockedLpTokens[account].upperLookupRecent(currentClock);

        bytes32 userRefCode = referralStorage.accountCodeOwned(account);

        if (userRefCode != bytes32(0)) {
            referredTokensLocked = _lockedTokensPerReferralCode[userRefCode].upperLookupRecent(currentClock);
            referredLpTokensLocked = _lockedLpTokensPerReferralCode[userRefCode].upperLookupRecent(currentClock);
        }
    }

    /// @dev Method used to get infos about a round.
    function getRoundInfo(uint256 roundId) external view returns (RoundInfo memory) {
        return roundInfo[roundId - 1];
    }

    ///////////////////////////////////////////
    ///////////// USER FUNCTIONS /////////////
    //////////////////////////////////////////

    /// @dev Method used to lock tokens.
    function lockTokens(uint256 amount, bytes32 _referralCode) external {
        // Transfer the amount of tokens to lock in this contract.
        ERC20(lucky8Token).safeTransferFrom(msg.sender, address(this), amount);

        // Update the total locked tokens for the user and the global total locked tokens.
        _push(_lockedTokens[msg.sender], _add, SafeCast.toUint208(amount));
        _push(_totalTokenCheckpoint, _add, SafeCast.toUint208(amount));

        // Set the account referral code if needed.
        _setAccountReferralCode(msg.sender, _referralCode);

        // Check if the user has registered a referral code to use.
        (bytes32 referralCode,) = referralStorage.getAccountReferralInfo(msg.sender);

        // If so, update the total locked tokens for the code.
        if (referralCode != bytes32(0)) {
            _push(_lockedTokensPerReferralCode[referralCode], _add, SafeCast.toUint208(amount));
        }

        // Emit `TokensLocked` event.
        emit TokensLocked(msg.sender, amount, referralCode);
    }

    /// @dev Method used to lock LP tokens.
    function lockLpTokens(uint256 amount, bytes32 _referralCode) external {
        // Transfer the amount of lp tokens to lock in this contract.
        ERC20(lucky8LpToken).safeTransferFrom(msg.sender, address(this), amount);

        // Update the total locked lp tokens for the user and the global total locked lp tokens.
        _push(_lockedLpTokens[msg.sender], _add, SafeCast.toUint208(amount));
        _push(_totalLpTokenCheckpoint, _add, SafeCast.toUint208(amount));

        // Set the account referral code if needed.
        _setAccountReferralCode(msg.sender, _referralCode);

        // Check if the user has registered a referral code to use.
        (bytes32 referralCode,) = referralStorage.getAccountReferralInfo(msg.sender);

        // If so, update the total locked tokens for the code.
        if (referralCode != bytes32(0)) {
            _push(_lockedLpTokensPerReferralCode[referralCode], _add, SafeCast.toUint208(amount));
        }

        // Emit `LpTokensLocked` event.
        emit LpTokensLocked(msg.sender, amount, referralCode);
    }

    /// @dev Method used to unlock tokens.
    function unlockTokens(uint256 amount) external {
        require(!isRoundOngoing, "Lottery: round ongoing");

        // Get current clock and check that the user has enough locked tokens.
        uint48 currentClock = clock();
        uint208 lockedTokens = _lockedTokens[msg.sender].upperLookupRecent(currentClock);
        require(lockedTokens >= amount, "Lottery: not enough locked tokens");

        // Update the user locked tokens and the global locked tokens.
        _push(_lockedTokens[msg.sender], _subtract, SafeCast.toUint208(amount));
        _push(_totalTokenCheckpoint, _subtract, SafeCast.toUint208(amount));

        // Check if the user has registered a referral code to use.
        (bytes32 referralCode,) = referralStorage.getAccountReferralInfo(msg.sender);

        // If so, update the total locked tokens for the code.
        if (referralCode != bytes32(0)) {
            _push(_lockedTokensPerReferralCode[referralCode], _subtract, SafeCast.toUint208(amount));
        }

        // Transfer the amount of tokens back to the user.
        ERC20(lucky8Token).safeTransfer(msg.sender, amount);

        // Emit `TokensUnlocked` event.
        emit TokensUnlocked(msg.sender, amount, referralCode);
    }

    /// @dev Method used to unlock LP tokens.
    /// todo: find a way to reduce tokens locked for referrer when user change referral code.
    function unlockLpTokens(uint256 amount) external {
        require(!isRoundOngoing, "Lottery: round ongoing");

        // Get current clock and check that the user has enough locked lp tokens.
        uint48 currentClock = clock();
        uint208 lockedLpTokens = _lockedLpTokens[msg.sender].upperLookupRecent(currentClock);
        require(lockedLpTokens >= amount, "Lottery: not enough locked tokens");

        // Update the user locked lp tokens and the global locked lp tokens.
        _push(_lockedLpTokens[msg.sender], _subtract, SafeCast.toUint208(amount));
        _push(_totalLpTokenCheckpoint, _subtract, SafeCast.toUint208(amount));

        // Check if the user has registered a referral code to use.
        (bytes32 referralCode,) = referralStorage.getAccountReferralInfo(msg.sender);

        // If so, update the total locked lp tokens for the code.
        if (referralCode != bytes32(0)) {
            _push(_lockedLpTokensPerReferralCode[referralCode], _subtract, SafeCast.toUint208(amount));
        }

        // Transfer the amount of lp tokens back to the user.
        ERC20(lucky8LpToken).safeTransfer(msg.sender, amount);

        // Emit `LpTokensUnlocked` event.
        emit LpTokensUnlocked(msg.sender, amount, referralCode);
    }

    /// @dev Method used to mint raffle tickets.
    function mintTickets() external returns (uint256) {
        require(isRoundOngoing, "Lottery: no round ongoing");

        // Get current round number and round info.
        uint256 currentRound = roundNumber;
        RoundInfo memory currentRoundInfo = roundInfo[currentRound - 1];

        // Check that we are in the minting window.
        require(
            clock() <= currentRoundInfo.startTimepoint + currentRoundInfo.mintingWindowDuration,
            "Lottery: not in minting window"
        );

        // Check if the user has already minted tickets for this round.
        uint256 userTickets = balanceOf(msg.sender, currentRound);
        require(userTickets == 0, "Lottery: user already minted tickets");

        // Get the amount of claimable tickets for the user.
        (uint256 mintableTickets,,,) =
            _mintableTicketsForAccount(msg.sender, currentRoundInfo.startTimepoint, currentRoundInfo.tokensPerLpWei);

        uint256 totalSupplyBeforeMinting = totalSupply(currentRound);
        _mint(msg.sender, currentRound, mintableTickets, "");
        uint256 totalSupplyAfterMinting = totalSupply(currentRound);

        // Update the user tickets ranges.
        userTicketsRanges[currentRound][msg.sender][0] = totalSupplyBeforeMinting;
        userTicketsRanges[currentRound][msg.sender][1] = totalSupplyAfterMinting - 1;

        // Emit `TicketsMinted` event.
        emit TicketsMinted(msg.sender, currentRound, mintableTickets);

        return mintableTickets;
    }

    /// @dev Method used to claim the prize.
    function claimPrize() external returns (uint256) {
        // Check that there's an ongoing round.
        require(isRoundOngoing, "Lottery: no round ongoing");

        // Get current round number and round info.
        uint48 currentClock = clock();
        uint256 currentRound = roundNumber;
        RoundInfo memory currentRoundInfo = roundInfo[currentRound - 1];

        // Check that the user has at least one ticket.
        uint256 userTickets = balanceOf(msg.sender, currentRound);
        require(userTickets > 0, "Lottery: no tickets");

        // Check that the raffle has been executed.
        require(currentRoundInfo.isRaffleExecuted, "Lottery: raffle not executed yet");

        // Check that we are in the claiming window.
        require(
            currentClock > currentRoundInfo.raffleExecutionTimepoint
                && currentClock <= currentRoundInfo.raffleExecutionTimepoint + currentRoundInfo.claimingWindowDuration,
            "Lottery: claiming window not started yet or still ongoing"
        );

        // Get the ticket range for the user.
        uint256[2] memory userTicketsRange = userTicketsRanges[currentRound][msg.sender];

        // Check if the user has won.
        uint256[] memory winningNumbers = currentRoundInfo.winningNumbers;

        // Initialize the amount of winning tickets.
        uint256 prize;
        uint256 winningTickets;
        uint256 winningTicketPrize = currentRoundInfo.prizePot.ceilDiv(currentRoundInfo.nWinners);
        for (uint256 i = 0; i < winningNumbers.length; i++) {
            // Check if the winning number is in the user ticket range.
            if (winningNumbers[i] >= userTicketsRange[0] && winningNumbers[i] <= userTicketsRange[1]) {
                // Add the amount of winning tickets and the prize.
                winningTickets += 1;
                prize += winningTicketPrize;
            }
        }

        // Check if the user has won.
        require(winningTickets != 0, "Lottery: no winning tickets");

        // Burn the all the users tickets.
        _burn(msg.sender, currentRound, userTickets);

        // Check if the user used a referral code.
        // Check if the user has registered a referral code to use.
        (bytes32 referralCode, address referrer) = referralStorage.getAccountReferralInfo(msg.sender);

        // If so, update the total locked lp tokens for the code.
        if (referralCode != bytes32(0)) {
            // 10% goes to the referrer.
            uint256 referrerShare = prize.mulDiv(5e16, 1e18, Math.Rounding.Floor);
            prize = prize - referrerShare;

            ERC20(usdcToken).safeTransfer(referrer, referrerShare);
        }

        // Transfer the prize to the user.
        ERC20(usdcToken).safeTransfer(msg.sender, prize);

        // Emit `PrizeClaimed` event.
        emit PrizeClaimed(msg.sender, currentRound, prize);

        return prize;
    }

    /// @dev Method used to burn user's tickets.
    function burnTickets(uint256 round) external {
        // Check that the user has at least one ticket.
        uint256 userTickets = balanceOf(msg.sender, round);
        require(userTickets != 0, "Lottery: no tickets");

        // Burn the all the user's tickets.
        _burn(msg.sender, round, userTickets);

        // Emit `TicketsBurned` event.
        emit TicketsBurned(msg.sender, round, userTickets);
    }

    ///////////////////////////////////////////
    ///////////// ADMIN FUNCTIONS /////////////
    ///////////////////////////////////////////

    /// @dev Function used to withdraw tokens from the contract.
    /// @dev This function can be used to withdraw tokens that are not $888 or $888/USDC LP tokens.
    /// @dev This function can only be called by the owner.
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(token != lucky8Token, "Lottery: cannot withdraw 888 tokens");
        require(token != lucky8LpToken, "Lottery: cannot withdraw 888/USDC LP tokens");

        ERC20(token).safeTransfer(msg.sender, amount);
    }

    /// @dev Function used to set the referral storage.
    function setReferralStorage(IReferralStorage _referralStorage) external onlyOwner {
        referralStorage = _referralStorage;
        emit SetReferralStorage(address(_referralStorage));
    }

    /// @dev Function used to set the buyback and burn address.
    function setBuybackBurnAddress(address _buybackBurnAddress) external onlyOwner {
        buybackBurnAddress = _buybackBurnAddress;
        emit SetBuybackBurnAddress(_buybackBurnAddress);
    }

    /// @dev Function used to set the chainlink subscription id.
    function setChainlinkSubscriptionId(uint64 _chainlinkSubscriptionId) external onlyOwner {
        chainlinkSubscriptionId = _chainlinkSubscriptionId;
    }

    /// @dev Function used to set the chainlink minimum request confirmations.
    function setChainlinkMinimumRequestConfirmations(uint16 _chainlinkMinimumRequestConfirmations) external onlyOwner {
        chainlinkMinimumRequestConfirmations = _chainlinkMinimumRequestConfirmations;
    }

    /// @dev Function used to set the chainlink callback gas.
    function setChainlinkCallbackGas(uint32 _chainlinkCallbackGas) external onlyOwner {
        chainlinkCallbackGas = _chainlinkCallbackGas;
    }

    /// @dev Init params for initializing a new round.
    struct InitParams {
        string tokenUri;
        uint8 nWinners;
        uint48 mintingWindowDuration;
        uint48 claimingWindowDuration;
        uint256 buyBackPct;
        uint256 lpWeiValue;
    }

    /// @dev Function used to start a new raffle round.
    /// @dev This function snapshots the state of the contract (total token and LP token locked)
    ///      and updates the latest raffle timepoint. From this point on users can then mint the
    ///      ERC-1155 token representing their raffle tickets.
    ///
    /// @dev This function can only be called by the owner.
    function startNewRound(InitParams calldata params) public onlyOwner {
        // Check that a round is not ongoing.
        require(!isRoundOngoing, "Lottery: round already ongoing");
        // Check that the `mintingWindowDuration` is not 0.
        require(params.mintingWindowDuration != 0, "Lottery: minting window duration must be greater than 0");
        // Check that the `claimingWindowDuration` is not 0.
        require(params.claimingWindowDuration != 0, "Lottery: claiming window duration must be greater than 0");
        // Check that the `buyBackPct` is not greater than the max buyback and burn percentage.
        require(params.buyBackPct <= MAX_BUYBACK_BURN, "Lottery: buyback and burn percentage too high");

        // Get the current clock
        uint48 currentClock = clock();

        // Get the amount of total locked tokens and lp tokens.
        uint208 totalToken = _totalTokenCheckpoint.upperLookupRecent(currentClock);
        uint208 totalLpToken = _totalLpTokenCheckpoint.upperLookupRecent(currentClock);

        // Update the total locked tokens and lp tokens checkpoints for the current clock value.
        _totalTokenCheckpoint.push(currentClock, SafeCast.toUint208(totalToken));
        _totalLpTokenCheckpoint.push(currentClock, SafeCast.toUint208(totalLpToken));

        // Compute the prize pot and transfer amount for buyback and burn.
        uint256 prizePot;

        {
            uint256 usdcBalance = ERC20(usdcToken).balanceOf(address(this));
            uint256 buyBackAmount = usdcBalance.mulDiv(params.buyBackPct, 1e18);
            uint256 rollOverAmount = usdcBalance.mulDiv(1e17, 1e18);

            // Transfer the buyback amount to the buyback and burn address.
            ERC20(usdcToken).safeTransfer(buybackBurnAddress, buyBackAmount);

            prizePot = usdcBalance - (buyBackAmount + rollOverAmount);
        }

        // Initialize the round infos
        RoundInfo memory round = RoundInfo({
            isRaffleExecuted: false,
            prizePot: prizePot,
            tokensPerLpWei: params.lpWeiValue,
            raffleExecutionTimepoint: 0,
            startTimepoint: currentClock,
            nWinners: params.nWinners,
            reqId: 0,
            mintingWindowDuration: params.mintingWindowDuration,
            claimingWindowDuration: params.claimingWindowDuration,
            winningNumbers: new uint256[](0)
        });

        // Update the round number and round info.
        roundNumber += 1;
        roundInfo.push(round);

        // Set the global state as ongoing round.
        isRoundOngoing = true;

        // Set the token URI for the round.
        _setURI(roundNumber, params.tokenUri);

        // Emit `RoundStarted` event.
        emit RoundStarted(
            roundNumber,
            prizePot,
            params.nWinners,
            params.mintingWindowDuration,
            params.claimingWindowDuration,
            params.buyBackPct,
            params.lpWeiValue
        );
    }

    /// @dev Function used to execute the raffle.
    /// @dev This function can only be called by the owner.
    function executeRaffle() public onlyOwner {
        uint48 currentClock = clock();

        RoundInfo storage currentRound = roundInfo[roundNumber - 1];

        require(!currentRound.isRaffleExecuted, "Lottery: raffle already executed");
        require(
            currentClock > currentRound.startTimepoint + currentRound.mintingWindowDuration,
            "Lottery: raffle not started yet"
        );

        // Get the amount of winners to draw.
        uint8 nWinners = currentRound.nWinners;

        // Use the Chainlink VRF to get a random number.
        // This will initiate the request but we will need to wait for the request to be fulfilled.
        // See the method `fulfillRandomWords` for the callback.
        uint256 requestId = VRFCoordinatorV2Interface(vrfCoordinator).requestRandomWords(
            VRF_KEYHASH, // keyHash
            chainlinkSubscriptionId,
            chainlinkMinimumRequestConfirmations, // minimumRequestConfirmations
            chainlinkCallbackGas, // callbackGasLimit
            nWinners // numWords
        );

        // Update current round request id and mapping between request id and round number.
        currentRound.reqId = requestId;
        requestIdToRound[requestId] = roundNumber;
    }

    /// @dev Function used to finalize the current round.
    /// @dev This function can only be called by the owner.
    function finalizeRound() public onlyOwner {
        require(isRoundOngoing, "Lottery: no round ongoing");

        uint256 _roundNumber = roundNumber;

        RoundInfo storage currentRound = roundInfo[_roundNumber - 1];

        // Require that the raffle has been executed.
        require(currentRound.isRaffleExecuted, "Lottery: raffle not executed yet");

        // And that the claiming window is over.
        require(
            clock() > currentRound.raffleExecutionTimepoint + currentRound.claimingWindowDuration,
            "Lottery: claiming window not started yet or still ongoing"
        );

        isRoundOngoing = false;

        emit RoundFinalized(_roundNumber);
    }

    /// @dev Function used to finalize the current round without checks.
    /// @dev This function can only be called by the owner.
    /// @dev THIS SHOULD BE USED ONLY IN EMERGENCY CASES.
    function forceFinalizeRound() public onlyOwner {
        require(isRoundOngoing, "Lottery: no round ongoing");

        isRoundOngoing = false;

        emit RoundFinalized(roundNumber);
    }

    ///////////////////////////////////////////
    ////////// ERC-1155 OVERRIDES /////////////
    ///////////////////////////////////////////

    /// @dev Override needed to make the tickets non-transferable.
    function safeTransferFrom(
        address, /* from */
        address, /* to */
        uint256, /* id */
        uint256, /* value */
        bytes memory /* data */
    )
        public
        pure
        override
    {
        revert("Lottery: Tickets are non-transferable");
    }

    /// @dev Override needed to make the tickets non-transferable.
    function safeBatchTransferFrom(
        address, /* from */
        address, /* to */
        uint256[] memory, /* ids */
        uint256[] memory, /* values */
        bytes memory /* data */
    )
        public
        pure
        override
    {
        revert("Lottery: Tickets are non-transferable");
    }

    /// @dev Override needed to get token id URI.
    function uri(uint256 id) public view override(ERC1155URIStorage, ERC1155) returns (string memory) {
        return super.uri(id);
    }

    /// @dev Override needed to update balances for ERC-1155 tokens.
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    )
        internal
        override(ERC1155Supply, ERC1155)
    {
        super._update(from, to, ids, values);
    }

    ///////////////////////////////////////////
    ////////// INTERNAL FUNCTIONS /////////////
    ///////////////////////////////////////////

    /// @dev Method used to get the amount of $888 tokens per LP wei.
    function _tokensPerLpWei() internal view returns (uint256) {
        (uint112 r0, uint112 r1,) = IUniswapV2Pair(lucky8LpToken).getReserves();
        uint256 pairReserves = (IUniswapV2Pair(lucky8LpToken).token0() == lucky8Token) ? r0 : r1;
        uint256 lpTokenSupply = ERC20(lucky8LpToken).totalSupply();

        // We multiply the reserves by 3 because LP token holders are entitled to a 1.5x bonus.
        return (3 * pairReserves) / lpTokenSupply;
    }

    /// @dev Method used to get the amount of claimable tickets.
    function _mintableTicketsForAccount(
        address _account,
        uint48 _startTimepoint,
        uint256 _tokensPerLpWeiAmount
    )
        internal
        view
        returns (uint256, uint256, uint256, uint256)
    {
        // Initialize the bonus amount.
        uint256 bonusAmount;

        // Check the amount of locked tokens and LP tokens for the user.
        uint208 lockedTokens = _lockedTokens[_account].upperLookupRecent(_startTimepoint);
        uint208 lockedLpTokens = _lockedLpTokens[_account].upperLookupRecent(_startTimepoint);

        // The total amount of locked tokens is equal to the sum of locked tokens and (locked LP tokens * tickets per lp
        // wei).
        // note: This quantity is (tickets * 1e18).
        uint256 userLockedTokens = lockedTokens + (lockedLpTokens * _tokensPerLpWeiAmount);

        // If the user used a referral code add a 10% bonus.
        (bytes32 referralCode,) = referralStorage.getAccountReferralInfo(_account);
        if (referralCode != bytes32(0)) {
            bonusAmount = userLockedTokens.mulDiv(1e17, 1e18, Math.Rounding.Floor);
        }

        // If the user has no locked tokens, return 0.
        if (userLockedTokens == 0) return (0, 0, 0, 0);

        // Check if the user has a referrer code.
        bytes32 referrerCode = referralStorage.accountCodeOwned(_account);

        // If so, check the amount of locked tokens and LP tokens for the referrer.
        if (referrerCode != bytes32(0)) {
            uint208 lockedReferralTokens = _lockedTokensPerReferralCode[referrerCode].upperLookupRecent(_startTimepoint);

            uint208 lockedReferralLpTokens =
                _lockedLpTokensPerReferralCode[referrerCode].upperLookupRecent(_startTimepoint);

            // The total amount of locked tokens is equal to the sum of locked tokens and (locked LP tokens * tickets
            // per lp wei).
            uint256 referralLockedTokens = lockedReferralTokens + (lockedReferralLpTokens * _tokensPerLpWeiAmount);

            // The ratio between referral locked tokens and user locked tokens is used to calculate the bonus amount.
            uint256 ratio = referralLockedTokens.mulDiv(1e18, userLockedTokens, Math.Rounding.Floor);

            // The bonus multiplier is the min between ratio and 10.
            uint256 bonusMultiplier = Math.min(ratio, 1e19);

            // The bonus amount is equal to (user locked tokens * bonus multiplier).
            bonusAmount = bonusAmount + userLockedTokens.mulDiv(bonusMultiplier, 1e18, Math.Rounding.Floor);
        }

        // The mintable tickets is equal to (user locked tokens + bonus amount) / 1e18.
        uint256 mintableTickets = (userLockedTokens + bonusAmount).ceilDiv(1e18);

        return (
            mintableTickets,
            uint256(lockedTokens).ceilDiv(1e18),
            uint256(lockedLpTokens).ceilDiv(1e18),
            bonusAmount.ceilDiv(1e18)
        );
    }

    /// @dev Callback function used by the Chainlink VRF.
    // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // Check that a round is ongoing.
        require(isRoundOngoing, "Lottery: no round ongoing");

        // Get the round number for the request id.
        uint256 round = requestIdToRound[requestId];

        // Get the round info.
        RoundInfo storage currentRound = roundInfo[round - 1];

        // Check that the round has the same request id.
        require(currentRound.reqId == requestId, "Lottery: wrong request id");

        // Check that the round raffle has not been executed yet.
        require(
            !currentRound.isRaffleExecuted && currentRound.raffleExecutionTimepoint == 0,
            "Lottery: raffle already executed"
        );

        uint48 currentClock = clock();

        // Check that the round is not in the minting phase.
        require(
            currentClock > currentRound.startTimepoint + currentRound.mintingWindowDuration,
            "Lottery: raffle minting phase ongoing"
        );

        // Iterate over the random words and get the winning numbers.
        for (uint256 i = 0; i < currentRound.nWinners; i++) {
            uint256 winningNumber = randomWords[i] % totalSupply(round);
            currentRound.winningNumbers.push(winningNumber);
        }

        // Finalize the round.
        currentRound.isRaffleExecuted = true;
        currentRound.raffleExecutionTimepoint = currentClock;

        // Emit `RaffleExecuted` event.
        emit RaffleExecuted(round, currentRound.winningNumbers);
    }

    /// @dev Internal utility function used to set the referral code for an account.
    function _setAccountReferralCode(address _account, bytes32 _referralCode) internal {
        // skip if referral code is null
        if (_referralCode == bytes32(0)) return;

        // skip if referral storage is not set
        if (address(referralStorage) == address(0)) return;

        // skip if the account already has a referral code set
        if (referralStorage.accountReferralCode(_account) != bytes32(0)) return;

        referralStorage.setAccountReferralCode(_account, _referralCode);
    }

    /// @dev Pushes a new checkpoint to a given tracer.
    function _push(
        Checkpoints.Trace208 storage store,
        function(uint208, uint208) view returns (uint208) op,
        uint208 delta
    )
        private
        returns (uint208, uint208)
    {
        return store.push(clock(), op(store.latest(), delta));
    }

    /// @dev Adds two numbers.
    function _add(uint208 a, uint208 b) private pure returns (uint208) {
        return a + b;
    }

    /// @dev Subtracts two numbers.
    function _subtract(uint208 a, uint208 b) private pure returns (uint208) {
        return a - b;
    }
}
