// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./Collection.sol";

contract NFTStaking is OwnableUpgradeable, ERC721HolderUpgradeable {
    // user deposits are recorded in StakeInfo[] stakes struct
    struct StakeInfo {
        // staked is true if token is staked and hasn't been unstaked.
        // After user claims his stake back, `staked` becomes false
        bool staked;
        // address of staked token's owner
        address stakerAddress;
        // time of start staking token
        uint256 lastUpdateTime;
        // totalYield is a total value of rewards for the given stake.
        // user is able to withdraw yield.
        uint256 totalYield;
        // The amount of yield user already harvested
        uint256 harvestedYield;
    }

    // If stakesOpen == true, the contract is operational and accepts new stakes.
    // Otherwise it allows just harvesting and unstaking.
    bool public stakesOpen;

    // Token used for rewards
    IERC20 public nftlToken;

    // The token accepted for staking
    Collection public heroesToken;

    uint256 internal constant WELCOME_BONUS_TIME = 365 * 24 * 60 * 60;

    // struccture that stores the records of users' stakes
    mapping(uint256 => StakeInfo) public stakes;
    // struccture that stores the records of users' staked tokens
    mapping(address => uint256[]) public stakedTokens;

    // Base reward that staker will receive for his stake
    uint256 public baseRewardPerSecond;

    event Stake(address indexed user, uint256 indexed tokenId);
    event Unstake(address indexed user, uint256 indexed tokenId);
    event Harvest(address indexed user, uint256 indexed tokenId, uint256 amount);

    /**
     * @dev the constructor arguments:
     * @param _nftlAddress address of token - the same used to pay rewards
     * @param _heroesAddress address of token - the same accepted for staking
     */
    function initialize(address _nftlAddress, address _heroesAddress) public initializer {
        require(_nftlAddress != address(0), "Empty NFTL token address");
        require(_heroesAddress != address(0), "Empty heroes address");
        nftlToken = IERC20(_nftlAddress);
        heroesToken = Collection(_heroesAddress);
        __Ownable_init();
    }

    /**
     * @dev set token address for payment of rewards
     * @param _nftlAddress address of token - the same used to pay rewards
     */
    function setNftl(address _nftlAddress) public onlyOwner {
        nftlToken = IERC20(_nftlAddress);
    }

    /**
     * @dev start accepting new stakes. Called only by the owner
     */
    function start() public onlyOwner {
        require(!stakesOpen, "Stakes are open already");
        stakesOpen = true;
    }

    /**
     * @dev stop accepting new stakes. Called only by the owner
     */
    function stop() public onlyOwner {
        require(stakesOpen, "Stakes are stopped already");
        stakesOpen = false;
    }

    /**
     * @dev set base reward for tokens
     * @param _baseRewardPerSecond  base reward in second
     */

    function setBaseRewardPerSecond(uint256 _baseRewardPerSecond) public onlyOwner {
        baseRewardPerSecond = _baseRewardPerSecond;
    }

    /**
     * @dev the owner is able to withdraw excess tokens
     * @param _to  address who will receive the funds
     * @param _amount amount of tokens in atto (1e-18) units
     */

    function withdrawNftl(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Empty receiver address");
        require(_amount > 0, "Zero amount");
        require(nftlToken.balanceOf(address(this)) >= _amount, "Not enough tokens");
        nftlToken.transfer(_to, _amount);
    }

    /**
     * @dev submit the stake
     * @param _tokenId id of hero token
     */
    function stake(uint256 _tokenId) external {
        require(stakesOpen, "stake: not open");
        stakes[_tokenId].staked = true;
        stakes[_tokenId].stakerAddress = msg.sender;
        stakes[_tokenId].lastUpdateTime = block.timestamp;

        // stakers get welcome bonus for their first stake
        if (stakes[_tokenId].totalYield == 0) {
            stakes[_tokenId].totalYield = WELCOME_BONUS_TIME * getTokenRewardPerSecond(_tokenId);
        }
        stakedTokens[msg.sender].push(_tokenId);
        emit Stake(msg.sender, _tokenId);
        heroesToken.safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    /**
     * @dev withdraw the user's staked token
     * @param _tokenId id of hero token
     */
    function unstake(uint256 _tokenId) external {
        require(msg.sender == stakes[_tokenId].stakerAddress, "Sender is not staker");
        require(stakes[_tokenId].staked, "Unstaked already");
        _updateYield(_tokenId);
        stakes[_tokenId].staked = false;
        stakes[_tokenId].stakerAddress = address(0);

        // Since `delete` Solidity operator leaves zeroes at the deleted index and
        // doesn'd decrease array length.
        // To actually drop data and shorten the list, we copy last item to the index
        // of removed value (overwriting it) then pop last element to decrease array size
        for (uint256 i = 0; i < stakedTokens[msg.sender].length; ++i) {
            if (stakedTokens[msg.sender][i] == _tokenId) {
                uint256 lastElementIndex = stakedTokens[msg.sender].length - 1;
                stakedTokens[msg.sender][i] = stakedTokens[msg.sender][lastElementIndex];
                stakedTokens[msg.sender].pop();
                break;
            }
        }

        emit Unstake(msg.sender, _tokenId);
        _calculateAndTransferHarvest(_tokenId);
        heroesToken.safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    /**
     * @dev harvest accumulated rewards. Can be called many times.
     * @param _tokenId   Id of the token to be harvested
     */
    function harvest(uint256 _tokenId) external {
        address currentTokenHolder = heroesToken.ownerOf(_tokenId);
        if (currentTokenHolder == address(this)) {
            // token is on staking contract, so we need to check it was indeed staked by msg.sender
            require(msg.sender == stakes[_tokenId].stakerAddress, "Sender is not staker");
            _updateYield(_tokenId);
        } else {
            // token is on another address, so we need to check msg.sender is its owner
            require(msg.sender == currentTokenHolder, "Sender is not holder");
        }

        require(stakes[_tokenId].totalYield > stakes[_tokenId].harvestedYield, "No harvestableYield");
        _calculateAndTransferHarvest(_tokenId);
    }

    /**
     * @dev return the array of staked token IDs
     * @param _staker address of token staker
     * @return stakedTokens array of staked token IDs
     */
    function getStakedTokens(address _staker) public view returns (uint256[] memory) {
        return stakedTokens[_staker];
    }

    /**
     * @dev return unaccounted reward that is not reflected in the contract state
     * for staked tokens this function returns value that increments each block.
     * For tokens that are not staked it returns 0
     * @param _tokenId index of the token
     * @return rewardSinceLastUpdate reward tokens that were accumulated sinceLastUpdate
     */
    function getRewardSinceLastUpdate(uint256 _tokenId) public view returns (uint256 rewardSinceLastUpdate) {
        rewardSinceLastUpdate = 0;
        if (stakes[_tokenId].staked) {
            uint256 secondsStaked = block.timestamp - stakes[_tokenId].lastUpdateTime;
            rewardSinceLastUpdate = getTokenRewardPerSecond(_tokenId) * secondsStaked;
        }
    }

    /**
     * @dev get the individual stake parameters of the user's staked token
     * @param _tokenId token stake index
     * @return staked the status of stake
     * @return stakerAddress address of staker
     * @return lastUpdateTime time of start staking
     * @return totalYield entire yield for the stake
     * @return harvestedYield The part of yield user harvested already
     */
    function getStake(uint256 _tokenId)
        external
        view
        returns (
            bool staked,
            address stakerAddress,
            uint256 lastUpdateTime,
            uint256 totalYield,
            uint256 harvestedYield
        )
    {
        StakeInfo memory _stake = stakes[_tokenId];
        staked = _stake.staked;
        stakerAddress = _stake.stakerAddress;
        lastUpdateTime = _stake.lastUpdateTime;
        totalYield = _stake.totalYield + getRewardSinceLastUpdate(_tokenId);
        harvestedYield = _stake.harvestedYield;
    }

    /**
     * @dev calculate reward speed for the given tokenId
     * @param _tokenId token id
     * @return rewardPerSecond in atto tokens per second
     */
    function getTokenRewardPerSecond(uint256 _tokenId) public view returns (uint256 rewardPerSecond) {
        rewardPerSecond = baseRewardPerSecond * heroesToken.getRarity(_tokenId);
    }

    /**
     * @dev Update accumulated reward for staked token
     * @param _tokenId token id
     */
    function _updateYield(uint256 _tokenId) internal {
        require(stakes[_tokenId].staked, "Token not staked");
        stakes[_tokenId].totalYield += getRewardSinceLastUpdate(_tokenId);
        stakes[_tokenId].lastUpdateTime = block.timestamp;
    }

    /**
     * @dev Calculate yield amount, emit Harvest event and pay nftl tokens
     * @param _tokenId token id
     */
    function _calculateAndTransferHarvest(uint256 _tokenId) internal {
        uint256 amount = stakes[_tokenId].totalYield - stakes[_tokenId].harvestedYield;
        stakes[_tokenId].harvestedYield = stakes[_tokenId].totalYield;
        emit Harvest(msg.sender, _tokenId, amount);
        nftlToken.transfer(msg.sender, amount);
    }
}
