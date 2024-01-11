// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./IERC1155.sol";
import "./ERC1155Receiver.sol";
import "./ERC1155.sol";

struct UserInfo {
    uint256 amount;
    uint256 depositTime;
    uint256 previousUnClaimedRewardAmount;
}

contract ChainsawInuStaking is Ownable, ERC1155Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event ChangeExpiration(
        uint256 oldExpirationTime,
        uint256 newExpirationTime
    );
    event ChangeRewardAddress(IERC20 oldRewardAddress, IERC20 newOldAddress);
    event ChangeChainftAddress(IERC1155 oldChainftAddress, IERC1155 newChainftAddress);
    event ChangeRoyaltyClaimer(
        address oldRoyaltyClaimer,
        address newRoyaltyClaimer
    );
    event Deposited(
        address depositer,
        uint256 collectionId,
        uint256 amount,
        uint256 depositedTime
    );
    event WithDraw(
        uint256[] collectionIds,
        uint256[] totalRewardsAmounts,
        uint256 claimedAmount
    );

    event ChangedRoyaltyPercentage(
        uint256 indexed oldRoyaltyPercentage,
        uint256 indexed newRoyaltyPercentage
    );

    IERC1155 ChainftAddress;

    // expiration time of reward providing
    uint256 public expiration;

    address royaltyClaimer = 0x89cC8F045033CF767BbB93A01e55F83288E061BA;

    mapping(uint256 => uint256) public rates;

    mapping(address => mapping(uint256 => UserInfo)) public _userInfo;

    IERC20 public rewardToken;

    uint256 public royaltyPercentage = 20;

    constructor(IERC1155 _ChainftAddress) {
        ChainftAddress = _ChainftAddress;
    }

    function setExpiration(uint256 _expiration) public onlyOwner {
        uint256 oldExpirationTime = expiration;
        expiration = _expiration;
        emit ChangeExpiration(oldExpirationTime, expiration);
    }

    function changeRewardToken(IERC20 _rewardTokenAddress) public onlyOwner {
        IERC20 oldRewardAddress = rewardToken;
        rewardToken = _rewardTokenAddress;
        emit ChangeRewardAddress(oldRewardAddress, _rewardTokenAddress);
    }

    function changeChainftAddress(IERC1155 _ChainftAddress) public onlyOwner {
        IERC1155 oldChainftAddress = ChainftAddress;
        ChainftAddress = _ChainftAddress;
        emit ChangeChainftAddress(oldChainftAddress, ChainftAddress);
    }

    function changeRate(uint256 collectionId, uint256 newRate)
        public
        onlyOwner
    {
        rates[collectionId] = newRate;
    }

    function changeRoyaltyPercentage(uint256 _royaltyPercentage)
        public
        onlyOwner
    {
        uint256 oldRoyaltyPercentage = royaltyPercentage;
        royaltyPercentage = _royaltyPercentage;
        emit ChangedRoyaltyPercentage(oldRoyaltyPercentage, royaltyPercentage);
    }

    function changeRoyaltyClaimer(address newRoyaltyClaimer) public {
        address oldRoyaltyClaimer = royaltyClaimer;
        royaltyClaimer = newRoyaltyClaimer;
        emit ChangeRoyaltyClaimer(oldRoyaltyClaimer, royaltyClaimer);
    }

    function deposit(uint256 _amount, uint256 collectionId) external {
        require(expiration > block.timestamp, "Invalid time stamp");

        ChainftAddress.safeTransferFrom(
            msg.sender,
            address(this),
            collectionId,
            _amount,
            ""
        );
        uint256 previousDeposit = _userInfo[msg.sender][collectionId].amount;

        uint256 rewardAmount = calculateReward(collectionId, msg.sender);
        if (previousDeposit > 0) {
            _userInfo[msg.sender][collectionId]
                .previousUnClaimedRewardAmount = rewardAmount;
            _userInfo[msg.sender][collectionId].depositTime = block.timestamp;
            _userInfo[msg.sender][collectionId].amount =
                previousDeposit +
                _amount;
        } else {
            _userInfo[msg.sender][collectionId] = UserInfo(
                _amount,
                block.timestamp,
                0
            );
        }
        emit Deposited(msg.sender, collectionId, _amount, block.timestamp);
    }

    function calculateReward(uint256 collectionId, address account)
        public
        view
        returns (uint256)
    {
        return
            _userInfo[account][collectionId].previousUnClaimedRewardAmount +
            rates[collectionId] *
            (Math.min(block.timestamp, expiration) -
                _userInfo[account][collectionId].depositTime) *
            _userInfo[account][collectionId].amount;
    }

    function claimRewards(uint256[] memory collectionIds) public {
        claimRewards(collectionIds, msg.sender);
    }

    function distributeRewards(uint256[] memory collectionIds, address account)
        public
        onlyOwner
    {
        claimRewards(collectionIds, account);
    }

    function claimRewards(uint256[] memory collectionIds, address account)
        internal
    {
        uint256 totalClaimableAmount;
        uint256[] memory amounts = new uint256[](collectionIds.length);
        for (uint256 i = 0; i < collectionIds.length; i++) {
            amounts[i] = _userInfo[account][collectionIds[i]].amount;
            require(amounts[i] > 0, "Amount must be more than or equal to 1");
            totalClaimableAmount =
                totalClaimableAmount +
                calculateReward(collectionIds[i], account);
            _userInfo[account][collectionIds[i]]
                .previousUnClaimedRewardAmount = 0;
            _userInfo[account][collectionIds[i]].depositTime = block.timestamp;
        }
        uint256 rewardAmount = totalClaimableAmount
            .mul(100 - royaltyPercentage)
            .div(100);
        uint256 royaltyAmount = totalClaimableAmount.mul(royaltyPercentage).div(
            100
        );
        rewardToken.transfer(account, rewardAmount);
        rewardToken.transfer(royaltyClaimer, royaltyAmount);
    }

    function calculateClaimableRewards(
        uint256[] memory collectionIds,
        address account
    )
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 totalRewardAmount;
        uint256[] memory amounts = new uint256[](collectionIds.length);
        uint256[] memory rewardAmounts = new uint256[](collectionIds.length);
        uint256[] memory royaltyAmounts = new uint256[](collectionIds.length);
        for (uint256 i = 0; i < collectionIds.length; i++) {
            amounts[i] = _userInfo[account][collectionIds[i]].amount;
            uint256 reward = calculateReward(collectionIds[i], account);
            totalRewardAmount += reward;
        }
        return (amounts, rewardAmounts, royaltyAmounts);
    }

    function withdraw(uint256[] memory collectionIds) public {
        uint256 totalClaimableAmount;
        uint256[] memory amounts = new uint256[](collectionIds.length);
        for (uint256 i = 0; i < collectionIds.length; i++) {
            amounts[i] = _userInfo[msg.sender][collectionIds[i]].amount;
            totalClaimableAmount =
                totalClaimableAmount +
                calculateReward(collectionIds[i], msg.sender);
            delete _userInfo[msg.sender][collectionIds[i]];
        }
        uint256 rewardAmount = totalClaimableAmount
            .mul(100 - royaltyPercentage)
            .div(100);
        uint256 royaltyAmount = totalClaimableAmount.mul(royaltyPercentage).div(
            100
        );
        rewardToken.transfer(msg.sender, rewardAmount);
        rewardToken.transfer(royaltyClaimer, royaltyAmount);
        ChainftAddress.safeBatchTransferFrom(
            address(this),
            msg.sender,
            collectionIds,
            amounts,
            ""
        );

        emit WithDraw(collectionIds, amounts, rewardAmount);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId;
    }

    function emergencyExit(IERC20 token) public onlyOwner {
        rewardToken.transfer(msg.sender, token.balanceOf(address(this)));
    }
}
