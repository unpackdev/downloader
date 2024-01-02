// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./AccessController.sol";

contract RewardStorage is ERC1155Holder, ERC721Holder, ReentrancyGuard, AccessController {
    using Address for address;

    enum Reward {
        Normal,
        Referral
    }

    /** Storage Structure */
    enum RewardType {
        Token,
        NFT,
        SemiNft,
        ProprieratySemiNft,
        ProprieratyNFT
    }

    struct RewardOwner {
        string campaignId;
        address contractAddress;
        address campaignOwner;
        RewardType rewardType;
        uint256 amountPerWinner;
        uint256 totalWinner;
    }

    mapping(string => mapping(Reward => uint256)) public totalUserClaimByCampaignId;
    mapping(string => mapping(Reward => uint256)) public collectionIdByCampaignId; // For ERC1155
    mapping(string => mapping(Reward => RewardOwner)) public rewardInfoByCampaignId;
    mapping(address => mapping(string => mapping(Reward => bool))) public userClaimedReward; // userWallet -> campaignId -> reward -> bool
    mapping(string => bool) public executedOrderIds;
    address private adminVerifier;

    constructor(address _adminVerifier) {
        adminVerifier = _adminVerifier;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    
    function setAdminVerify(address _adminVerifier) external onlyAdmin {
        adminVerifier = _adminVerifier;
    }

    function createReward(RewardOwner memory _rewardOwner, Reward _reward) external onlyOperator {
        string memory _campaignId = _rewardOwner.campaignId;
        RewardOwner memory existReward = rewardInfoByCampaignId[_campaignId][_reward];
        require(existReward.campaignOwner == address(0), "Reward is existed");
        rewardInfoByCampaignId[_campaignId][_reward] = _rewardOwner;
    }

    function getRewardInfo(string calldata _campaignId, Reward _reward) external onlyOperator view returns (RewardOwner memory, uint256) {
        return (rewardInfoByCampaignId[_campaignId][_reward], totalUserClaimByCampaignId[_campaignId][_reward]);
    }

    function isOrderExcuted(string calldata _orderId) external onlyOperator view returns (bool) {
        return executedOrderIds[_orderId];
    }

    function setOrderExcuted(string calldata _orderId, bool _excuted) external onlyOperator {
        executedOrderIds[_orderId] = _excuted;
    }

    function isUserClaimReward(string calldata _campaignId, address _user, Reward _reward) external onlyOperator view returns (bool) {
        return userClaimedReward[_user][_campaignId][_reward];
    }

    function setUserClaimReward(string calldata _campaignId, address _user, Reward _reward, bool _excuted) external onlyOperator {
        userClaimedReward[_user][_campaignId][_reward] = _excuted;
    }

    function getTotalUserClaimInCampaign(string calldata _campaignId, Reward _reward) external onlyOperator view returns (uint256) {
        return totalUserClaimByCampaignId[_campaignId][_reward];
    }

    function setTotalUserClaimInCampaign(string calldata _campaignId, Reward _reward, uint256 _total) external onlyOperator {
        totalUserClaimByCampaignId[_campaignId][_reward] = _total;
    }

    function getCollectionIdByCampaign(string calldata _campaignId, Reward _reward) external onlyOperator view returns (uint256) {
        return collectionIdByCampaignId[_campaignId][_reward];
    }

    function setCollectionIdByCampaign(string calldata _campaignId, Reward _reward, uint256 _collectionId) external onlyOperator {
        collectionIdByCampaignId[_campaignId][_reward] = _collectionId;
    }

    function getAdminVerifier() external view returns (address){
        return adminVerifier;
    }

    function setUserClaim(string calldata _orderId, string calldata _campaignId, address _user, Reward _reward, uint256 _amount) external onlyOperator {
        executedOrderIds[_orderId] = true;
        totalUserClaimByCampaignId[_campaignId][_reward] += _amount;
        userClaimedReward[_user][_campaignId][_reward] = true;
    }

    function _validateContractAddress(address contractAddress) private view {
        require(
            contractAddress != address(0),
            "Address can not be zero address"
        );
        require(contractAddress.isContract(), "Address must be a contract");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}