// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";

/// @title StellarInu NFT Staking
/// @dev Stake NFTs, earn ETH
/// @author crypt0s0nic
contract NFTStaking is Ownable, ReentrancyGuard {
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // StellarInu NFT
    // CA: TBA
    IERC721 public nft;

    /// @notice Struct to track what user is staking which NFT
    /// @dev tokenIds are all the NFT staked by the staker
    /// @dev amount is the
    /// @dev rewardsEarned is the total reward for the staker till now
    /// @dev rewardsReleased is how much reward has been paid to the staker
    struct Staker {
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenIndex;
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    /// @notice mapping of a staker to its current properties
    mapping(address => Staker) public stakers;

    // @notice mapping from token ID to owner address
    mapping(uint256 => address) public tokenOwner;

    /// @notice total shares, rewards, distributed rewards and reward per each staked nft
    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 public rewardsPerShareMultiplier = 1e36;

    /// @notice sets the rewards to be claimable or not.
    /// Cannot claim if it set to false.
    bool public rewardsClaimable;
    bool initialized;

    /// @notice modifier to require initialized state
    /// Cannot take action if initialized is false
    modifier onlyInitialized() {
        require(initialized == true, "onlyInitialized: NOT_INIT_YET");
        _;
    }

    /// @notice event emitted when a user has staked a token
    event Staked(address indexed user, uint256 amount);

    /// @notice event emitted when a user has unstaked a token
    event Unstaked(address indexed user, uint256 amount);

    /// @notice event emitted when a user claims reward
    event Claimed(address indexed user, uint256 amount);

    constructor() {}

    /// @dev Single gateway to intialize the staking contract after deploying
    /// @dev Sets the contract with the NFT token
    /// @param _nft The ERC721 NFT
    function initStaking(IERC721 _nft) external onlyOwner {
        require(!initialized, "init: initialized");
        nft = _nft;
        initialized = true;
    }

    /// @notice Stake StellarInu NFTs and earn ETH
    /// @dev Rewards will be claimed when staking an additional NFT
    /// @param tokenId The ERC721 tokenId
    function stake(uint256 tokenId) external onlyInitialized nonReentrant {
        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        Staker storage staker = stakers[msg.sender];
        if (staker.amount > 0) {
            _claim(msg.sender);
        }
        totalShares += 1;
        staker.amount += 1;
        staker.totalExcluded = getCumulativeRewards(staker.amount);
        staker.tokenIds.push(tokenId);
        staker.tokenIndex[staker.tokenIds.length - 1];
        tokenOwner[tokenId] = msg.sender;

        emit Staked(msg.sender, tokenId);
    }

    /// @notice Unstake StellarInu NFTs.
    /// @dev Rewards will be claimed when unstaking
    /// @param tokenId The ERC721 tokenId
    function unstake(uint256 tokenId) external onlyInitialized nonReentrant {
        require(msg.sender == tokenOwner[tokenId], "unstake: NOT_STAKED_NFT_OWNER");

        Staker storage staker = stakers[msg.sender];
        if (staker.amount > 0) {
            _claim(msg.sender);
        }

        uint256 lastIndex = staker.tokenIds.length - 1;
        uint256 lastIndexKey = staker.tokenIds[lastIndex];
        uint256 tokenIdIndex = staker.tokenIndex[tokenId];
        staker.tokenIds[tokenIdIndex] = lastIndexKey;
        staker.tokenIndex[lastIndexKey] = tokenIdIndex;
        if (staker.tokenIds.length > 0) {
            staker.tokenIds.pop();
            delete staker.tokenIndex[tokenId];
        }

        totalShares -= 1;
        staker.amount -= 1;
        staker.totalExcluded = getCumulativeRewards(staker.amount);

        // delete staker
        delete tokenOwner[tokenId];
        nft.safeTransferFrom(address(this), msg.sender, tokenId);

        emit Unstaked(msg.sender, tokenId);
    }

    /// @notice Claim the ETH rewards
    function claim() public onlyInitialized nonReentrant {
        require(rewardsClaimable == true, "claim: NOT_CLAIMABLE");
        _claim(msg.sender);
    }

    /// @notice Private function to implementing the ETH rewards claiming
    function _claim(address user) private {
        if (rewardsClaimable != true) return;

        uint256 amount = getUnpaidRewards(user);
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }
        if (amount == 0) return;

        stakers[user].totalRealised += amount;
        stakers[user].totalExcluded = getCumulativeRewards(stakers[user].amount);
        totalDistributed += amount;
        safeTransferETH(user, amount);
        emit Claimed(user, amount);
    }

    /// @notice View the unpaid rewards of a staker
    /// @param user The address of a user
    /// @return The amount of rewards in wei that `user` can withdraw
    function getUnpaidRewards(address user) public view returns (uint256) {
        if (stakers[user].amount == 0) return 0;

        uint256 stakerTotalRewards = getCumulativeRewards(stakers[user].amount);
        uint256 stakerTotalExcluded = stakers[user].totalExcluded;

        if (stakerTotalRewards <= stakerTotalExcluded) return 0;

        return stakerTotalRewards - stakerTotalExcluded;
    }

    /// @notice Private function to view the cumulative rewards of an amount of shares
    /// @param share the amount of shares
    /// @return The cumulative rewards in wei
    function getCumulativeRewards(uint256 share) private view returns (uint256) {
        return (share * rewardsPerShare) / rewardsPerShareMultiplier;
    }

    /// @notice Set the stakable NFT address
    /// @dev _nft must be IERC721
    /// @param _nft NFT address
    function setNFT(IERC721 _nft) external onlyOwner {
        nft = _nft;
    }

    /// @notice Set the rewards to be claimable
    /// @param _enabled is boolean. True means claimable and false means unclaimable
    function setRewardClaimable(bool _enabled) external onlyOwner {
        rewardsClaimable = _enabled;
    }

    /// @dev Getter functions for Staking contract
    /// @dev Get the tokens staked by a user
    function getStakedNFT(address user) external view returns (uint256[] memory) {
        return stakers[user].tokenIds;
    }

    /// @notice Deposit reward
    /// @dev Called by owner only
    function depositRewards() external payable onlyOwner {
        require(totalShares > 0, "depositRewards: NO_SHARES");
        totalRewards += msg.value;
        rewardsPerShare += ((rewardsPerShareMultiplier * msg.value) / totalShares);
    }

    /// @notice Rescue ETH from the contract
    /// @dev Called by owner only
    /// @param receiver The payable address to receive ETH
    /// @param amount The amount in wei
    function withdrawETH(address payable receiver, uint256 amount) external onlyOwner {
        require(receiver != address(0), "withdrawETH: BURN_ADDRESS");
        require(address(this).balance >= amount, "withdrawETH: INSUFFICIENT_BALANCE");
        safeTransferETH(receiver, amount);
    }

    /// @dev Private function that safely transfers ETH to an address
    /// It fails if to is 0x0 or the transfer isn't successful
    /// @param to The address to transfer to
    /// @param value The amount to be transferred
    function safeTransferETH(address to, uint256 value) private {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "FD::safeTransferETH: ETH_TRANSFER_FAILED");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public returns (bytes4) {
        return _ERC721_RECEIVED;
    }
}
