// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

import "./VRFConsumerBase.sol";

import "./LotteryInterface.sol";
import "./GovernanceInterface.sol";

contract Randomness is VRFConsumerBase {
    GovernanceInterface public immutable TrustedGovernance;

    address public immutable vrfCoordinator;
    bytes32 internal immutable keyHash;
    uint128 internal linkFee = 2000000000000000000; // 2 LINK

    struct Request {
        address g;          // Lottery
        uint32 r;           // Round
    }

    mapping (address => mapping (uint32 => uint)) public randomNumbers;
    mapping (bytes32 => Request) public requestIds;

    modifier onlyLotteries() {
        require(TrustedGovernance.lotteryContracts(msg.sender), "Unauthorized");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == TrustedGovernance.owner(), "Only owner");
        _;
    }
    
    /**
     * @dev Constructor inherits VRFConsumerBase
     * 
     * Network: Rinkeby
     * Chainlink VRF Coordinator address: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * LINK token address:                0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     */
    constructor(
        address _governance,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash
    ) public VRFConsumerBase(_vrfCoordinator, _linkToken) {
        TrustedGovernance = GovernanceInterface(_governance);
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
    }

    /** 
     * @dev Requests randomness from a user-provided seed.
     *
     * @param userProvidedSeed Seed for random number generation.
     * @param round Current round in scope of specific lottery.
     */
    function getRandom(uint256 userProvidedSeed, uint32 round) external virtual onlyLotteries {
        require(LINK.balanceOf(address(this)) > linkFee, "Not enough LINK");
        require(randomNumbers[msg.sender][round] == 0, "Round resolution pending");
        
        bytes32 _requestId = requestRandomness(keyHash, linkFee, userProvidedSeed);
        requestIds[_requestId] = Request({g: msg.sender, r: round});

        randomNumbers[msg.sender][round] = 1;
    }

    /**
     * @dev Callback function used by VRF Coordinator.
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(randomness > 0, "Corrupted randomness");

        Request memory request = requestIds[requestId];
        require(randomNumbers[request.g][request.r] == 1, "Round already resolved");

        LotteryInterface(request.g).fulfillRandom(randomness);
        randomNumbers[request.g][request.r] = randomness;
    }

    /** 
     * @dev Used to update Chainlink randomness oracle fee.
     * @param _oracleFee Alarm fee in LINK
     */
    function daoOracleFee(uint128 _oracleFee) external onlyDAO {
        linkFee = _oracleFee;
    }

    /** 
     * @dev Withdraw unused LINK in case of migration / shutdown.
     */
    function daoWithdrawLink() external onlyDAO {
        LINK.transfer(TrustedGovernance.beneficiary(), LINK.balanceOf(address(this)));
    }
}