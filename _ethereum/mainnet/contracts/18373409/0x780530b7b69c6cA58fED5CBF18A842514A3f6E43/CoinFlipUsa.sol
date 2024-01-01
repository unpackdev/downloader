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
    uint64 public subscriptionId;
    bytes32 public constant keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    IERC20 public immutable flipToken;
    VRFCoordinatorV2Interface public immutable vrfCoordinatorV2;
    LinkTokenInterface public immutable linkToken;

    uint16 constant requestConfirmations = 3;
    uint32 constant callbackGasLimit = 1e5; // todo configure this one
    uint32 constant numWords = 1;
    uint256 public gameIndex = 1;
    uint256 public minimumBetSize;
    uint256 public maxAllowedGasPrice = 20;

    // the house edge is 5% (1/20)
    uint256 public winMultiplierEdge = 1900;

    mapping(uint256 => CoinFlipInfo) public coinFlipInfo;

    mapping(uint256 => uint256) public requestIdToGameIndex;

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

    function flipUsa(uint256 _flipAmount, uint8 _playerChoice) external whenNotPaused returns (uint256 gameIndex_) {
        // check if _flipAmount exceeds minimumBetSize
        require(_flipAmount >= minimumBetSize, "CoinFlipUsa: bet amount too small");

        require(tx.gasprice <= maxAllowedGasPrice * 1e9, "CoinFlipUsa: gas price too high");

        // check if the _flipAmount is not large as the tokens balance
        require(_flipAmount <= maxFlipBetAmount(), "CoinFlipUsa: bet amount too large");

        // player can choose 1 for heads or 0 for tails
        require(_playerChoice <= 1, "CoinFlipUsa: invalid player choice");

        // todo check if the approval is given to this contract
        require(flipToken.allowance(msg.sender, address(this)) >= _flipAmount, "CoinFlipUsa: insufficient allowance");

        // transfer tokens into contract
        require(flipToken.balanceOf(msg.sender) >= _flipAmount, "CoinFlipUsa: insufficient balance");

        // transfer tokens into contract
        require(flipToken.transferFrom(msg.sender, address(this), _flipAmount), "CoinFlipUsa: transfer failed");

        uint256 requestId_ = _requestRandomness();

        gameIndex_ = gameIndex;
        CoinFlipInfo memory coinFlipInfo_;
        coinFlipInfo_.playerAddress = msg.sender;
        coinFlipInfo_.betAmount = uint128(_flipAmount);
        coinFlipInfo_.timestamp = uint32(block.timestamp);
        coinFlipInfo_.requestId = uint96(requestId_);
        coinFlipInfo_.playerChoice = _playerChoice;
        coinFlipInfo_.result = FlipResult.AWAITINGRESOLUTION;

        coinFlipInfo[gameIndex_] = coinFlipInfo_;

        requestIdToGameIndex[requestId_] = gameIndex_;

        gameIndex++;

        emit FlippingCoin(gameIndex_, msg.sender, _flipAmount, _playerChoice);

        return gameIndex_;
    }

    function _requestRandomness() internal returns (uint256 requestId_) {
        return vrfCoordinatorV2.requestRandomWords(
            keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords
        );
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override nonReentrant {
        uint256 randomResult_ = _randomWords[0] % 2;
        uint256 gameIndex_ = requestIdToGameIndex[_requestId];
        _solveGame(gameIndex_, randomResult_);
    }

    function _solveGame(uint256 _gameIndex, uint256 _randomValue) internal {
        CoinFlipInfo memory coinFlipInfo_ = coinFlipInfo[_gameIndex];
        // check if is awaiting resolution
        require(coinFlipInfo_.result == FlipResult.AWAITINGRESOLUTION, "CoinFlipUsa: game already resolved");
        uint256 winAmount_;
        // check if the playersChoice is equal to the randomValue
        // if it is, the player has won
        // if it is not, the house has won
        FlipResult result_;
        if (coinFlipInfo_.playerChoice == _randomValue) {
            result_ = FlipResult.PLAYERWINS;
            winAmount_ = coinFlipInfo_.betAmount * winMultiplierEdge / 1000;
            flipToken.transfer(coinFlipInfo_.playerAddress, winAmount_);
        } else {
            result_ = FlipResult.HOUSEWINS;
        }

        coinFlipInfo_.result = result_;

        coinFlipInfo[_gameIndex] = coinFlipInfo_;

        emit CoinFlipResolved(_gameIndex, result_, _randomValue, winAmount_);
    }

    // Configuration functions

    function setMinimumBetSize(uint256 _minimumBetSize) external onlyOwner {
        minimumBetSize = _minimumBetSize;
        emit MinimumBetSizeUpdated(_minimumBetSize);
    }

    function setWinMultiplierEdge(uint256 _winMultiplierEdge) external onlyOwner {
        // cannot be greater as 2000 (because then the house would lose money)
        require(_winMultiplierEdge <= 2000, "CoinFlipUsa: win multiplier edge too high");
        winMultiplierEdge = _winMultiplierEdge;
        emit WinMultiplierEdgeUpdated(_winMultiplierEdge);
    }

    function withdrawTokensFromContract(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, _amount);
        emit TokenWithdrawn(_tokenAddress, _amount);
    }

    function setMaxGweiFlip(uint256 _maxGweiFlip) external onlyOwner {
        maxAllowedGasPrice = _maxGweiFlip;
        emit MaxGweiFlipUpdated(_maxGweiFlip);
    }

    // View functions

    function maxFlipBetAmount() public view returns (uint256) {
        return flipToken.balanceOf(address(this));
    }

    function returnCoinFlipInfo(uint256 _gameIndex) external view returns (CoinFlipInfo memory info_) {
        info_ = coinFlipInfo[_gameIndex];
        require(info_.playerAddress != address(0), "CoinFlipUsa: game does not exist");
    }

    function returnRequestIdToGameIndex(uint256 _requestId) external view returns (uint256 gameIndex_) {
        gameIndex_ = requestIdToGameIndex[_requestId];
    }

    function refundDraw(uint256 _gameIndex) external onlyOwner {
        CoinFlipInfo memory coinFlipInfo_ = coinFlipInfo[_gameIndex];
        require(coinFlipInfo_.result == FlipResult.AWAITINGRESOLUTION, "CoinFlipUsa: game already resolved");
        coinFlipInfo_.result = FlipResult.REFUNDED;
        coinFlipInfo[_gameIndex] = coinFlipInfo_;
        flipToken.transfer(coinFlipInfo_.playerAddress, coinFlipInfo_.betAmount);
        emit CoinFlipRefunded(_gameIndex, coinFlipInfo_.playerAddress, coinFlipInfo_.betAmount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
