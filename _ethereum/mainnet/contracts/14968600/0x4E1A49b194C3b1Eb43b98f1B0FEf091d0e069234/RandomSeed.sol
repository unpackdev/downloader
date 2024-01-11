// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./AccessControl.sol";

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract RandomSeed is VRFConsumerBaseV2, AccessControl {

    bytes32 public constant RANDOM_REQUESTER_ROLE = keccak256("RANDOM_REQUESTER_ROLE");

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    // VRF coordinator. For other networks see ...
    // https://docs.chain.link/docs/vrf-contracts/#configurations
    address public constant vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab; // Rinkeby
    // address public constant vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;    // Eth mainnet

    // LINK token contract. For other networks, see ...
    // https://docs.chain.link/docs/vrf-contracts/#configurations
    address public constant link_token_contract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709; // Rinkeby
    // address public constant link_token_contract = 0x514910771AF9Ca656af840dff83E8264EcF986CA;    // Eth mainnet


    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 public keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc; // Rinkeby
    // bytes32 public keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef; // Eth mainnet  200 gwei
//  bytes32 public keyHash = 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92; // Eth mainnet  500 gwei
//  bytes32 public keyHash = 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805; // Eth mainnet 1000 gwei

    // A reasonable default is 100000, but this value could be different
    // on other networks.
    uint32 public constant callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 public constant requestConfirmations = 3;

    // Retrieve 1 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 public constant numWords = 1;

    // Storage parameters
    uint64 public s_subscriptionId;

    struct RandomRequest {
        // uint32 chainId;     //  4 Bytes
        uint48 requestTime;    //  6 Bytes
        uint48 scheduledTime;  //  6 Bytes
        uint48 fullFilledTime; //  6 Bytes
        uint256 requestId;     // 32 Bytes
        uint256 randomNumber;  // 32 Bytes
    }

    mapping(bytes32 => RandomRequest) public randomRequests; // projectName => RandomRequest
    mapping(uint256 => bytes32) public requestId_to_contract; // requestid => chainId + projectName
    bytes32[] public randomRequestsList;

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "caller has not admin role");
        _;
    }

    modifier onlyRandomRequesterRole() {
        require(hasRole(RANDOM_REQUESTER_ROLE, msg.sender), "caller has not RandomRequesterRole");
        _;
    }

    /**
     * @dev CONSTRUCTOR
     */

    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(RANDOM_REQUESTER_ROLE, msg.sender);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link_token_contract);
        // createNewSubscription(); // Create a new subscription when you deploy the contract.
    }

    /**
     * @dev map a chainID and a contract address to a uint256
     * @param _chainId of blockchain where contract is deployed
     * @param _contractAddress contract address
     */
    function chainIdAddressToUint256(uint32 _chainId, address _contractAddress) public pure returns (uint256) {
        return (uint256(_chainId) << 160) | uint256(uint160(_contractAddress));
    }

    function bytesToBytes32(bytes memory source) private pure returns (bytes32 result) {
        if (source.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function stringToBytes32(string memory projectNameString) public pure returns (bytes32) {
        return bytes32(bytes(projectNameString));
    }

    /**
     * @dev Request a random number from Chainlink VRF Oracle
     * @dev Assumes the subscription is funded sufficiently.
     * @dev Will revert if subscription is not set and funded.
     * @param projectNameString name of project
     */
    function requestRandomWords(string memory projectNameString) external onlyRandomRequesterRole {
        bytes32 projectName = stringToBytes32(projectNameString);
        require(randomRequests[projectName].requestId == 0, "random number already requested");

        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        randomRequests[projectName].requestTime = uint48(block.timestamp);
        randomRequests[projectName].requestId = requestId;
        requestId_to_contract[requestId] = projectName;
        randomRequestsList.push(projectName);
    }

    /**
     * @dev Chainlink VRF oracle will call this function to deliver the random number
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        bytes32 projectName = requestId_to_contract[requestId];
        randomRequests[projectName].randomNumber = randomWords[0];
        randomRequests[projectName].fullFilledTime = uint48(block.timestamp);
    }

    function getRandomNumber(string memory projectNameString) public view returns (uint256) {
        bytes32 projectName = stringToBytes32(projectNameString);
        return randomRequests[projectName].randomNumber;
    }

    function getScheduleRequest(string memory projectNameString) public view returns (RandomRequest memory) {
        bytes32 projectName = stringToBytes32(projectNameString);
        return randomRequests[projectName];
    }

    // Create a new subscription when the contract is initially deployed.
    function createNewSubscription() public onlyOwner {
        // Create a subscription with a new subscription ID.
        address[] memory consumers = new address[](1);
        consumers[0] = address(this);
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumers[0]);
    }

    // set or update keyHash
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    // update subscriptionId
    function setSubscriptionId(uint64 _s_subscriptionId) external onlyOwner {
        s_subscriptionId = _s_subscriptionId;
    }


    // Assumes this contract owns link.
    // 1000000000000000000 = 1 LINK
    function topUpSubscription(uint256 amount) external onlyOwner {
        LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
    }

    // Add a consumer contract to the subscription.
    function addConsumer(address consumerAddress) external onlyOwner {
        COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
    }

    // Remove a consumer contract from the subscription.
    function removeConsumer(address consumerAddress) external onlyOwner {
        COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
    }

    // Cancel the subscription and send the remaining LINK to a wallet address.
    function cancelSubscription(address receivingWallet) external onlyOwner {
        COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
        s_subscriptionId = 0;
    }

    // Transfer this contract's funds to an address.
    // 1000000000000000000 = 1 LINK
    function withdraw(uint256 amount, address to) external onlyOwner {
        LINKTOKEN.transfer(to, amount);
    }
}
