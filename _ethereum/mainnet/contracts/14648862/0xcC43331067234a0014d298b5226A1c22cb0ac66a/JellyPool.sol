pragma solidity 0.8.6;

/**
* @title Jelly Pool V1.3:
*
*              ,,,,
*            g@@@@@@K
*           l@@@@@@@@P
*            $@@@@@@@"                   l@@@  l@@@
*             "*NNM"                     l@@@  l@@@
*                                        l@@@  l@@@
*             ,g@@@g        ,,gg@gg,     l@@@  l@@@ ,ggg          ,ggg
*            @@@@@@@@p    g@@@EEEEE@@W   l@@@  l@@@  $@@g        ,@@@Y
*           l@@@@@@@@@   @@@P      ]@@@  l@@@  l@@@   $@@g      ,@@@Y
*           l@@@@@@@@@  $@@D,,,,,,,,]@@@ l@@@  l@@@   '@@@p     @@@Y
*           l@@@@@@@@@  @@@@EEEEEEEEEEEE l@@@  l@@@    "@@@p   @@@Y
*           l@@@@@@@@@  l@@K             l@@@  l@@@     '@@@, @@@Y
*            @@@@@@@@@   %@@@,    ,g@@@  l@@@  l@@@      ^@@@@@@Y
*            "@@@@@@@@    "N@@@@@@@@E'   l@@@  l@@@       "*@@@Y
*             "J@@@@@@        "**""       '''   '''        @@@Y
*    ,gg@@g    "J@@@P                                     @@@Y
*   @@@@@@@@p    J@@'                                    @@@Y
*   @@@@@@@@P    J@h                                    RNNY
*   'B@@@@@@     $P
*       "JE@@@p"'
*
*
*/

/**
* @author ProfWobble
* @dev
* - Pool Contract with Staking NFTs:
*   - Mints NFTs on stake() which represent staked tokens
*          and claimable rewards in the pool.
*   - Supports Merkle proofs using the JellyList interface.
*   - External rewarder logic for multiple pools.
*   - NFT attributes onchain via the descriptor.
*
*/


import "IJellyAccessControls.sol";
import "IJellyRewarder.sol";
import "IJellyPool.sol";
import "IJellyContract.sol";
import "IMerkleList.sol";
import "IDescriptor.sol";
import "SafeERC20.sol";
import "Documents.sol";
import "BoringMath.sol";
import "JellyPoolNFT.sol";

contract JellyPool is IJellyPool, IJellyContract, JellyPoolNFT, Documents {
    using SafeERC20 for OZIERC20;

    /// @notice Jelly template id for the pool factory.
    /// @dev For different pool types, this must be incremented.
    uint256 public override constant TEMPLATE_TYPE = 2;
    bytes32 public override constant TEMPLATE_ID = keccak256("JELLY_POOL");
    uint256 public constant pointMultiplier = 10e12;

    IJellyAccessControls public accessControls;
    IJellyRewarder public rewardsContract;
    IDescriptor public descriptor;

    /// @notice Token to stake.
    address public override poolToken;
    address public owner;
    struct PoolSettings {
        bool tokensClaimable;
        bool useList;
        bool useListAmounts;
        bool initialised; 
        uint256 transferTimeout;
        /// @notice Address that manages approvals.
        address list;  
    }
    PoolSettings public poolSettings;

    /// @notice Total tokens staked.
    uint256 public override stakedTokenTotal;

    struct RewardInfo {
        uint48 lastUpdateTime;
        uint208 rewardsPerTokenPoints;
    }

    /// @notice reward token address => rewardsPerTokenPoints
    mapping(address => RewardInfo) public poolRewards;

    address[] public rewardTokens;

    struct TokenRewards {
        uint128 rewardsEarned;
        uint128 rewardsReleased;
        uint48 lastUpdateTime;
        uint208 lastRewardPoints;
    }
    /// @notice Mapping from tokenId => rewards token => reward info.
    mapping (uint256 => mapping(address => TokenRewards)) public tokenRewards;

    struct TokenInfo {
        uint128 staked;
        uint48 lastUpdateTime;
    }
    /// @notice Mapping from tokenId => token info.
    mapping (uint256 => TokenInfo) public tokenInfo;

    struct UserPool {
        uint128 stakeLimit;
    }

    /// @notice user address => pool details
    mapping(address => UserPool) public userPool;

    /**
     * @notice Event emitted when claimable status is updated.
     * @param status True or False.
     */
    event TokensClaimable(bool status);
    /**
     * @notice Event emitted when rewards contract has been updated.
     * @param oldRewardsToken Address of the old reward token contract.
     * @param newRewardsToken Address of the new reward token contract.
     */
    event RewardsContractSet(address indexed oldRewardsToken, address newRewardsToken);
    /**
     * @notice Event emmited when a user has staked LPs.
     * @param owner Address of the staker.
     * @param amount Amount staked in LP tokens.
     */
    event Staked(address indexed owner, uint256 amount);
    /**
     * @notice Event emitted when a user claims rewards.
     * @param user Address of the user.
     * @param reward Reward amount.
     */
    event RewardsClaimed(address indexed user, uint256 reward);
    /**
     * @notice Event emitted when a user has unstaked LPs.
     * @param owner Address of the unstaker.
     * @param amount Amount unstaked in LP tokens.
     */
    event Unstaked(address indexed owner, uint256 amount);
    /**
     * @notice Event emitted when user unstaked in emergency mode.
     * @param user Address of the user.
     * @param tokenId unstaked tokenId.
     */
    event EmergencyUnstake(address indexed user, uint256 tokenId);

    constructor() {
    }


    //--------------------------------------------------------
    // Pool Config
    //--------------------------------------------------------

    /**
     * @notice Admin can change rewards contract through this function.
     * @param _addr Address of the new rewards contract.
     */
    function setRewardsContract(address _addr) external override {
        require(accessControls.hasAdminRole(msg.sender));
        require(_addr != address(0));
        emit RewardsContractSet(address(rewardsContract), _addr);
        rewardsContract = IJellyRewarder(_addr);
        rewardTokens = rewardsContract.rewardTokens(address(this));

    }

    /**
     * @notice Admin can set reward tokens claimable through this function.
     * @param _enabled True or False.
     */
    function setTokensClaimable(bool _enabled) external override  {
        require(accessControls.hasAdminRole(msg.sender));
        emit TokensClaimable(_enabled);
        poolSettings.tokensClaimable = _enabled;
    }

    /**
     * @notice Getter function for tokens claimable.
     */
    function tokensClaimable() external override view returns(bool) {
        return poolSettings.tokensClaimable;
    }


    //--------------------------------------------------------
    // Jelly Pool NFTs
    //--------------------------------------------------------

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the admin.
     */
    function setDescriptor(address _descriptor) external {
        require(accessControls.hasAdminRole(msg.sender));
        descriptor = IDescriptor(_descriptor);
    }

    /**
     * @notice Set admin details of the NFT including owner, token name and symbol.
     * @dev Only callable by the admin.
     */
    function setTokenDetails(string memory _name, string memory _symbol, address _owner) external {
        require(accessControls.hasAdminRole(msg.sender));
        tokenName = _name;
        tokenSymbol = _symbol;
        owner = _owner;
    }

    /**
     * @notice Add a delay between updating staked position and a token transfer.
     * @dev Only callable by the admin.
     */
    function setTransferTimeout(uint256 _timeout) external {
        require(accessControls.hasAdminRole(msg.sender));
        require(_timeout < block.timestamp);
        poolSettings.transferTimeout = _timeout;
    }

    function getOwnerTokens(address _owner) public view returns (uint256[] memory) {
        uint256 count = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            tokenIds[i] = _ownedTokens[_owner][i];
        }
        return tokenIds;
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), 'Non-existent token');
        return descriptor.tokenURI(_tokenId);
    }

    /**
     * @notice Includes a configurable delay between updating staked position and a token transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        for(uint i = 0; i < rewardTokens.length; i++) {
            require(tokenRewards[tokenId][rewardTokens[i]].lastUpdateTime <= block.timestamp - uint256(poolSettings.transferTimeout), "Staked value recently updated");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }


    //--------------------------------------------------------
    // Verify
    //--------------------------------------------------------

    /**
     * @notice Whitelisted staking
     * @param _merkleRoot List identifier.
     * @param _index User index.
     * @param _user User address.
     * @param _stakeLimit Max amount of tokens stakable by user, set in proof.
     * @param _data Bytes array to send to the list contract.
     */
    function verify(bytes32 _merkleRoot, uint256 _index, address _user, uint256 _stakeLimit, bytes32[] calldata _data ) public {
        UserPool storage _userPool =  userPool[_user];
        require(_stakeLimit > 0, "Limit must be > 0");

        if (_stakeLimit > uint256(_userPool.stakeLimit)) {
            uint256 merkleAmount = IMerkleList(poolSettings.list).tokensClaimable(_merkleRoot, _index, _user, _stakeLimit, _data );
            require(merkleAmount > 0, "Incorrect merkle proof");
            _userPool.stakeLimit = BoringMath.to128(merkleAmount);
        }
    }

    /**
     * @notice Function for verifying whitelist, staking and minting a Staking NFT
     * @param _amount Number of tokens in merkle proof.
     * @param _merkleRoot Merkle root.
     * @param _index Merkle index.
     * @param _stakeLimit Max amount of tokens stakable by user, set in proof.
     * @param _data Bytes array to send to the list contract.

     */
    function verifyAndStake(uint256 _amount, bytes32 _merkleRoot, uint256 _index, uint256 _stakeLimit, bytes32[] calldata _data ) 
        external
    {       
        verify(_merkleRoot, _index, msg.sender, _stakeLimit, _data );
        _stake(msg.sender, _amount);
    }


    //--------------------------------------------------------
    // Stake
    //--------------------------------------------------------

    /**
     * @notice Deposits tokens into the JellyPool and mints a Staking NFT 
     * @param _amount Number of tokens deposited into the pool.
     */
    function stake(uint256 _amount) 
        external
    {       
            _stake(msg.sender, _amount);
    }

    /**
     * @notice Internal staking function called by both verifyAndStake() and stake().
     * @param _user Stakers address.
     * @param _amount Number of tokens to deposit.
     */
    function _stake(
        address _user,
        uint256 _amount
    )
        internal
    {
        require(
            _amount > 0,
            "Amount must be > 0"
        );    

        /// @dev If a whitelist is set, this checks user balance. 
        if (poolSettings.useList) {
            if (poolSettings.useListAmounts) {
                require(_amount < userPool[_user].stakeLimit);
            } else {
                require(userPool[_user].stakeLimit > 0);
            }
        }

        /// @dev Mints a Staking NFT if the user doesnt already have one. 
        if (balanceOf(_user) == 0) {
            // Mints new Staking NFT
            uint256 _tokenId = _safeMint(_user);
            // Sets initial rewards points
            for(uint i = 0; i < rewardTokens.length; i++) {
                address rewardToken = rewardTokens[i];
                if(tokenRewards[_tokenId][rewardToken].lastRewardPoints == 0) {
                    tokenRewards[_tokenId][rewardToken].lastRewardPoints = poolRewards[rewardToken].rewardsPerTokenPoints;
                }
            }
        }
        /// We always add balance to the users first token. 
        uint256 tokenId = _ownedTokens[_user][0];

        /// Updates internal accounting and stakes tokens
        snapshot(tokenId);
        tokenInfo[tokenId] = TokenInfo(tokenInfo[tokenId].staked + BoringMath.to128(_amount)
                                        , BoringMath.to48(block.timestamp) );
        stakedTokenTotal += BoringMath.to128(_amount);
        OZIERC20(poolToken).safeTransferFrom(
            address(_user),
            address(this),
            _amount
        );
        emit Staked(_user, _amount);
    }

    /**
     * @notice Returns the number of tokens staked for a tokenID.
     * @param _tokenId TokenID to be checked.
     */
    function stakedBalance(uint256 _tokenId) external view override returns(uint256){
        return tokenInfo[_tokenId].staked;
    }

    //--------------------------------------------------------
    // Rewards
    //--------------------------------------------------------

    /// @dev Updates the rewards accounting onchain for a specific tokenID.
    function snapshot(
        uint256 _tokenId
    ) 
        public
    {
        require(_exists(_tokenId), 'Non-existent token');
        IJellyRewarder rewarder = rewardsContract;
        rewarder.updateRewards();
        uint256 sTotal = stakedTokenTotal;
        for(uint i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            RewardInfo storage rInfo = poolRewards[rewardTokens[i]];
            /// Get total pool rewards from rewarder
            uint208 currentRewardPoints;
            if (sTotal == 0) {
                currentRewardPoints = rInfo.rewardsPerTokenPoints;
            } else {
                uint256 currentRewards = rewarder.poolRewards(address(this), rewardToken, uint256(rInfo.lastUpdateTime), block.timestamp);

                /// Convert to reward points
                currentRewardPoints = rInfo.rewardsPerTokenPoints + BoringMath.to208(currentRewards * 1e18 * pointMultiplier / sTotal); 
            }
            /// Update reward info
            rInfo.rewardsPerTokenPoints = currentRewardPoints;
            rInfo.lastUpdateTime = BoringMath.to48(block.timestamp) ;

            _updateTokenRewards(_tokenId, rewardToken, currentRewardPoints);
        }
    }

    function _updateTokenRewards(uint256 _tokenId, address _rewardToken, uint208 currentRewardPoints) internal  {

        TokenRewards storage _tokenRewards = tokenRewards[_tokenId][_rewardToken];
        // update token rewards 
        _tokenRewards.rewardsEarned += BoringMath.to128(tokenInfo[_tokenId].staked * uint256(currentRewardPoints -_tokenRewards.lastRewardPoints)
                                                            / 1e18
                                                            / pointMultiplier);
        // Update token details 
        _tokenRewards.lastUpdateTime = BoringMath.to48(block.timestamp);
        _tokenRewards.lastRewardPoints = currentRewardPoints;

    }

    //--------------------------------------------------------
    // Claim
    //--------------------------------------------------------

    /**
     * @notice Claim rewards for all Staking NFTS owned by the sender.
     */
    function claim()  external {
        require(
            poolSettings.tokensClaimable == true,
            "Not yet claimable"
        );
        uint256[] memory tokenIds = getOwnerTokens(msg.sender);

        if (tokenIds.length > 0) {
            for(uint i = 0; i < tokenIds.length; i++) {
                snapshot(tokenIds[i]);
            }
            for(uint j = 0; j < rewardTokens.length; j++) {
                _claimRewards(tokenIds, rewardTokens[j], msg.sender);
            }
        }
    }

    /**
     * @notice Claiming rewards on behalf of a token ID.
     * @param _tokenId Token ID.
     */
    function fancyClaim(uint256 _tokenId) public {
        claimRewards(_tokenId, rewardTokens);
    }

    /**
     * @notice Claiming rewards for user for specific rewards.
     * @param _tokenId Token ID.
     */
    function claimRewards(uint256 _tokenId, address[] memory _rewardTokens) public {
        require(
            poolSettings.tokensClaimable == true,
            "Not yet claimable"
        );
        snapshot(_tokenId);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;
        address recipient = ownerOf(_tokenId);
        for(uint i = 0; i < _rewardTokens.length; i++) {
            _claimRewards(tokenIds, _rewardTokens[i], recipient);
        }
    }

    /**
     * @notice Claiming rewards for user.
     * @param _tokenIds Array of Token IDs.
     */
    function _claimRewards(uint256[] memory _tokenIds, address _rewardToken, address _recipient) internal {
        uint256 payableAmount;
        uint128 rewards;
        for(uint i = 0; i < _tokenIds.length; i++) {
            TokenRewards storage _tokenRewards = tokenRewards[_tokenIds[i]][_rewardToken];
            rewards = _tokenRewards.rewardsEarned - _tokenRewards.rewardsReleased;
            payableAmount += uint256(rewards);
            _tokenRewards.rewardsReleased += rewards;
        }

        OZIERC20(_rewardToken).safeTransfer(_recipient, payableAmount);
        emit RewardsClaimed(_recipient, payableAmount);
    }


    //--------------------------------------------------------
    // Unstake
    //--------------------------------------------------------

    /**
     * @notice Function for unstaking exact amount of tokens, claims all rewards.
     * @param _amount amount of tokens to unstake.
     */

    function unstake(uint256 _amount) external  {
        uint256[] memory tokenIds = getOwnerTokens(msg.sender);
        uint256 unstakeAmount;
        require(tokenIds.length > 0, "Nothing to unstake");
        for(uint i = 0; i < tokenIds.length; i++) {
            if (_amount > 0) {
                unstakeAmount = tokenInfo[tokenIds[i]].staked;
                if (unstakeAmount > _amount) {
                    unstakeAmount = _amount;
                }
                _amount = _amount - unstakeAmount;
                fancyClaim(tokenIds[i]);
                _unstake(msg.sender, tokenIds[i], unstakeAmount);
            }
        }
    }

    /**
     * @notice Function for unstaking exact amount of tokens, for a specific NFT token id.
     * @param _tokenId TokenID to be unstaked
     * @param _amount amount of tokens to unstake.
     */
    function unstakeToken(uint256 _tokenId, uint256 _amount) external  {
        require(
            ownerOf(_tokenId) == msg.sender,
            "Must own tokenId"
        );
        fancyClaim(_tokenId);
        _unstake(msg.sender, _tokenId, _amount);
    }

    /**
     * @notice Function that executes the unstaking.
     * @param _user Stakers address.
     * @param _tokenId Number of tokens to unstake.
     * @param _amount amount of tokens to unstake.
     */
    function _unstake(address _user, uint256 _tokenId, uint256 _amount) internal {        
        tokenInfo[_tokenId] = TokenInfo(tokenInfo[_tokenId].staked - BoringMath.to128(_amount)
                                        , BoringMath.to48(block.timestamp) );
        stakedTokenTotal -= BoringMath.to128(_amount);

        if (tokenInfo[_tokenId].staked == 0) {
            delete tokenInfo[_tokenId];  
            _burn(_tokenId);
        }

        uint256 tokenBal = OZIERC20(poolToken).balanceOf(address(this));
        if (_amount > tokenBal) {
            _amount = tokenBal;       
        } 
        OZIERC20(poolToken).safeTransfer(address(_user), _amount);
        emit Unstaked(_user, _amount);
    }

    /**
     * @notice Unstake without rewards. EMERGENCY ONLY.
     */
    function emergencyUnstake(uint256 _tokenId) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "Must own tokenId"
        );
        _unstake(msg.sender, _tokenId, tokenInfo[_tokenId].staked);
        emit EmergencyUnstake(msg.sender, _tokenId);
    }


    //--------------------------------------------------------
    // List
    //--------------------------------------------------------
    /**
     * @notice Address used for whitelist if activated
     */
    function list() external view returns (address) {
        return poolSettings.list;
    }

    function setList(address _list) external {
        require(accessControls.hasAdminRole(msg.sender));
        if (_list != address(0)) {
            poolSettings.list = _list;
        }
    }

    function enableList(bool _useList, bool _useListAmounts) public {
        require(accessControls.hasAdminRole(msg.sender));
        poolSettings.useList = _useList;
        poolSettings.useListAmounts = _useListAmounts;

    }

    //--------------------------------------------------------
    // Documents
    //--------------------------------------------------------

    function setDocument(string calldata _name, string calldata _data) external {
        require(accessControls.hasAdminRole(msg.sender) );
        if (bytes(_data).length > 0) {
            _setDocument( _name, _data);
        } else {
            _removeDocument(_name);
        }
    }

    //--------------------------------------------------------
    // Factory
    //--------------------------------------------------------

    /**
     * @notice Initializes main contract variables.
     * @dev Init function.
     * @param _poolToken Address of the pool token.
     * @param _accessControls Access controls interface.

     */
    function initJellyPool(
        address _poolToken,
        address _accessControls
    ) public 
    {
        require(!poolSettings.initialised);
        poolToken = _poolToken;
        accessControls = IJellyAccessControls(_accessControls);
        poolSettings.initialised = true;
    }

    function init(bytes calldata _data) external override payable {}

    function initContract(
        bytes calldata _data
    ) external override {
        (
        address _poolToken,
        address _accessControls
        ) = abi.decode(_data, (address, address));

        initJellyPool(
                        _poolToken,
                        _accessControls
                    );
    }
}
