// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./GenArtAccess.sol";
import "./IGenArtInterfaceV3.sol";
import "./GenArtDutchAuctionHouse.sol";

/**
 * @title GenArtSharing
 * @notice It handles the distribution of ETH revenues
 * @notice forked from https://etherscan.io/address/0xbcd7254a1d759efa08ec7c3291b2e85c5dcc12ce#code
 */
contract GenArtSharing is ReentrancyGuard, GenArtAccess {
    using SafeERC20 for IERC20;
    struct UserInfo {
        uint256 shares; // shares of token staked
        uint256[] membershipIds;
        uint256 userRewardPerTokenPaid; // user reward per token paid
        uint256 rewards; // pending rewards
    }

    // Precision factor for calculating rewards and exchange rate
    uint256 public constant PRECISION_FACTOR = 10**18;

    // Reward rate (block)
    uint256 public currentRewardPerBlock;

    // Last update block for rewards
    uint256 public lastUpdateBlock;

    // Current end block for the current reward period
    uint256 public periodEndBlock;

    // Reward per token stored
    uint256 public rewardPerTokenStored;

    // Total existing shares
    uint256 public totalShares;

    mapping(address => UserInfo) public userInfo;

    IERC20 public immutable genartToken;

    address public genartDA;

    address public genartInterface;

    address public genartMembership;

    mapping(uint256 => address) public membershipOwners;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 harvestedAmount);
    event NewRewardPeriod(
        uint256 numberBlocks,
        uint256 rewardPerBlock,
        uint256 reward
    );
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @notice Constructor
     * @param _genartToken address of the token staked (GRNART)
     */
    constructor(
        address _genartMembership,
        address _genartToken,
        address _genartInterace,
        address _genartDA
    ) {
        genartToken = IERC20(_genartToken);
        genartInterface = _genartInterace;
        genartMembership = _genartMembership;
        genartDA = _genartDA;
    }

    /**
     * @dev modifier to only allow DA contract to call functions
     */
    modifier onlyDAContract() {
        require(
            genartDA == msg.sender,
            "GenArtSharing: only DA contract allowed"
        );
        _;
    }

    /**
     * checks requirements for depositing a stake
     */
    function checkDeposit(uint256[] memory membershipIds, uint256 amount)
        internal
        view
    {
        // check required amount of tokens
        require(
            amount >=
                (
                    userInfo[msg.sender].shares == 0
                        ? 4000 * PRECISION_FACTOR
                        : PRECISION_FACTOR
                ),
            "GenArtSharing: amount too small"
        );

        if (userInfo[msg.sender].shares == 0) {
            // if no tokens and memberships staked yet check if required memberships are passed
            if (membershipIds.length == 1) {
                // in case 1 memeberships was passed it has to be a gold one
                require(
                    IGenArtInterfaceV3(genartInterface).isGoldToken(
                        membershipIds[0]
                    ),
                    "GenArtSharing: 5 Standard or 1 Gold membership required"
                );
            } else {
                require(
                    membershipIds.length == 5,
                    "GenArtSharing: 5 Standard or 1 Gold membership required"
                );
            }
        } else {
            // revent if there is an active stake and memberships were passed
            require(
                membershipIds.length == 0,
                "GenArtSharing: no memberships required"
            );
        }
    }

    /**
     * @notice Deposit staked tokens (and collect reward tokens if requested)
     * @param amount amount to deposit (in GENART)
     */
    function deposit(uint256[] memory membershipIds, uint256 amount)
        external
        nonReentrant
    {
        checkDeposit(membershipIds, amount);
        _deposit(membershipIds, amount);
    }

    function _deposit(uint256[] memory membershipIds, uint256 amount) internal {
        // Update reward for user
        _updateReward(msg.sender);

        // send memberships to this contract
        for (uint256 i; i < membershipIds.length; i++) {
            IERC721(genartMembership).transferFrom(
                msg.sender,
                address(this),
                membershipIds[i]
            );
            // save the membership token Ids
            userInfo[msg.sender].membershipIds.push(membershipIds[i]);
            membershipOwners[membershipIds[i]] = msg.sender;
        }

        // Transfer GENART tokens to this address
        genartToken.safeTransferFrom(msg.sender, address(this), amount);

        // Adjust internal shares
        userInfo[msg.sender].shares += amount;
        totalShares += amount;

        emit Deposit(msg.sender, amount);
    }

    function harvest() external nonReentrant {
        // // If pending rewards are null, revert
        uint256 amount = _harvest();
        require(amount > 0, "GenArtSharing: zero rewards to harvest");
    }

    /**
     * @notice Harvest reward tokens that are pending
     */
    function _harvest() internal returns (uint256) {
        // Update reward for user
        _updateReward(msg.sender);

        // Retrieve pending rewards
        uint256 pendingRewards = userInfo[msg.sender].rewards;

        if (pendingRewards == 0) return 0;
        // Adjust user rewards and transfer
        userInfo[msg.sender].rewards = 0;

        // Transfer reward token to sender
        payable(msg.sender).transfer(pendingRewards);

        emit Harvest(msg.sender, pendingRewards);

        return pendingRewards;
    }

    /**
     * @notice Withdraw all staked tokens (and collect reward tokens if requested)
     */
    function withdraw() external nonReentrant {
        require(userInfo[msg.sender].shares > 0, "GenArtSharing: zero shares");
        _withdraw();
    }

    /**
     * @notice Update the reward per block (in rewardToken)
     * @dev Only callable by owner. Owner is meant to be another smart contract.
     */
    function updateRewards(uint256 rewardDurationInBlocks)
        external
        payable
        onlyDAContract
    {
        // Adjust the current reward per block
        if (block.number >= periodEndBlock) {
            currentRewardPerBlock = msg.value / rewardDurationInBlocks;
        } else {
            currentRewardPerBlock =
                (msg.value +
                    ((periodEndBlock - block.number) * currentRewardPerBlock)) /
                rewardDurationInBlocks;
        }

        lastUpdateBlock = block.number;
        periodEndBlock = block.number + rewardDurationInBlocks;

        emit NewRewardPeriod(
            rewardDurationInBlocks,
            currentRewardPerBlock,
            msg.value
        );
    }

    /**
     * @notice Calculate pending rewards (WETH) for a user
     * @param user address of the user
     */
    function calculatePendingRewards(address user)
        external
        view
        returns (uint256)
    {
        return _calculatePendingRewards(user);
    }

    /**
     * @notice Return last block where trading rewards were distributed
     */
    function lastRewardBlock() external view returns (uint256) {
        return _lastRewardBlock();
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user address of the user
     */
    function _calculatePendingRewards(address user)
        internal
        view
        returns (uint256)
    {
        return
            ((userInfo[user].shares *
                (_rewardPerToken() - (userInfo[user].userRewardPerTokenPaid))) /
                PRECISION_FACTOR) + userInfo[user].rewards;
    }

    /**
     * @notice Return last block where rewards must be distributed
     */
    function _lastRewardBlock() internal view returns (uint256) {
        return block.number < periodEndBlock ? block.number : periodEndBlock;
    }

    /**
     * @notice Return reward per share
     */
    function _rewardPerToken() internal view returns (uint256) {
        if (totalShares == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((_lastRewardBlock() - lastUpdateBlock) *
                (currentRewardPerBlock * PRECISION_FACTOR)) /
            totalShares;
    }

    /**
     * @notice Update reward for a user account
     * @param _user address of the user
     */
    function _updateReward(address _user) internal {
        if (block.number != lastUpdateBlock) {
            rewardPerTokenStored = _rewardPerToken();
            lastUpdateBlock = _lastRewardBlock();
        }

        userInfo[_user].rewards = _calculatePendingRewards(_user);
        userInfo[_user].userRewardPerTokenPaid = rewardPerTokenStored;
    }

    /**
     * @notice Withdraw staked tokens and memberships and collect rewards
     */
    function _withdraw() internal {
        // harvest rewards
        _harvest();

        uint256 shares = userInfo[msg.sender].shares;
        uint256[] memory memberships = userInfo[msg.sender].membershipIds;

        // adjust internal shares
        userInfo[msg.sender].shares = 0;
        totalShares -= shares;

        // Transfer GRNART tokens to sender
        genartToken.safeTransfer(msg.sender, shares);
        for (uint256 i = memberships.length; i >= 1; i--) {
            userInfo[msg.sender].membershipIds.pop();
            membershipOwners[memberships[i - 1]] = address(0);
            IERC721(genartMembership).transferFrom(
                address(this),
                msg.sender,
                memberships[i - 1]
            );
        }

        emit Withdraw(msg.sender, shares);
    }

    function emergencyWithdraw(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }

    function getMembershipsOf(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userInfo[user].membershipIds;
    }
}
