// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./IERC20Upgradeable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./KeeperCompatible.sol";
import "./console.sol";
import "./SupplyBoxes.sol";

/**
 * @title SupplyBoxMinter
 * @dev Takes payment and mints random supply boxes - with Chainlink integration!
 */
contract SupplyBoxMinter is
    Ownable,
    ReentrancyGuard,
    VRFConsumerBaseV2,
    KeeperCompatibleInterface
{
    uint256 private MAX_MINT_QUEUE_LENGTH;

    address public teamLinkWallet; // to store LINK to pay for Chainlink oracle.

    // ERC1155 token being minted by this contract
    SupplyBoxes public supplyBoxes;

    // ERC20 token to be taken in as payment
    IERC20Upgradeable public paymentToken;

    // Prices
    uint256 public tokenPricePerMint;
    uint256 public ethPricePerMint;
    uint256 public gasTariffPerMint; // 0.01 ETH to top up LINK balance

    uint256 public maxTokenId; // 5 types of tokens. Starts at id 1.
    uint256[] public weightingArray;
    uint256 public totalWeighting;

    /************************/
    /************************/
    /*** Chainlink Config ***/
    /************************/
    /************************/

    /** Rinkeby **/
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    VRFCoordinatorV2Interface COORDINATOR;

    // TODO: pass these in via constructor / deploy script.
    uint64 public s_subscriptionId;
    address public vrfCoordinator;
    bytes32 public keyHash;

    // ~~ 20k gas per write.
    // logic has potentially 500 * 3 writes = minimum ~ 30m...
    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;

    /************************/
    /************************/
    /*** Async Mint Queue ***/
    /************************/
    /************************/

    uint256 public batchMintNonce;
    mapping(uint256 => address[]) public pendingMinters;
    uint256[] public pendingNoncesToProcess;
    mapping(uint256 => uint256) public vrfIdToNonce;
    mapping(uint256 => uint256) public nonceToVrfId;
    mapping(address => uint256) public pendingBatchNonce; // for fetch last request for user
    mapping(uint256 => bool) public nonceCompleted; // display if request is complete.

    // Note for frontend implementation
    // If current batch nonce == user's batch nonce, status = pending.
    // if nonceCompleted[userBatchNonce] == true, status = complete.
    // if current batch > user batch, status = processing.

    event FulfillCallbackMint(uint256 nftId, address receiver);
    event BatchNonceFilled(uint256 nonceId);
    event FulfillLoop(uint256 batchNonce, uint256 wordsLen);

    /************************/
    /************************/
    /**** Initialization ****/
    /************************/
    /************************/

    receive() external payable {}

    constructor(
        address _supplyBoxes,
        address _paymentToken,
        address _teamLinkWallet,
        address _vrfCoordinator, // = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
        bytes32 _keyHash, // 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc
        uint64 _s_subscriptionId // 3287
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        // General initialization
        MAX_MINT_QUEUE_LENGTH = 10;
        batchMintNonce = 0;

        // Internal initialization
        setPrice(5000e18, 1e17, 1e16);
        setMaxTokenId(5);
        weightingArray = [150, 3, 150, 300, 420];
        totalWeighting = 1023;

        // Chainlink initialization
        vrfCoordinator = _vrfCoordinator;
        setChainlinkVariables(_s_subscriptionId, _keyHash, 250e3, 3);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        setAddresses(_supplyBoxes, _paymentToken, _teamLinkWallet);
        keeperTriggerInterval = 100;
        lastKeeperTrigger = 0;
    }

    /************************/
    /************************/
    /**** ADMIN FUNCTIONS ***/
    /************************/
    /************************/

    function setPrice(
        uint256 tokenPrice,
        uint256 ethPrice,
        uint256 gasPrice
    ) public onlyOwner {
        tokenPricePerMint = tokenPrice;
        ethPricePerMint = ethPrice;
        gasTariffPerMint = gasPrice;
    }

    function setMaxTokenId(uint256 _maxTokenId) public onlyOwner {
        maxTokenId = _maxTokenId;
    }

    function setAddresses(
        address newSupplyBoxAddr,
        address newTokenAddr,
        address newTeamLinkWallet
    ) public onlyOwner {
        supplyBoxes = SupplyBoxes(newSupplyBoxAddr);
        paymentToken = IERC20Upgradeable(newTokenAddr);
        teamLinkWallet = newTeamLinkWallet;
    }

    function setNftWeighting(uint256[] calldata weights) external onlyOwner {
        uint256 totWeight = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            totWeight += weights[i];
        }
        totalWeighting = totWeight;
        weightingArray = weights;
    }

    function withdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawErc20() external onlyOwner {
        uint256 balance = paymentToken.balanceOf(address(this));
        paymentToken.transfer(msg.sender, balance);
    }

    function setSupplyBoxNFTOwnership(address newSupplyBoxOwner)
        external
        onlyOwner
    {
        supplyBoxes.transferOwnership(newSupplyBoxOwner);
    }

    function setChainlinkVariables(
        uint64 _s_subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) public onlyOwner {
        s_subscriptionId = _s_subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
    }

    function adminFulfillRandomWords(
        // LINK failsafe
        uint256 requestId,
        uint256[] calldata randomWords
    ) external onlyOwner {
        fulfillRandomWords(requestId, randomWords);
    }

    /************************/
    /************************/
    /*** PUBLIC FUNCTIONS ***/
    /************************/
    /************************/

    function mintRandomSupplyBoxWithErc20(uint256 amount)
        external
        payable
        nonReentrant
    {
        require(msg.value >= gasTariffPerMint * amount, "Not enough Gas");
        // Note: user must approve erc20 token spend;
        paymentToken.transferFrom(msg.sender, address(this), tokenPricePerMint * amount);
        _queueMinter(amount);
    }

    function mintRandomSupplyBoxWithEth(uint256 amount)
        external
        payable
        nonReentrant
    {
        require(
            msg.value >= (ethPricePerMint + gasTariffPerMint) * amount,
            "Value below price"
        );
        _queueMinter(amount);
    }

    /************************/
    /** Chainlink Functions */
    /************************/
    // These functions are in the order that they get executed
    // via "webhooks" from Chainlink

    uint256 public keeperTriggerInterval;
    uint256 public lastKeeperTrigger;

    function setBlocksBetweenKeeperTrigger(uint256 blocks) external onlyOwner {
        keeperTriggerInterval = blocks;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        return (_shouldSendBatch(), "");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override nonReentrant {
        if (_shouldSendBatch()) {
            requestRandomWords();
            lastKeeperTrigger = block.number;
        }
    }

    function requestRandomWords() internal {
        // Handle full queues first.
        for (uint16 i = 0; i < pendingNoncesToProcess.length; i++) {
            uint256 nonceToProcess = pendingNoncesToProcess[i];
            _requestRandomWord(nonceToProcess);
            
        }
        _requestRandomWord(batchMintNonce);
        delete pendingNoncesToProcess;
        batchMintNonce++;
    }

    function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        uint256 batchNonce = vrfIdToNonce[requestId];
        emit FulfillLoop(batchNonce, randomWords.length);
        require(
            !nonceCompleted[batchNonce],
            "This batch has already been minted."
        );
        // mint
        for (uint16 i = 0; i < randomWords.length; i++) {
            uint256 nftId = _getWeightedNftId(randomWords[i]);
            address reciever = pendingMinters[batchNonce][i];
            emit FulfillCallbackMint(nftId, reciever);
            if (reciever == 0x0000000000000000000000000000000000000000) {
                continue;
            }
            _performMint(reciever, nftId);
        }
        nonceCompleted[batchNonce] = true;
    }

    /************************/
    /**** Internal Funcs ****/
    /************************/

    function _queueMinter(uint256 amount) internal {
        payable(teamLinkWallet).transfer(gasTariffPerMint * amount);
        for (uint16 i = 0; i < amount; i++) {
            if (
                pendingMinters[batchMintNonce].length >= MAX_MINT_QUEUE_LENGTH
            ) {
                pendingNoncesToProcess.push(batchMintNonce);
                emit BatchNonceFilled(batchMintNonce);
                batchMintNonce++;
            }
            pendingMinters[batchMintNonce].push(msg.sender);
        }
        pendingBatchNonce[msg.sender] = batchMintNonce;
    }

    function _requestRandomWord(uint256 nonceToProcess) internal {
        uint32 mintersInQueue = uint32(pendingMinters[nonceToProcess].length);
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            mintersInQueue
        );
        vrfIdToNonce[requestId] = nonceToProcess;
        nonceToVrfId[nonceToProcess] = requestId; // for manual failsafe
    }

    function _performMint(address receiver, uint256 nftId) internal {
        supplyBoxes.adminMint(receiver, nftId, 1);
    }

    function _shouldSendBatch() internal view returns (bool) {
        // If Full queue, ret true.
        if (pendingNoncesToProcess.length > 0) {
            return true;
        }
        // If queue close to full, send.
        uint256 mintersInQueue = pendingMinters[batchMintNonce].length;
        if (mintersInQueue > MAX_MINT_QUEUE_LENGTH - 3) {
            // 500 is max chainlink will accept
            return true;
        }
        // else, if interval and pending minters, send.
        if ((block.number - lastKeeperTrigger) > keeperTriggerInterval) {
            return mintersInQueue > 0;
        }
        return false;
    }

    function _getWeightedNftId(uint256 rand) internal view returns (uint256) {
        uint256 weightsConsidered = 0;
        for (uint16 i = 0; i < weightingArray.length - 1; i++) {
            weightsConsidered += weightingArray[i];
            if (
                rand <
                ((weightsConsidered * 1e9) / totalWeighting) *
                    (type(uint256).max / 1e9)
            ) {
                return i + 1;
            }
        }
        // Don't loop through last one.
        return weightingArray.length;
    }
}
