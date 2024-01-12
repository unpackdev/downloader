// Soulz is the project name
// You are building a staking contract that receives an NFT
// You need to store the address of the tokenID, address of the staker and the block timestamp
// You need to reward the staker with a certain amount of SoulZ tokens lets start with 1 token per day per nft
// Users will need a way to withdraw their staked tokens
// We want to use onERC721Received() hook so that users dont need to pay for an additional approve function
// because users will send the NFT directly to this contract which will trigger the onERC721Received() hook

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721Upgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./console.sol";

contract SoulzStaking is
    Initializable,
    ERC721HolderUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    IERC721Upgradeable public stakingNFT;
    IERC20Upgradeable public rewardToken;

    struct StakingInfo {
        uint256[] tokenIDs;
        uint256[] timestampsStaked;
    }

    mapping(address => StakingInfo) private stakers;
    uint256 public dailyRewardRate;
    uint256 public endTimestamp;
    bool public hasEnded;

    event RewardsClaimed(uint256 tokensClaimed, address addressClaiming);
    event StakingEnded(uint256 timeEnded);

    function initialize(address _stakingNFT, address _rewardToken, address _owner)
        public
        initializer
    {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ERC721Holder_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(UPGRADER_ROLE, _owner);

        stakingNFT = IERC721Upgradeable(_stakingNFT);
        rewardToken = IERC20Upgradeable(_rewardToken);
        dailyRewardRate = 1 ether;
    }

    /**
     * @notice Returns all of the NFT IDs staked by an address
     *
     * @param _staker The stakers address being checked
     */
    function nftsStaked(address _staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakers[_staker].tokenIDs;
    }

    /**
     * @notice Returns if user is a staker or not
     *
     * @param _staker The stakers address being checked
     */
    function isStaking(address _staker) public view returns (bool) {
        return stakers[_staker].tokenIDs.length > 0;
    }

    /**
     * @notice Returns the timestamps for staked NFTs by an address
     *
     * @param _staker The stakers address being checked
     */
    function stakeTimestamps(address _staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakers[_staker].timestampsStaked;
    }

    /**
     * @notice Returns the duration of staking for a single specified staked NFT by an address
     *
     * @param _staker The address of the staker
     * @param _tokenID The ID of the NFT that is staked
     */
    function stakeDuration(address _staker, uint256 _tokenID)
        public
        view
        returns (uint256)
    {
        uint256 startTime = stakers[_staker].timestampsStaked[_tokenID];
        if (startTime > 0) {
            return block.timestamp - startTime;
        } else {
            return 0;
        }
    }

    /**
     * @notice Returns the amount of reward tokens currently on the contract
     */
    function allowance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function stakeBatch(uint256[] memory _tokenIds) public whenNotPaused {
        require(hasEnded == false, "Staking has ended");
        require(_tokenIds.length > 0, "Must stake at least 1 NFT");
        uint256[] memory _values = new uint256[](_tokenIds.length);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            stakers[msg.sender].tokenIDs.push(_tokenIds[i]);
            stakers[msg.sender].timestampsStaked.push(block.timestamp);
            stakingNFT.transferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
        }
    }

    /**
     * @notice The hook called when an ERC721 is received and begins staking
     *
     * Requirements
     * - `msg.sender` must equal the `stakingNFT` address
     * - Staking has not been ended (`hasEnded` = false)
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes memory
    ) public virtual override whenNotPaused returns (bytes4) {
        require(
            msg.sender == address(stakingNFT),
            "Only an authorised NFT contract can stake"
        );
        require(hasEnded == false, "Staking has ended");

        stakers[from].tokenIDs.push(tokenId);
        stakers[from].timestampsStaked.push(block.timestamp);

        return this.onERC721Received.selector;
    }

    /**
     * @notice Withdraws the NFTs that are staked & claims pending rewards
     *
     * Requirements
     * - caller withdrawing NFTs must be the one who originally staked
     * - `reward` claim of user must be less than tokens on contract as per return result of `allowance` function
     * - must remove `tokenID` and `timestampStaked` from `StakingInfo` struct of `msg.sender` for all `_tokenID`s input
     * - must transfer the `stakingNFT` back to `msg.sender`
     * - if `msg.sender` has no more staked NFTs (`stakers[msg.sender].tokenID.length = 0) delete from `stakers` mapping
     * - must transfer correct amount of tokens from `rewardsPending`
     *
     * @param _tokenIDs The IDs of the NFTs that will be unstaked
     */
    function withdraw(uint256[] memory _tokenIDs) public nonReentrant whenNotPaused {
        // Get all rewards
        // uint256 reward = rewardsPending(msg.sender);

        uint256 rewards;
        // For each token Id
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            // This also requires msg.sender to be the staker
            uint256 index = getIndexOf(
                _tokenIDs[i],
                stakers[msg.sender].tokenIDs
            );

            rewards += getRewards(msg.sender, index);

            remove(index, stakers[msg.sender].tokenIDs);
            remove(index, stakers[msg.sender].timestampsStaked);

            stakingNFT.safeTransferFrom(
                address(this),
                msg.sender,
                _tokenIDs[i]
            );
        }

        if (stakers[msg.sender].tokenIDs.length == 0) {
            delete stakers[msg.sender];
        }

        require(rewards <= allowance(), "Reward exceeds tokens available");
        rewardToken.transfer(msg.sender, rewards);
        emit RewardsClaimed(rewards, msg.sender);
    }

    function getIndexOf(uint256 item, uint256[] memory array)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == item) {
                return i;
            }
        }
        revert("Token not found");
    }

    function remove(uint256 index, uint256[] storage array) internal {
        if (index >= array.length) return;

        for (uint256 i = index; i < array.length - 1; i++) {
            array[i] = array[i + 1];
        }
        array.pop();
    }

    /**
     * @notice Determines the amount of pending reward tokens for particular NFTs
     *
     * Requirements
     * - must have `rewardToken` available on the contract
     * - if `hasEnded`, then `endTime` = endTimestamp
     * - should give 1 `totalReward` if have staked 1 NFT for 1 day
     *
     * @param _staker The address of the user
     */
    function getRewards(address _staker, uint256 _index)
        internal
        view
        returns (uint256)
    {
        StakingInfo memory staker = stakers[_staker];
        uint256 endTime;

        if (hasEnded) {
            endTime = endTimestamp;
        } else {
            endTime = block.timestamp;
        }

        uint256 totalStakeTime = endTime - staker.timestampsStaked[_index];
        uint256 dailyTokensInSeconds = dailyRewardRate / 86400; // Daily reward split into seconds

        return dailyTokensInSeconds * totalStakeTime;
    }

    /**
     * @notice Determines the amount of pending reward tokens for all NFTs staked by a user
     *
     * Requirements
     * - must have `rewardToken` available on the contract
     * - if `hasEnded`, then `endTime` = block.timestamp
     * - should give 1 `totalReward` if have staked 1 NFT for 1 day
     *
     * @param _staker The address of the user
     */
    function totalRewardsPending(address _staker)
        public
        view
        returns (uint256)
    {
        StakingInfo memory staker = stakers[_staker];
        uint256 totalReward;
        uint256 endTime;

        if (hasEnded) {
            endTime = endTimestamp;
        } else {
            endTime = block.timestamp;
        }

        for (uint256 i = 0; i < staker.tokenIDs.length; i++) {
            uint256 totalStakeTime = endTime - staker.timestampsStaked[i];
            uint256 dailyTokensInSeconds = dailyRewardRate / 86400; // Daily reward split into seconds
            totalReward += dailyTokensInSeconds * totalStakeTime;
        }

        return totalReward;
    }

    /**
     * @notice Changes the rate of `rewardToken` distributed per NFT per day
     *
     * Requirements
     * - Caller must be `DEFAULT_ADMIN_ROLE`
     *
     * @param _newDaylyRewardRate The new value for `dailyTokensReward`
     */
    function editDailyOutput(uint256 _newDaylyRewardRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        dailyRewardRate = _newDaylyRewardRate;
    }

    /**
     * @dev Should be aware of pending rewards claimable from NFTs still staked
     *
     * @notice Removes specified amount of `rewardToken` from the contract
     *
     * Requirements
     * - Caller must be `DEFAULT_ADMIN_ROLE`
     * - Cannot call while hasEnded = false
     * - Cannot remove more tokens than are on the contract
     *
     * @param _removeAmount The amount of tokens to be taken off the contract
     */
    function removeRewardTokens(uint256 _removeAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(hasEnded == true, "Staking has not ended yet");
        require(
            _removeAmount < allowance(),
            "Cannot withdraw more than on contract"
        );
        rewardToken.transfer(msg.sender, _removeAmount);
    }

    /**
     * @notice Ends staking rewards at current `block.timestamp`
     *
     * Requirements
     * - Caller must be `DEFAULT_ADMIN_ROLE`
     */
    function endStaking(bool _isEnded) public onlyRole(DEFAULT_ADMIN_ROLE) {
        hasEnded = _isEnded;
        endTimestamp = _isEnded == true ? block.timestamp : 0;
        emit StakingEnded(endTimestamp);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}
