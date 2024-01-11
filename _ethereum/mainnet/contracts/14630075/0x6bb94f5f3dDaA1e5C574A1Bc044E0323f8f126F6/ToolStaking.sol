// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./IERC1155.sol";
import "./ERC1155Receiver.sol";
import "./ERC1155.sol";

contract ToolStaking is Ownable, ERC1155Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event ChangeExpiration(
        uint256 oldExpirationTime,
        uint256 newExpirationTime
    );
    event ChangeRewardAddress(IERC20 oldRewardAddress, IERC20 newOldAddress);
    event ChangetoolAddress(IERC1155 oldtoolAddress, IERC1155 newtoolAddress);
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
        uint256[] amounts,
        uint256 rewardAmount
    );

    IERC20 rewardToken;
    IERC1155 toolAddress;

    // expiration time of reward providing
    uint256 public expiration;

    uint256 public royaltyPercentage = 25;

    address royaltyClaimer = 0x89cC8F045033CF767BbB93A01e55F83288E061BA;

    uint256 public constant RESTING_TIME = 86400;
    uint256 public constant FATIQUE_TIME = 15 days;

    struct UserInfo {
        uint256 amount;
        uint256 depositedTime;
        uint256 currentClaimedAmount;
        uint256 restingTime;
        uint256 startTimeStamp;
        uint256 fatiqueTime;
        uint256 totalClaimedAmount;
    }

    mapping(uint256 => uint256) public rates;

    mapping(address => mapping(uint256 => UserInfo)) public _userInfo;

    constructor() {}

    function setExpiration(uint256 _expiration) public onlyOwner {
        uint256 oldExpirationTime = expiration;
        expiration = _expiration;
        emit ChangeExpiration(oldExpirationTime, expiration);
    }

    function setNewRoyaltyPercentage(uint256 newRoyaltyPercentage)
        public
        onlyOwner
    {
        royaltyPercentage = newRoyaltyPercentage;
    }

    function changeRewardToken(IERC20 _rewardToken) public onlyOwner {
        IERC20 oldRewardAddress = rewardToken;
        rewardToken = _rewardToken;
        emit ChangeRewardAddress(oldRewardAddress, rewardToken);
    }

    function changetoolAddress(IERC1155 _toolAddress) public onlyOwner {
        IERC1155 oldtoolAddress = toolAddress;
        toolAddress = _toolAddress;
        emit ChangetoolAddress(oldtoolAddress, toolAddress);
    }

    function changeRate(uint256 collectionId, uint256 newRate)
        public
        onlyOwner
    {
        rates[collectionId] = newRate;
    }

    function changeRoyaltyClaimer(address newRoyaltyClaimer) public {
        address oldRoyaltyClaimer = royaltyClaimer;
        royaltyClaimer = newRoyaltyClaimer;
        emit ChangeRoyaltyClaimer(oldRoyaltyClaimer, royaltyClaimer);
    }

    function stakeMany(
        uint256[] calldata collectionIds,
        uint256[] calldata amounts
    ) public {
        address owner = msg.sender;
        require(collectionIds.length == amounts.length, "Invalid Length Sent");
        for (uint256 index = 0; index < collectionIds.length; index++) {
            deposit(collectionIds[index], amounts[index]);
        }
    }

    function reStakeRestedTools(uint256[] calldata collectionIds) public {
        for (uint256 index = 0; index < collectionIds.length; index++) {
            require(
                _userInfo[msg.sender][collectionIds[index]].restingTime <
                    block.timestamp &&
                    _userInfo[msg.sender][collectionIds[index]].restingTime !=
                    0,
                "Tool still is in resting"
            );
            _userInfo[msg.sender][collectionIds[index]].restingTime = 0;
            _userInfo[msg.sender][collectionIds[index]].startTimeStamp = block
                .timestamp;
            _userInfo[msg.sender][collectionIds[index]].fatiqueTime =
                block.timestamp +
                FATIQUE_TIME;
        }
    }

    function deposit(uint256 collectionId, uint256 _amount) internal {
        toolAddress.safeTransferFrom(
            msg.sender,
            address(this),
            collectionId,
            _amount,
            ""
        );
        uint256 previousDeposit = _userInfo[msg.sender][collectionId].amount;

        if (previousDeposit > 0) {
            if (_userInfo[msg.sender][collectionId].fatiqueTime != 0)
                claimReward(collectionId);
            _userInfo[msg.sender][collectionId].depositedTime = block.timestamp;
            _userInfo[msg.sender][collectionId].amount =
                previousDeposit +
                _amount;
        } else {
            _userInfo[msg.sender][collectionId] = UserInfo(
                _amount,
                block.timestamp,
                0,
                0,
                block.timestamp,
                block.timestamp + FATIQUE_TIME,
                0
            );
        }
    }

    function claimReward(uint256 collectionId) public {
        uint256 tempClaimableReward = calculateReward(
            collectionId,
            msg.sender
        ) - _userInfo[msg.sender][collectionId].currentClaimedAmount;

        _userInfo[msg.sender][collectionId]
            .currentClaimedAmount += tempClaimableReward;
        if (tempClaimableReward > 0)
            rewardToken.transfer(msg.sender, tempClaimableReward);
    }

    function claimRewards(uint256[] memory collectionIds) public {
        uint256 totalClaimableAmount;
        uint256[] memory amounts = new uint256[](collectionIds.length);
        for (uint256 index = 0; index < collectionIds.length; index++) {
            uint256 tempClaimableReward = calculateReward(
                collectionIds[index],
                msg.sender
            ) -
                _userInfo[msg.sender][collectionIds[index]]
                    .currentClaimedAmount;

            _userInfo[msg.sender][collectionIds[index]]
                .currentClaimedAmount += tempClaimableReward;
            totalClaimableAmount += tempClaimableReward;
        }
        if (totalClaimableAmount > 0)
            rewardToken.transfer(msg.sender, totalClaimableAmount);
    }

    function restTools(uint256[] calldata collectionIds) public {
        claimRewards(collectionIds);
        for (uint256 index = 0; index < collectionIds.length; index++) {
            rest(collectionIds[index]);
        }
    }

    function rest(uint256 collectionId) internal {
        uint256 previousDeposit = _userInfo[msg.sender][collectionId].amount;
        require(previousDeposit > 0, "No Deposit");
        require(
            _userInfo[msg.sender][collectionId].restingTime < block.timestamp,
            "Tool still is in resting"
        );
        _userInfo[msg.sender][collectionId].restingTime =
            block.timestamp +
            RESTING_TIME;
        _userInfo[msg.sender][collectionId].startTimeStamp = 0;
        _userInfo[msg.sender][collectionId].fatiqueTime = 0;
        _userInfo[msg.sender][collectionId].totalClaimedAmount += _userInfo[
            msg.sender
        ][collectionId].currentClaimedAmount;
        _userInfo[msg.sender][collectionId].currentClaimedAmount = 0;
    }

    function withDrawTools(uint256[] calldata collectionIds) public {
        address owner = msg.sender;
        uint256 length = collectionIds.length;
        uint256[] memory amounts = new uint256[](length);
        for (uint256 index = 0; index < length; index++) {
            require(
                _userInfo[msg.sender][collectionIds[index]].restingTime <
                    block.timestamp &&
                    _userInfo[msg.sender][collectionIds[index]].restingTime !=
                    0,
                "Tool still is in resting"
            );

            amounts[index] = _userInfo[msg.sender][collectionIds[index]].amount;
            require(
                amounts[index] > 0,
                "Amount must be more than or equal to 1"
            );
            delete _userInfo[msg.sender][collectionIds[index]];
        }
        toolAddress.safeBatchTransferFrom(
            address(this),
            msg.sender,
            collectionIds,
            amounts,
            ""
        );
    }

    function claimAbleReward(uint256 collectionId, address account)
        public
        view
        returns (uint256)
    {
        uint256 claimAbleReward = calculateReward(collectionId, account) -
            _userInfo[account][collectionId].currentClaimedAmount;
        return claimAbleReward;
    }

    function calculateReward(uint256 collectionId, address account)
        public
        view
        returns (uint256)
    {
        uint256 depositedAmount = _userInfo[account][collectionId].amount;
        uint256 fatiqueTime = _userInfo[account][collectionId].fatiqueTime;
        if (fatiqueTime == 0) return 0;
        uint256 claimAblePercentage = 100 - checkPercentage(fatiqueTime);
        return
            rates[collectionId]
                .mul(depositedAmount)
                .mul(claimAblePercentage)
                .div(100);
    }

    function checkPercentage(uint256 fatiqueTime)
        public
        view
        returns (uint256)
    {
        if (block.timestamp < fatiqueTime) {
            uint256 percentage = (fatiqueTime - block.timestamp).mul(100).div(
                FATIQUE_TIME
            );
            return percentage;
        }
        return 0;
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

    function emergencyExit() public onlyOwner {
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }
}
