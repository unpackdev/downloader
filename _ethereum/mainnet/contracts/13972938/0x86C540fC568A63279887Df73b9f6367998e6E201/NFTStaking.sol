// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

/*
 ▄████▄   ██▀███   ▄▄▄      ▒███████▒▓██   ██▓
▒██▀ ▀█  ▓██ ▒ ██▒▒████▄    ▒ ▒ ▒ ▄▀░ ▒██  ██▒
▒▓█    ▄ ▓██ ░▄█ ▒▒██  ▀█▄  ░ ▒ ▄▀▒░   ▒██ ██░
▒▓▓▄ ▄██▒▒██▀▀█▄  ░██▄▄▄▄██   ▄▀▒   ░  ░ ▐██▓░
▒ ▓███▀ ░░██▓ ▒██▒ ▓█   ▓██▒▒███████▒  ░ ██▒▓░
░ ░▒ ▒  ░░ ▒▓ ░▒▓░ ▒▒   ▓▒█░░▒▒ ▓░▒░▒   ██▒▒▒
  ░  ▒     ░▒ ░ ▒░  ▒   ▒▒ ░░░▒ ▒ ░ ▒ ▓██ ░▒░
░          ░░   ░   ░   ▒   ░ ░ ░ ░ ░ ▒ ▒ ░░
░ ░         ░           ░  ░  ░ ░     ░ ░
░                           ░         ░ ░
 ▄████▄   ██▓     ▒█████   █     █░ ███▄    █   ██████
▒██▀ ▀█  ▓██▒    ▒██▒  ██▒▓█░ █ ░█░ ██ ▀█   █ ▒██    ▒
▒▓█    ▄ ▒██░    ▒██░  ██▒▒█░ █ ░█ ▓██  ▀█ ██▒░ ▓██▄
▒▓▓▄ ▄██▒▒██░    ▒██   ██░░█░ █ ░█ ▓██▒  ▐▌██▒  ▒   ██▒
▒ ▓███▀ ░░██████▒░ ████▓▒░░░██▒██▓ ▒██░   ▓██░▒██████▒▒
░ ░▒ ▒  ░░ ▒░▓  ░░ ▒░▒░▒░ ░ ▓░▒ ▒  ░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░
  ░  ▒   ░ ░ ▒  ░  ░ ▒ ▒░   ▒ ░ ░  ░ ░░   ░ ▒░░ ░▒  ░ ░
░          ░ ░   ░ ░ ░ ▒    ░   ░     ░   ░ ░ ░  ░  ░
░ ░          ░  ░    ░ ░      ░             ░       ░
░

Crazy Clowns Insane Asylum
2021, V1.1
https://ccia.io
*/

import "./SafeMath.sol";
import "./Ownable.sol";
import "./CrazyClown.sol";
import "./BalloonToken.sol";
import "./NFTExtension.sol";

/**
 * @title NFTStaking
 * @dev Stake NFTs, earn ballon tokens
 * @author
 */

contract NFTStaking is Ownable {
  using SafeMath for uint256;

  // ERC20 Reward Token
  BalloonToken public rewardsToken;

  struct Pool {
    uint256 lastRewardBlock;
    uint256 rewardsEarned;
    uint256 rewardsReleased;
  }

  struct Stake {
    mapping(uint256 => Pool) pool;
    uint256[] tokenIds;
    mapping(uint256 => uint256) tokenIndex;
  }

  struct StakeParam {
    address _contract;
    uint256 _tokenId;
  }

  struct Path {
    address to_address;
    bool burn_original;
    BalloonToken fee_contract;
    uint256 evolve_fee;
  }

  mapping(address => Path) public evolvePathList;
  mapping(address => bool) public evolvePathExists;

  // Registered NFT List
  mapping(address => NFTExtension) public NFTTokens;
  mapping(address => bool) _isNFTRegistered;
  address[] NFTTokenList;

  // Blocks per day
  uint256 public blockPerDay = 5760;

  // Mapping of a NFT contract to mapping from account to Stake struct
  mapping(address => mapping(address => Stake)) stakers;

  // Turn staking on/off
  bool public allowStaking;

  // Turn claim reward on/off
  bool public allowClaiming;

  // Mapping from a NFT Contract to a mapping from a token ID to owner address
  mapping(address => mapping(uint256 => address)) public tokenOwner;

  // Mapping from NFT address to its daily reward
  mapping(address => uint256) public dailyReward;

  // @notice event emitted when a user has staked a token
  event Staked(address owner, address tokenAddress, uint256 amount);

  // @notice event emitted when a user has unstaked a token
  event Unstaked(address owner, address tokenAddress, uint256 amount);

  // @notice event emitted when a user claims reward
  event RewardPaid(address indexed user, uint256 reward);

  /// @notice Emergency unstake tokens without rewards
  event EmergencyUnstake(address indexed user, uint256 tokenId);

  modifier isAllowedStaking() {
    require(allowStaking, 'Staking is currently disabled');
    _;
  }

  modifier isAllowedClaiming() {
    require(allowClaiming, 'Claiming is currently disabled');
    _;
  }

  constructor(BalloonToken _rewardsToken) {
    rewardsToken = _rewardsToken;
  }

  /// @notice Function allows us to add or update an external NFT contract address along with dailyReward
  function addNftReward(address contract_address, uint256 reward_per_block_day) public {
    require(!_isNFTRegistered[contract_address], 'Contract has been already registered');
    dailyReward[contract_address] = reward_per_block_day;
    NFTTokens[contract_address] = NFTExtension(contract_address);
    NFTTokenList.push(contract_address);
    _isNFTRegistered[contract_address] = true;
  }

  /// @notice function will allow us to remove an external NFT contract address.
  function removeNftReward(address contract_address) public {
    require(_isNFTRegistered[contract_address], 'Contract is not registered');
    delete dailyReward[contract_address];
    delete NFTTokens[contract_address];
    // Remove from registered NFT Contract List
    for (uint256 i = 0; i < NFTTokenList.length; i++) {
      if (NFTTokenList[i] == contract_address) {
        NFTTokenList[i] = NFTTokenList[NFTTokenList.length - 1];
        NFTTokenList.pop();
        break;
      }
    }
    _isNFTRegistered[contract_address] = false;
  }

  function _getNFTTokenList() external view returns (address[] memory) {
    return NFTTokenList;
  }

  function stakeBatch(StakeParam[] memory _tokenList) external isAllowedStaking {
    for (uint256 i = 0; i < _tokenList.length; i++) {
      _stake(msg.sender, _tokenList[i]._contract, _tokenList[i]._tokenId);
    }
  }

  /// @notice Stake NFTs and earn reward tokens.
  function stake(
    address _tokenAddress,
    uint256 _tokenId,
    address account
  ) external isAllowedStaking {
    require(_tokenAddress != address(0), 'Token Address is null');
    // require(NFTTokens[_tokenAddress].name(), "NFT Token is not registered");
    require(account == _msgSender() || _msgSender() == _tokenAddress, 'DONT GIVE YOUR TOKENS AWAY');
    if (_msgSender() != _tokenAddress) {
      require(NFTTokens[_tokenAddress].ownerOf(_tokenId) == msg.sender, 'msg.sender is not owner of token');
      _stake(msg.sender, _tokenAddress, _tokenId);
    } else {
      require(NFTTokens[_tokenAddress].ownerOf(_tokenId) == account, 'account is not owner of token');
      _stake(account, _tokenAddress, _tokenId);
    }
  }

  /**
   * @dev All the staking goes through this function
   */
  function _stake(
    address _user,
    address _tokenAddress,
    uint256 _tokenId
  ) internal {
    Stake storage _item = stakers[_tokenAddress][_user];
    _item.pool[_tokenId].lastRewardBlock = block.number;
    _item.tokenIds.push(_tokenId);
    _item.tokenIndex[_tokenId] = _item.tokenIds.length - 1;
    tokenOwner[_tokenAddress][_tokenId] = _user;

    NFTTokens[_tokenAddress].transferFrom(_user, address(this), _tokenId);

    emit Staked(_user, _tokenAddress, _tokenId);
  }

  function unstake(address _tokenAddress, uint256 _tokenId) external {
    require(_tokenAddress != address(0), 'Token Address is null');
    require(tokenOwner[_tokenAddress][_tokenId] == msg.sender, 'Sender must have staked tokenID');
    _claimReward(msg.sender, _tokenAddress, _tokenId);
    _unstake(msg.sender, _tokenAddress, _tokenId);
  }

  /**
   * @dev All the unstaking goes through this function
   * @dev Rewards to be given out is calculated
   */
  function _unstake(
    address _user,
    address _tokenAddress,
    uint256 _tokenId
  ) internal {
    Stake storage _item = stakers[_tokenAddress][_user];
    delete _item.pool[_tokenId];

    uint256 lastIndex = _item.tokenIds.length - 1;
    uint256 lastIndexKey = _item.tokenIds[lastIndex];
    uint256 tokenIdIndex = _item.tokenIndex[_tokenId];

    _item.tokenIds[tokenIdIndex] = lastIndexKey;
    _item.tokenIndex[lastIndexKey] = tokenIdIndex;
    if (_item.tokenIds.length > 0) {
      _item.tokenIds.pop();
      delete _item.tokenIndex[_tokenId];
    }

    delete tokenOwner[_tokenAddress][_tokenId];

    NFTTokens[_tokenAddress].transferFrom(address(this), _user, _tokenId);
    emit Unstaked(_user, _tokenAddress, _tokenId);
  }

  function pendingReward(address _tokenAddress, uint256 _tokenId) external view returns (uint256) {
    uint256 _reward = _pendingReward(msg.sender, _tokenAddress, _tokenId);
    return _reward;
  }

  // View function to see pending Reward on frontend.
  function _pendingReward(
    address _user,
    address _tokenAddress,
    uint256 _tokenId
  ) internal view returns (uint256) {
    Pool storage _pool = stakers[_tokenAddress][_user].pool[_tokenId];
    uint256 tokenReward = ((block.number).sub(_pool.lastRewardBlock)).mul(dailyReward[_tokenAddress]).div(blockPerDay);
    return tokenReward;
  }

  // Updates the reward earned per staked Token.
  function updateReward(
    address _user,
    address _tokenAddress,
    uint256 _tokenId
  ) internal {
    Pool storage _pool = stakers[_tokenAddress][_user].pool[_tokenId];
    uint256 _reward = _pendingReward(_user, _tokenAddress, _tokenId);
    _pool.rewardsEarned = _pool.rewardsEarned.add(_reward);
    _pool.lastRewardBlock = block.number;
  }

  function claimReward(address _tokenAddress, uint256 _tokenId) external {
    require(_tokenAddress != address(0), 'TokenAddress is null');
    _claimReward(msg.sender, _tokenAddress, _tokenId);
  }

  /// @notice Lets a user with rewards owing to claim tokens
  function _claimReward(
    address _user,
    address _tokenAddress,
    uint256 _tokenId
  ) internal isAllowedClaiming {
    updateReward(_user, _tokenAddress, _tokenId);
    Pool storage _pool = stakers[_tokenAddress][_user].pool[_tokenId];

    uint256 payableAmount = _pool.rewardsEarned.sub(_pool.rewardsReleased);
    _pool.rewardsReleased = _pool.rewardsReleased.add(payableAmount);

    rewardsToken.mint(_user, payableAmount);
    emit RewardPaid(_user, payableAmount);
  }

  /// @dev Getter functions for NFTStaking contract
  /// @dev Get the tokens staked by a user
  function getStakedTokens(address _user, address _tokenAddress) external view returns (uint256[] memory tokenIds) {
    return stakers[_tokenAddress][_user].tokenIds;
  }

  // Unstake without caring about rewards. EMERGENCY ONLY.
  function emergencyUnstake(address _tokenAddress, uint256 _tokenId) public {
    require(tokenOwner[_tokenAddress][_tokenId] == msg.sender, 'Sender must have staked tokenID');
    _unstake(msg.sender, _tokenAddress, _tokenId);
    emit EmergencyUnstake(msg.sender, _tokenId);
  }

  // Claim all the staked tokens from registered NFT contracts
  function claimAll() public {
    for (uint256 i = 0; i < NFTTokenList.length; i++) {
      address _tokenAddress = NFTTokenList[i];
      uint256[] storage tokenList = stakers[_tokenAddress][msg.sender].tokenIds;
      for (uint256 index = 0; index < tokenList.length; index++) {
        _claimReward(msg.sender, _tokenAddress, tokenList[index]);
      }
    }
  }

  // Public function to Update blockPerDay
  function updateBlockPerDay(uint256 _blockPerDay) public {
    blockPerDay = _blockPerDay;
  }

  // Function to register evolve path
  function addEvolvePath(
    address from_address,
    address to_address,
    bool burn_original,
    address fee_contract,
    uint256 evolve_fee
  ) external onlyOwner {
    require(from_address != address(0), 'Contract From Address is null');
    require(to_address != address(0), 'Contract to Address is null');
    require(fee_contract != address(0), 'Fee Contract  to Address is null');

    evolvePathList[from_address].to_address = to_address;
    evolvePathList[from_address].burn_original = burn_original;
    evolvePathList[from_address].fee_contract = BalloonToken(fee_contract);
    evolvePathList[from_address].evolve_fee = evolve_fee;
    evolvePathExists[from_address] = true;
  }

  // Function to delete evolve Path
  function deleteEvolvePath(address from_address) external onlyOwner {
    require(from_address != address(0), 'Contract From Address is null');
    delete evolvePathList[from_address];
    evolvePathExists[from_address] = false;
  }

  // Function to evolve NFT
  function evolvePath(
    address original_nft_address,
    uint256 token_id,
    bool isStaked
  ) external {
    require(original_nft_address != address(0), 'Original NFT Contract address is null');
    Path storage _path = evolvePathList[original_nft_address];
    if (isStaked) {
      // Evolve from Staked
      _unstake(msg.sender, original_nft_address, token_id);
    } else {
      // check to see if user has token_id in the original nft address
      require(NFTTokens[original_nft_address].ownerOf(token_id) == msg.sender, 'msg.sender is not owner of token');
    }

    // check to see if evolve path is registered
    require(evolvePathExists[original_nft_address], 'Evolve Path from original nft address is not registered');

    BalloonToken feeContract = _path.fee_contract;
    uint256 balanceOfSender = feeContract.balanceOf(address(msg.sender));
    // check to see if user has token amount to evolve
    require(balanceOfSender > _path.evolve_fee, 'User does not have enough ballon to evolve');

    // burn original token if burn_original of corresponding evolve path is true
    if (_path.burn_original) {
      NFTTokens[original_nft_address].burn(token_id);
    }
    // Transfer Balloon Fee Token to evolveToAddress Contract
    feeContract.burn(msg.sender, _path.evolve_fee);
    // Mint a new NFT Token to msg.sender
    uint256 _evolvedTokenId = NFTTokens[_path.to_address].evolve_mint(msg.sender);
    // Stake Evolved NFT if original token was staked.
    if (isStaked) {
      _stake(msg.sender, _path.to_address, _evolvedTokenId);
    }
  }

  function toggleAllowStaking() external onlyOwner {
    allowStaking = !allowStaking;
  }

  function toggleAllowClaiming() external onlyOwner {
    allowClaiming = !allowClaiming;
  }
}
