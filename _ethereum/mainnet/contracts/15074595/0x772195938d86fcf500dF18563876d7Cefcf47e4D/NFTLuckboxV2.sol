// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./IERC721Receiver.sol"; 
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./MerkleProof.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

/**
 * @title NFT Luckbox v.2.1 raffle-campaign-on-the-go
 */

contract NFTLuckboxV2 is
    VRFConsumerBaseV2,
    ReentrancyGuard,
    Ownable,
    IERC721Receiver,
    ERC721Holder,
    ERC1155Holder
{
    using SafeERC20 for IERC20;
    using Address for address;

    // Reward Info
    struct Reward {
        address assetAddress;
        uint256 tokenId;
        bool is1155;
        address owner;
    }

    // Campaign info
    struct Campaign {
        uint256[] rewards;
        address owner;
        bool useVRF;
        bool ended;
        bool active;
        uint256 seed;
        mapping(address => bool) claimed;
        bytes32 root;
    }

    // Campaign Id => Campaign
    mapping(uint256 => Campaign) public campaigns;
    // Reward Id => Reward
    mapping(uint256 => Reward) public rewards;
    mapping(address => mapping(uint256 => uint256)) public addressToRewardId;
    mapping(uint256 => uint256) private requestIdToCampaignId;

    // VRF-related
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    // Chainlink constants on Polygon
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator;

    // https://docs.chain.link/docs/vrf-contracts/#configurations
    address LINKTOKEN_contract;

    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash;

    // A reasonable default is 100000, but this value could be different
    // on other networks.
    uint32 callbackGasLimit = 100000;
    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    // Storage parameters
    uint64 public s_subscriptionId;
    address s_owner;

    event CampaignCreated(uint256 indexed campaignId, uint256[] rewards);
    event RewardAdded(
        uint256 indexed rewardId,
        address owner,
        address assetAddress,
        uint256 tokenId,
        bool is1155
    );  
    event Claimed(
		address to,
		uint256 campaignId
	);

    constructor(
        address _vrfCoordinator,
        address _LINKTOKEN_contract,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(_LINKTOKEN_contract);

        vrfCoordinator = _vrfCoordinator;
        LINKTOKEN_contract = _LINKTOKEN_contract;
        keyHash = _keyHash;

        // uncomment when deploying
        createNewSubscription();
    }

    // USERS

    /// @notice check whether the given address has held NFTs or not
	/// @param _campaignId the campaign ID to check
	/// @param _address the wallet address that want to check
	/// @param _proof the proof generated off-chain
	/// @return output the result
	function eligible(
		uint256 _campaignId,
		address _address,
		bytes32[] memory _proof
	) external view returns (bool output) {
		output = _eligible(_campaignId, _address, _proof);
	}

	/// @notice check whether the caller can claim a POAP NFT or not
	/// @param _campaignId the campaign to check
	/// @param _rewardId ID of the reward NFT recorded on this contract
	/// @param _proof the proof generated off-chain
	/// @return output the result
	function checkClaim(
		uint256 _campaignId,
		uint256 _rewardId,
		bytes32[] memory _proof
	) external view returns (bool output) {
		output = _checkClaim(_campaignId, _rewardId, _proof);
	}

	/// @notice claim the NFT if the caller is eligible for
	/// @param _campaignId the campaign to check
	/// @param _rewardId ID of the reward NFT recorded on this contract
	/// @param _proof the proof generated off-chain
	function claim(
		uint256 _campaignId,
		uint256 _rewardId,
		bytes32[] memory _proof
	) external nonReentrant {
		require(campaigns[_campaignId].active == true, "Given Event ID is invalid");
		require(campaigns[_campaignId].ended == false, "The event is ended");
		require(
			campaigns[_campaignId].claimed[msg.sender] == false,
			"The caller is already claimed"
		);
		require(
			_checkClaim(_campaignId, _rewardId, _proof) == true,
			"The caller is not eligible to claim the given reward"
		);

		if (rewards[_rewardId].is1155) {
			IERC1155(rewards[_rewardId].assetAddress).safeTransferFrom(
				rewards[_rewardId].owner,
				msg.sender,
				rewards[_rewardId].tokenId,
				1,
				"0x00"
			);
		} else {
			IERC721(rewards[_rewardId].assetAddress).safeTransferFrom(
				rewards[_rewardId].owner,
				msg.sender,
				rewards[_rewardId].tokenId
			);
		}

		campaigns[_campaignId].claimed[msg.sender] = true;

		emit Claimed(
			msg.sender,
			_campaignId
		);
	}

    // CAMPAIGN RUNNERS

    /// @notice create a raffle campaign
    /// @param _campaignId ID of the campaign
    /// @param _useVRF using Chainlink's VRF for the seed number or it
    /// @param _seed if _useVRF is not set, seed number must be provided
    /// @param _rewards array of reward ID to be distributed
    function createCampaign(
        uint256 _campaignId,
        bool _useVRF,
        uint256 _seed,
        uint256[] memory _rewards
    ) external nonReentrant {
        require(campaigns[_campaignId].active == false, "Given ID is occupied");

        campaigns[_campaignId].active = true;
        campaigns[_campaignId].owner = msg.sender;
        campaigns[_campaignId].useVRF = _useVRF;

        if (_useVRF) {
            // Will revert if subscription is not set and funded.
            uint256 s_requestId = COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );

            requestIdToCampaignId[s_requestId] = _campaignId;
        } else {
            campaigns[_campaignId].seed = _seed;
        }

        emit CampaignCreated(_campaignId, _rewards);
    }

    /// @notice close the campaign
	/// @param _campaignId ID of the campaign
    function closeCampaign(
        uint256 _campaignId, bool _isEnd
    ) external nonReentrant {
        require(campaigns[_campaignId].active == true, "Given ID is invalid");
        require(campaigns[_campaignId].owner == msg.sender, "Must be the owner");

        campaigns[_campaignId].ended = _isEnd;
    }

    /// @notice attaches the merkle root to the campaign
	/// @param _campaignId ID of the campaign
    function attachClaim(
        uint256 _campaignId,
        bytes32 _root
    ) external nonReentrant {
        require(campaigns[_campaignId].active == true, "Given ID is invalid");
        require(campaigns[_campaignId].owner == msg.sender, "Must be the owner");

        campaigns[_campaignId].root = _root;
    }

    /// @notice replace reward NFTs to be distributed on the event
	/// @param _campaignId ID of the event
	/// @param _rewards array of the POAP ID
	function updateRewards(uint256 _campaignId, uint256[] memory _rewards)
		external
		nonReentrant 
	{
		require(campaigns[_campaignId].active == true, "Given ID is invalid");
        require(campaigns[_campaignId].owner == msg.sender, "Must be the owner");

		campaigns[_campaignId].rewards = _rewards;
	}

    /// @notice register the asset to be a reward
    /// @param _rewardId ID of the reward
    /// @param _assetAddress NFT contract address
    /// @param _tokenId NFT token ID
    /// @param _is1155 ERC-721 or ERC-1155
    function registerReward(
        uint256 _rewardId,
        address _assetAddress,
        uint256 _tokenId,
        bool _is1155
    ) external nonReentrant {
        require(
            rewards[_rewardId].assetAddress == address(0),
            "Given ID is occupied"
        );
        require(
            addressToRewardId[_assetAddress][_tokenId] == 0,
            "Given asset address and token ID are occupied"
        );

        rewards[_rewardId].assetAddress = _assetAddress;
        rewards[_rewardId].tokenId = _tokenId;
        rewards[_rewardId].is1155 = _is1155;
        rewards[_rewardId].owner = msg.sender;

        addressToRewardId[_assetAddress][_tokenId] = _rewardId;

        emit RewardAdded(
            _rewardId,
            msg.sender,
            _assetAddress,
            _tokenId,
            _is1155
        );
    }

    /// @notice withdraw ERC-20 locked in the contract
	function withdrawERC20(address _tokenAddress, uint256 _amount)
		external
		nonReentrant
		onlyOwner
	{
		IERC20(_tokenAddress).transfer(msg.sender, _amount);
	}

    // Assumes this contract owns link.
    // 1000000000000000000 = 1 LINK
    function topUpSubscription(uint256 amount) external onlyOwner {
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(s_subscriptionId)
        );
    }

    function addConsumer(address consumerAddress) external onlyOwner {
        // Add a consumer contract to the subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
    }

    function removeConsumer(address consumerAddress) external onlyOwner {
        // Remove a consumer contract from the subscription.
        COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
    }

    function cancelSubscription(address receivingWallet) external onlyOwner {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
        s_subscriptionId = 0;
    }

    // PRIVATE FUNCTIONS

    function _checkClaim(
		uint256 _campaignId,
		uint256 _rewardId,
		bytes32[] memory _proof
	) internal view returns (bool) {
		bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _rewardId));
		return
			MerkleProof.verify(_proof, campaigns[_campaignId].root, leaf);
	}

	function _eligible(
		uint256 _campaignId,
		address _address,
		bytes32[] memory _proof
	) internal view returns (bool) {
		require(campaigns[_campaignId].active == true, "Given ID is invalid");

		bytes32 leaf = keccak256(abi.encodePacked(_address));

		return
			MerkleProof.verify(
				_proof,
				campaigns[_campaignId].root,
				leaf
			);
	}

    // callback from Chainlink VRF
    function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        uint256 campaignId = requestIdToCampaignId[requestId];

        if (campaignId != 0) {
            campaigns[campaignId].seed = randomWords[0];
        }
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
}
