// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./LinkTokenInterface.sol";
import "./ICoinFlipUsa.sol";

contract CoinFlipUsa is ICoinFlipUsa, VRFConsumerBaseV2, Ownable, ReentrancyGuard, Pausable {
    // The subscription ID for the Chainlink VRF service
    uint64 public immutable subscriptionId;

    // The key hash used for the Chainlink VRF service
    bytes32 public constant keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    // The number of confirmations required for the Chainlink VRF service
    uint16 constant requestConfirmations = 3;

    // The gas limit for the Chainlink VRF callback
    uint32 constant callbackGasLimit = 1e5;

    // The number of random words requested from the Chainlink VRF service
    uint32 constant numWords = 1;

    // The token used for betting in the coin flip game
    IERC20 public immutable flipToken;

    // The interface for interacting with the Chainlink VRF Coordinator
    VRFCoordinatorV2Interface public immutable vrfCoordinatorV2;

    // The interface for interacting with the Chainlink LINK token
    LinkTokenInterface public immutable linkToken;

    // The index of the current game
    uint256 public gameIndex = 1;

    // The minimum bet size for the coin flip game, in USA tokens
    uint256 public minimumBetSize = 5 * 1e3 * 1e18;

    // The maximum allowed gas price for participating in the coin flip game
    uint256 public maxAllowedGasPrice = 20;

    // The edge multiplier for winning bets in the coin flip game
    uint256 public winMultiplierEdge = 1900;

    // The address of the player with the current longest winning streak
    address internal currentStreakWinner;

    // The length of the current longest winning streak
    uint256 internal winningStreak = 2;

    // A mapping from player addresses to their coin flip game information
    mapping(address => CoinFlipInfo) internal coinFlipInfo;

    // A mapping from Chainlink VRF request IDs to the player addresses that made the requests
    mapping(uint256 => address) internal requestIdToPlayerAddress;

    constructor(
        address _admin,
        address _vrfCoordinator,
        address _linkTokenContract,
        uint256 _subscriptionId,
        address _flipTokenAddress
    ) VRFConsumerBaseV2(_vrfCoordinator) Ownable(_admin) {
        vrfCoordinatorV2 = VRFCoordinatorV2Interface(_vrfCoordinator);
        linkToken = LinkTokenInterface(_linkTokenContract);
        flipToken = IERC20(_flipTokenAddress);
        subscriptionId = uint64(_subscriptionId);
    }

    /**
     * @notice do a coin flip for a certain amount of tokens
     * @param _flipAmount the amount of tokens to bet
     * @param _playerChoice 1 for heads, 0 for tails
     */
    function flipUsa(uint256 _flipAmount, uint8 _playerChoice) external whenNotPaused nonReentrant {
        // check if _flipAmount exceeds minimumBetSize
        require(_flipAmount >= minimumBetSize, "CoinFlipUsa: bet amount too small");

        // check if the gas price is not too high
        require(tx.gasprice <= maxAllowedGasPrice * 1e9, "CoinFlipUsa: gas price too high");

        // check if the _flipAmount is not large as the tokens balance
        require(_flipAmount <= flipToken.balanceOf(address(this)), "CoinFlipUsa: bet amount too large");

        // player can choose 1 for heads or 0 for tails
        require(_playerChoice <= 1, "CoinFlipUsa: invalid player choice");

        // check if the player has enough allowance
        require(flipToken.allowance(msg.sender, address(this)) >= _flipAmount, "CoinFlipUsa: insufficient allowance");

        // transfer tokens into contract
        require(flipToken.transferFrom(msg.sender, address(this), _flipAmount), "CoinFlipUsa: transfer failed");

        // request a random number from the VRF
        uint256 requestId_ = _requestRandomness();

        // get the CoinFlipInfo struct for the player, this could be populated or empty
        CoinFlipInfo memory coinFlipInfo_ = coinFlipInfo[msg.sender];

        // check if the player has already a game in progress, player can only have one game in progress
        require(
            coinFlipInfo_.result != FlipResult.AWAITINGRESOLUTION, "CoinFlipUsa: game already in progress - be patient"
        );

        uint256 gameIndex_ = gameIndex;

        // populate the CoinFlipInfo struct, all previous values will be overwritten except for the winningStreak

        coinFlipInfo_.betAmount = uint128(_flipAmount);
        coinFlipInfo_.gameIndex = uint32(gameIndex_);
        coinFlipInfo_.requestId = uint64(requestId_);
        coinFlipInfo_.playerChoice = _playerChoice;
        coinFlipInfo_.result = FlipResult.AWAITINGRESOLUTION;

        // save the CoinFlipInfo struct
        coinFlipInfo[msg.sender] = coinFlipInfo_;

        // save the requestId to player address mapping
        requestIdToPlayerAddress[requestId_] = msg.sender;

        gameIndex++;

        emit FlippingCoin(gameIndex_, msg.sender, _flipAmount, _playerChoice);
    }

    /**
     * @notice fulfillRandomWords is called by the VRF Coordinator
     * @param _requestId the requestId that was generated by the VRF Coordinator
     * @param _randomWords the random words that were generated by the VRF Coordinator
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        // The first random word is taken and mod 2 is applied to get a binary result (0 or 1)
        uint256 randomResult_ = _randomWords[0] % 2;

        // Fetch the player's address using the requestId from the mapping
        address playerAddress_ = requestIdToPlayerAddress[_requestId];

        // Ensure that the player's address exists in the mapping. If it's not, revert the transaction.
        require(playerAddress_ != address(0), "CoinFlipUsa: player address not found");

        // Call the _solveGame function to determine the outcome of the game using the player's address and the random result
        _solveGame(playerAddress_, randomResult_);
    }

    function _requestRandomness() internal returns (uint256 requestId_) {
        return vrfCoordinatorV2.requestRandomWords(
            keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords
        );
    }

    /**
     * @notice This function is used to determine the outcome of the game.
     * @param _playerAddress The address of the player who initiated the coin flip.
     * @param _randomValue The random value that was generated by the VRF Coordinator.
     */
    function _solveGame(address _playerAddress, uint256 _randomValue) internal {
        // Fetch the CoinFlipInfo for the player from the mapping.
        CoinFlipInfo memory coinFlipInfo_ = coinFlipInfo[_playerAddress];

        // Ensure that the game is still awaiting resolution. If it's not, revert the transaction.
        require(coinFlipInfo_.result == FlipResult.AWAITINGRESOLUTION, "CoinFlipUsa: game already resolved");

        // Initialize the variable to store the amount the player will win if they win the coin flip.
        uint256 winAmount_;

        // Initialize the variable to store the result of the coin flip.
        FlipResult result_;

        // If the player's choice matches the random value generated by the VRF Coordinator, the player wins.
        if (coinFlipInfo_.playerChoice == _randomValue) {
            // Increment the player's winning streak.
            coinFlipInfo_.winningStreak++;

            // Set the result to indicate that the player has won.
            result_ = FlipResult.PLAYERWINS;

            // Calculate the amount the player wins. This is their bet amount multiplied by the win multiplier edge divided by 1000.
            winAmount_ = coinFlipInfo_.betAmount * winMultiplierEdge / 1000;

            // Transfer the winning amount to the player.
            flipToken.transfer(_playerAddress, winAmount_);

            // If the player's winning streak is greater than the current winning streak, update the current winning streak and the current streak winner.
            if (coinFlipInfo_.winningStreak > winningStreak) {
                winningStreak = coinFlipInfo_.winningStreak;
                currentStreakWinner = _playerAddress;
            }
        } else {
            // If the player's choice does not match the random value, the house wins.
            // Set the result to indicate that the house has won.
            result_ = FlipResult.HOUSEWINS;

            // Reset the player's winning streak to 0.
            coinFlipInfo_.winningStreak = 0;
        }

        // Update the result in the player's CoinFlipInfo.
        coinFlipInfo_.result = result_;

        // Update the player's CoinFlipInfo in the mapping.
        coinFlipInfo[_playerAddress] = coinFlipInfo_;

        // Emit an event to log the resolution of the coin flip.
        emit CoinFlipResolved(
            coinFlipInfo_.gameIndex, _playerAddress, result_, _randomValue, winAmount_, coinFlipInfo_.winningStreak
        );
    }

    // Configuration functions

    /**
     * @notice set the minimum bet size
     * @param _minimumBetSize the minimum bet size
     */
    function setMinimumBetSize(uint256 _minimumBetSize) external onlyOwner {
        minimumBetSize = _minimumBetSize;
        emit MinimumBetSizeUpdated(_minimumBetSize);
    }

    /**
     * @notice set the win multiplier edge
     * @param _winMultiplierEdge the win multiplier edge
     */
    function setWinMultiplierEdge(uint256 _winMultiplierEdge) external onlyOwner {
        // cannot be greater as 2000 (because then the house would lose money)
        require(_winMultiplierEdge <= 2000, "CoinFlipUsa: win multiplier edge too high");
        winMultiplierEdge = _winMultiplierEdge;
        emit WinMultiplierEdgeUpdated(_winMultiplierEdge);
    }

    /**
     * @notice withdraw tokens from the contract
     * @param _tokenAddress the address of the token
     * @param _destination the address of the destination
     * @param _amount the amount of tokens to withdraw
     */
    function withdrawTokensFromContract(address _tokenAddress, address _destination, uint256 _amount)
        external
        onlyOwner
    {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(_destination, _amount);
        emit TokenWithdrawn(_tokenAddress, _amount, _destination);
    }

    /**
     * @notice set the max gas price
     * @param _maxGweiFlip the max gas price in gwei
     */
    function setMaxGweiFlip(uint256 _maxGweiFlip) external onlyOwner {
        maxAllowedGasPrice = _maxGweiFlip;
        emit MaxGweiFlipUpdated(_maxGweiFlip);
    }

    /**
     * @notice pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // View functions

    /**
     * @notice return the max bet amount
     */
    function maxFlipBetAmount() public view returns (uint256) {
        return flipToken.balanceOf(address(this));
    }

    /**
     * @notice return the current game index
     */
    function returnCoinFlipInfo(address _playerAddress) external view returns (CoinFlipInfo memory info_) {
        info_ = coinFlipInfo[_playerAddress];
        require(info_.gameIndex != 0, "CoinFlipUsa: game does not exist");
    }

    /**
     * @notice return the player address by requestId
     * @param _requestId the requestId
     */
    function returnPlayerAddressByRequestId(uint256 _requestId) external view returns (address playerAddress_) {
        playerAddress_ = requestIdToPlayerAddress[_requestId];
    }

    /**
     * @notice refund a game in case of VRF request failed
     * @param _playerAddress the address of the player
     *     @dev this function can only be called by the owner
     *     @dev this function can only be called if the game is still awaiting resolution
     */
    function refundDraw(address _playerAddress) external onlyOwner {
        CoinFlipInfo memory coinFlipInfo_ = coinFlipInfo[_playerAddress];
        require(coinFlipInfo_.result == FlipResult.AWAITINGRESOLUTION, "CoinFlipUsa: game already resolved");
        coinFlipInfo_.result = FlipResult.REFUNDED;
        coinFlipInfo[_playerAddress] = coinFlipInfo_;
        // return the tokens to the player
        flipToken.transfer(_playerAddress, coinFlipInfo_.betAmount);
        emit CoinFlipRefunded(coinFlipInfo_.gameIndex, _playerAddress, coinFlipInfo_.betAmount);
    }

    /**
     * @notice return the current streak winner
     */
    function returnCurrentStreakWinner() external view returns (address currentStreakAddress_, uint256 streakCount_) {
        return (currentStreakWinner, winningStreak);
    }
}
