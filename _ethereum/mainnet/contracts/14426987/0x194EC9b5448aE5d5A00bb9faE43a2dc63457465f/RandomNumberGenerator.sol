// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

import "./IRandomNumberGenerator.sol";
import "./ITokenStandLottery.sol";

contract RandomNumberGenerator is VRFConsumerBaseV2, IRandomNumberGenerator, Ownable {
    using SafeERC20 for IERC20;

    address public tokenstandLottery;
    bytes32 public keyHash;
    uint256 public latestRequestId;
    uint32 public randomResult;
    uint256 public latestLotteryId;
    LinkTokenInterface LINKTOKEN;
    VRFCoordinatorV2Interface COORDINATOR;

    // A reasonable default is 100000, but this value could be different
    // on other networks.
    uint32 callbackGasLimit = 100000;

    // Storage parameters
    uint64 public s_subscriptionId;
    uint16 requestConfirmations = 3;
    uint32 numWords =  7;

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed before the lottery.
     * Once the lottery contract is deployed, setLotteryAddress must be called.
     * https://docs.chain.link/docs/vrf-contracts/
     * @param _vrfCoordinator: address of the VRF coordinator
     * @param _linkToken: address of the LINK token
     */
    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint64 _subscriptionId) VRFConsumerBaseV2(_vrfCoordinator) {
        //
        keyHash = _keyHash;
        LINKTOKEN = LinkTokenInterface(_linkToken);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_subscriptionId = _subscriptionId;
    }

    /**
     * @notice Request randomness from a user-provided seed
     */
    function requestRandomWords() external override {
        require(msg.sender == tokenstandLottery, "Only TokenStandLottery");
        require(keyHash != bytes32(0), "Must have valid key hash");

        latestRequestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
    );
    }

    /**
     * @notice Change the keyHash
     * @param _keyHash: new keyHash
     */
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    /**
     * @notice Set the address for the TokenStandLottery
     * @param _tokenstandLottery: address of the TokenStand lottery
     */
    function setLotteryAddress(address _tokenstandLottery) external onlyOwner {
        tokenstandLottery = _tokenstandLottery;
    }

    /**
     * @notice Set the subscriptionId on ChainlinkVRF
     * @param _s_subscriptionId: address of the TokenStand lottery
     */
    function setSubscriptionId(uint64 _s_subscriptionId) external onlyOwner {
        s_subscriptionId = _s_subscriptionId;
    }

    /**
     * @notice It allows the admin to withdraw tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function withdrawTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
    }

    /**
     * @notice View latestLotteryId
     */
    function viewLatestLotteryId() external view override returns (uint256) {
        return latestLotteryId;
    }

    /**
     * @notice View random result
     */
    function viewRandomResult() external view override returns (uint32) {
        return randomResult;
    }

    /**
     * @notice Callback function used by ChainLink's VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(latestRequestId == requestId, "Wrong requestId");
        randomResult = uint32(1000000 + (randomWords[0] % 1000000));
        latestLotteryId = ITokenStandLottery(tokenstandLottery).viewCurrentLotteryId();
    }
}