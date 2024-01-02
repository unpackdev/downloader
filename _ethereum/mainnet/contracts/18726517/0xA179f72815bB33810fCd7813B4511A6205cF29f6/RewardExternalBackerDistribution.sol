// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./RewardStorage.sol";
import "./AccessController.sol";

contract RewardExternalBackerDistribution is ERC721Holder, ERC1155Holder, ReentrancyGuard, AccessController {
    using ECDSA for bytes32;
    using Address for address;

    event DepositRewardExternal(address indexed campaignOwner, string campaignId, uint256 reward, uint256 timestamp);
    event ClaimedRewardExternal(address indexed user, string campaignId, uint256 reward, uint256[] tokenIds, uint256 amount, uint256 rewardType, uint256 timestamp);
    event OwnerWithdrawRewardExternal(address indexed owner, string campaignId, uint256 reward, uint256 rewardType, uint256 remainReward, uint256 timestamp);

    // avoid stack too deep
    struct CampaignType {
        string campaignId;
        RewardStorage.Reward reward;
    }

    struct ClaimInfo {
        uint256[] tokenIds;
        uint256 amount;
    }

    RewardStorage private rewardStorage;
    uint256 private timeout = 2 minutes;
    mapping(string => mapping(RewardStorage.Reward => uint256)) public indexOfTokenIdByCampaignId; 

    constructor(address _rewardStorage) {
        rewardStorage = RewardStorage(_rewardStorage);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setTimeout(uint256 _timeout) external onlyAdmin {
        timeout = _timeout;
    }

    function getIndexOfTokenIdByCampaignId(string calldata _campaignId, RewardStorage.Reward _reward) public view returns(uint256){
        return indexOfTokenIdByCampaignId[_campaignId][_reward];
    }

    function depositRewardExternal(
        RewardStorage.RewardOwner calldata _rewardOwner,
        RewardStorage.Reward _reward,
        uint256[] calldata _tokenIds,
        uint256 _collectionId,
        string calldata _orderId,
        bytes calldata _ownerSignature,
        bytes calldata _rewardSignature
    ) public nonReentrant {
        _validateContractAddress(_rewardOwner.contractAddress);
        require(_rewardOwner.campaignOwner != address(0), "Owner not be zero address");
        require(_msgSender() == _rewardOwner.campaignOwner, "Only owner can deposit reward");
        require(_rewardOwner.amountPerWinner > 0 && _rewardOwner.totalWinner > 0, "totalWinner and amountPerWinner must be greater than 0");
        require(!rewardStorage.isOrderExcuted(_orderId), "OrderId is excuted");
        CampaignType memory _campaignType = CampaignType({
            campaignId: _rewardOwner.campaignId,
            reward: _reward
        });
        _validateSignatureVerifyOwner(_ownerSignature, _orderId, _campaignType, _msgSender(), _collectionId);
        _validateSignatureVerifyReward(_rewardSignature, _rewardOwner, _orderId, _tokenIds);
        rewardStorage.setOrderExcuted(_orderId, true);
        rewardStorage.createReward(_rewardOwner, _reward);
        uint256 totalAmount = _rewardOwner.totalWinner * _rewardOwner.amountPerWinner;
        RewardStorage.RewardType _rewardType = _rewardOwner.rewardType;
        if(_rewardType == RewardStorage.RewardType.ProprieratyNFT){
            _batchTransfer(_rewardOwner.contractAddress, _msgSender(), address(this), _tokenIds);
        } else if(_rewardType == RewardStorage.RewardType.ProprieratySemiNft){
            rewardStorage.setCollectionIdByCampaign(_campaignType.campaignId, _campaignType.reward, _collectionId);
            IERC1155(_rewardOwner.contractAddress).safeTransferFrom(_msgSender(), address(this), _collectionId, totalAmount, "");
        }
        emit DepositRewardExternal(_msgSender(), _rewardOwner.campaignId, uint256(_campaignType.reward), block.timestamp);
    }
 
    function claimReward(
        CampaignType calldata _campaignType,
        ClaimInfo calldata _claimInfo,
        string calldata _orderId,
        bytes calldata _signature,
        uint256 _timestamp
    ) external nonReentrant {
        require(_timestamp + timeout > block.timestamp, "Timeout!");
        (RewardStorage.RewardOwner memory existReward, uint256 _totalUserClaimInCampaign) = rewardStorage.getRewardInfo(_campaignType.campaignId, _campaignType.reward);
        require(_msgSender() != existReward.campaignOwner, "Owner can not claim reward");
        require(existReward.campaignOwner != address(0), "Reward is not existed");
        require(_totalUserClaimInCampaign + 1 <= existReward.totalWinner, "Reward in campaign is over");
        require(!rewardStorage.isUserClaimReward(_campaignType.campaignId, _msgSender(), _campaignType.reward), "User has already claimed");
        require(!rewardStorage.isOrderExcuted(_orderId), "OrderId is excuted");
        require(_validateSignatureClaim(_signature, _campaignType.campaignId, _orderId, uint256(_campaignType.reward), _claimInfo, _timestamp, _msgSender()), "Invalid Input");
        rewardStorage.setUserClaim(_orderId, _campaignType.campaignId, _msgSender(), _campaignType.reward, _claimInfo.amount);
        if(existReward.rewardType == RewardStorage.RewardType.ProprieratyNFT){
            require(_claimInfo.tokenIds.length == _claimInfo.amount, "_tokenIds length and _amount mismatch");
            indexOfTokenIdByCampaignId[ _campaignType.campaignId][_campaignType.reward] += _claimInfo.amount;
            _batchTransfer(existReward.contractAddress, address(this), _msgSender(), _claimInfo.tokenIds);
        } else if(existReward.rewardType == RewardStorage.RewardType.ProprieratySemiNft){
            uint256 _collectionId = rewardStorage.getCollectionIdByCampaign(_campaignType.campaignId, _campaignType.reward);
            IERC1155(existReward.contractAddress).safeTransferFrom(address(this), _msgSender(), _collectionId, existReward.amountPerWinner * _claimInfo.amount, "");
        }
        emit ClaimedRewardExternal(_msgSender(), _campaignType.campaignId, uint256(_campaignType.reward), _claimInfo.tokenIds, _claimInfo.amount, uint256(existReward.rewardType), block.timestamp);
    }

    function withdrawRewardExternal(
        CampaignType calldata _campaignType, 
        string calldata _orderId,
        bytes calldata _signature,
        uint256[] calldata _tokenIds,
        uint256 _timestamp
    ) external nonReentrant {
        require(_timestamp + timeout > block.timestamp, "Timeout!");
        (RewardStorage.RewardOwner memory existReward, uint256 _totalUserClaimInCampaign) = rewardStorage.getRewardInfo(_campaignType.campaignId, _campaignType.reward);
        require(existReward.campaignOwner == _msgSender(), "User is not the owner of campaign");
        require(!rewardStorage.isOrderExcuted(_orderId), "OrderId is excuted");
        _validateSignatureToWithdraw(_signature, _orderId, _campaignType, _tokenIds, _timestamp);
        require(existReward.rewardType == RewardStorage.RewardType.ProprieratyNFT || existReward.rewardType == RewardStorage.RewardType.ProprieratySemiNft, "Invalid rewardType");
        uint256 remainReward = (existReward.totalWinner - _totalUserClaimInCampaign) * existReward.amountPerWinner;
        require(remainReward > 0, "Withdraw: Reward in campaign is over");
        rewardStorage.setTotalUserClaimInCampaign(_campaignType.campaignId, _campaignType.reward, existReward.totalWinner); // consider all reward is claimed
        rewardStorage.setOrderExcuted(_orderId, true);
        if(existReward.rewardType == RewardStorage.RewardType.ProprieratyNFT){
            indexOfTokenIdByCampaignId[ _campaignType.campaignId][_campaignType.reward] += _tokenIds.length;
            _batchTransfer(existReward.contractAddress, address(this), _msgSender(), _tokenIds);
        } else if(existReward.rewardType == RewardStorage.RewardType.ProprieratySemiNft){
            uint256 _collectionId = rewardStorage.getCollectionIdByCampaign(_campaignType.campaignId, _campaignType.reward);
            IERC1155(existReward.contractAddress).safeTransferFrom(address(this), _msgSender(), _collectionId, remainReward, "");
        }
        emit OwnerWithdrawRewardExternal(_msgSender(), _campaignType.campaignId, uint256(_campaignType.reward), uint256(existReward.rewardType), remainReward, block.timestamp);
    }

    /*** Private function*/
    function _validateContractAddress(address contractAddress) private view {
        require(
            contractAddress != address(0),
            "Address can not be zero address"
        );
        require(contractAddress.isContract(), "Address must be a contract");
    }

    function _validateSignatureClaim(
        bytes calldata _signature, 
        string calldata _campaignId,
        string calldata _orderId,
        uint256 _reward,
        ClaimInfo calldata _claimInfo,
        uint256 _timestamp,
        address _address
    ) private view returns (bool) {
        address _adminVerifier = rewardStorage.getAdminVerifier();
        bytes32 hashValue = keccak256(
            abi.encodePacked(_orderId, _campaignId, _address, uint256(_reward), _claimInfo.tokenIds, _claimInfo.amount, _timestamp)
        );
        address recover = hashValue.toEthSignedMessageHash().recover(_signature);
        return recover == _adminVerifier;
    }

    function _validateSignatureVerifyOwner(
        bytes calldata _ownerSignature, 
        string calldata _orderId,
        CampaignType memory _campaignType,
        address _owner,
        uint256 _collectionId
    ) private view {
        address _adminVerifier = rewardStorage.getAdminVerifier();
        bytes32 verifyOwner = keccak256(
            abi.encodePacked(_orderId, _campaignType.campaignId, _owner, uint256(_campaignType.reward), _collectionId)
        );
        address recoverOwner = verifyOwner.toEthSignedMessageHash().recover(_ownerSignature);
        require(recoverOwner == _adminVerifier, "Invalid owner");
    }

    function _validateSignatureVerifyReward(
        bytes calldata _rewardSignature,
        RewardStorage.RewardOwner calldata _rewardOwner,
        string calldata _orderId,
        uint256[] calldata _tokenIds
    ) private view {
        address _adminVerifier = rewardStorage.getAdminVerifier();
        bytes32 verifyReward = keccak256(
            abi.encodePacked(_orderId, _rewardOwner.amountPerWinner, _rewardOwner.totalWinner, uint256(_rewardOwner.rewardType), _rewardOwner.contractAddress, _tokenIds)
        );
        address recoverReward = verifyReward.toEthSignedMessageHash().recover(_rewardSignature);
        require(recoverReward == _adminVerifier, "Invalid reward");
    }

    function _validateSignatureToWithdraw(
        bytes calldata _signature,
        string calldata _orderId,
        CampaignType memory _campaignType,
        uint256[] calldata _tokenIds,
        uint256 _timestamp
    ) private view {
        address _adminVerifier = rewardStorage.getAdminVerifier();
        bytes32 verifyReward = keccak256(
            abi.encodePacked(_orderId, _campaignType.campaignId, uint256(_campaignType.reward), _tokenIds, _timestamp)
        );
        address recoverReward = verifyReward.toEthSignedMessageHash().recover(_signature);
        require(recoverReward == _adminVerifier, "Invalid input withdraw");
    }

    function _batchTransfer(address _contractAddress, address _sender, address _receiver, uint256[] calldata _tokenIds) private {
        require(_tokenIds.length > 0, "Invalid tokenIds array");
        for (uint256 index; index < _tokenIds.length; index++) {
            IERC721(_contractAddress).safeTransferFrom(_sender, _receiver, _tokenIds[index]);
        }
    }

    /** Support interface */
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