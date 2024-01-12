// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "./IERC20.sol"; 		// ERC20 interface
import "./IERC721Receiver.sol"; 	// OZ: IERC721Receiver
import "./Ownable.sol"; 			// OZ: Ownership
import "./ReentrancyGuard.sol"; 		// OZ: ReentrancyGuard 
import "./SafeMath.sol"; 		// OZ: SafeMath
import "./EnumerableSet.sol";	// OZ: EnumerableSet
import "./IEcoNFT.sol";

/**
 * @title ECO NFT's Staking Contract
 * @author ESG Team
 */
contract EcoNFTStaking is IERC721Receiver, ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public immutable esg;
    IEcoNFT public immutable nft;

    uint256 constant BLOCKS_PER_DAY = 5760; // mainnet
    uint256 constant REWARD_SHARE_MULTIPLIER = 1e12;

    uint256 public esg_per_day = 40e18; // ESG mined per day
    uint256 public lastStakeBlock;  		// Last block number that Token distribution occurs.
    uint256 public accRewardTokenPerShare;  	// Accumulated Token per share, times 1e12.

    uint256 public totalHashRate; 		// Total Hash Rate staked
    uint256 public totalNFTStaked; 		// Total NFT staked
    uint256 public esgRewardTotal; 		// ESG token claimed total

    // @notice A checkpoint for staking
    struct Checkpoint {
        uint256 hashRate;    // total Hash Rate user provides
        uint256 rewardDebt ; // Reward debt
        uint256 rewardTotal; // Reward total
        uint256 rewardPayout;// Reward payout
	bool	isUsed;
    }

    // @notice staking struct of every account
    mapping (address => Checkpoint) internal stakings;

    // @notice mapping of every NFT
    mapping (uint256 => address) internal stakerOf;

    // @notice mapping of hash rate for level
    mapping (uint256 => uint256) internal hashRateOf;

    // @notice mapping of tokenIds for address
    mapping (address => EnumerableSet.UintSet) internal userTokenIds;

    /**
     * Events
     */
    /// @notice Emitted when NFT is staked  
    event NFTStaked(address indexed account, uint256 tokenId);

    /// @notice Emitted when NFT is withdrawn 
    event NFTWithdrawn(address indexed account, uint256 tokenId);

    /// @notice Emitted when ESG is claimed 
    event EsgClaimed(address indexed account, uint256 amount);

    /// @notice Emitted when NFT received
    event NFTReceived(address indexed operator, address from, uint256 tokenId, bytes data);

    constructor(address esgAddress, address nftAddress) {
	esg = IERC20(esgAddress);
	nft = IEcoNFT(nftAddress);

	hashRateOf[1] = 100;
	hashRateOf[2] = 180;
	hashRateOf[3] = 350;
	hashRateOf[4] = 600;
	hashRateOf[5] = 1200;
	hashRateOf[6] = 180;
	hashRateOf[7] = 260;
	hashRateOf[8] = 430;
	hashRateOf[9] = 680;
	hashRateOf[10] = 1280;

	accRewardTokenPerShare = 0;
	lastStakeBlock = block.number;

	totalHashRate = 0;
	totalNFTStaked = 0;
	esgRewardTotal = 0;

    }


    /**
     * @notice Stake NFT to contract 
     * @param tokenId The tokenId of NFT to be staked 
     * @return Success indicator for whether staked 
     */
    function stake(uint256 tokenId) external nonReentrant returns (bool) {
    	require(stakerOf[tokenId] == address(0), "Token already staked");
	address nftOwner = nft.ownerOf(tokenId);
	nft.safeTransferFrom(nftOwner, address(this), tokenId);
	stakerOf[tokenId] = nftOwner;

	EnumerableSet.UintSet storage ids = userTokenIds[nftOwner];	
	require(!EnumerableSet.contains(ids, tokenId), "Token already staked 2");
	EnumerableSet.add(ids, tokenId);

	uint256 level = IEcoNFT(nft).getLevel(tokenId);
	require(level > 0, "Only Teru NFT accepted.");
		
	uint256 hash_rate = hashRateOf[level];

	uint256 accReward = block.number.sub(lastStakeBlock).mul(esg_per_day).div(BLOCKS_PER_DAY);
	if(totalHashRate > 0)
		accRewardTokenPerShare = accRewardTokenPerShare.add(accReward.mul(REWARD_SHARE_MULTIPLIER).div(totalHashRate));
	totalNFTStaked = totalNFTStaked.add(1);

	emit NFTStaked(nftOwner, tokenId);

	Checkpoint storage cp = stakings[nftOwner];
	if(cp.isUsed == true)
	{
		uint256 reward = cp.hashRate.mul(accRewardTokenPerShare).div(REWARD_SHARE_MULTIPLIER).sub(cp.rewardDebt);
		cp.rewardTotal = cp.rewardTotal.add(reward);
		totalHashRate = totalHashRate.add(hash_rate);
		cp.hashRate = cp.hashRate.add(hash_rate);
		cp.rewardDebt = cp.hashRate.mul(accRewardTokenPerShare).div(REWARD_SHARE_MULTIPLIER);
	}else
	{
		uint256 rewardDebt = hash_rate.mul(accRewardTokenPerShare).div(REWARD_SHARE_MULTIPLIER);
		totalHashRate = totalHashRate.add(hash_rate);
		stakings[nftOwner] = Checkpoint(hash_rate, rewardDebt, 0, 0, true);
	}
	lastStakeBlock = block.number;	

	return true;
    }

    /**
     * @notice withdraw NFT staked in contract 
     * @return Success indicator for success 
     */
    function unstake(uint256 tokenId) external nonReentrant returns (bool) {

	Checkpoint storage cp = stakings[msg.sender];
	require(cp.isUsed == true, "account no exists");
	require(stakerOf[tokenId] == msg.sender, "unauthorized staker");

	uint256 level = IEcoNFT(nft).getLevel(tokenId);
	uint256 hash_rate = hashRateOf[level];

	uint256 accReward = block.number.sub(lastStakeBlock).mul(esg_per_day).div(BLOCKS_PER_DAY);
	if(totalHashRate > 0)
		accRewardTokenPerShare = accRewardTokenPerShare.add(accReward.mul(REWARD_SHARE_MULTIPLIER).div(totalHashRate));
	uint256 reward = cp.hashRate.mul(accRewardTokenPerShare).div(REWARD_SHARE_MULTIPLIER).sub(cp.rewardDebt);
	cp.rewardTotal = cp.rewardTotal.add(reward);

	totalHashRate = totalHashRate.sub(hash_rate);
	cp.hashRate = cp.hashRate.sub(hash_rate);
	cp.rewardDebt = cp.hashRate.mul(accRewardTokenPerShare).div(REWARD_SHARE_MULTIPLIER);

	delete stakerOf[tokenId];
	EnumerableSet.UintSet storage ids = userTokenIds[msg.sender];	
	require(EnumerableSet.contains(ids, tokenId), "Token is not staked");
	EnumerableSet.remove(ids, tokenId);

	totalNFTStaked = totalNFTStaked.sub(1);
	nft.safeTransferFrom(address(this), msg.sender, tokenId);

	lastStakeBlock = block.number;

	emit NFTWithdrawn(msg.sender, tokenId); 

	if(cp.hashRate == 0 && cp.rewardPayout == cp.rewardTotal)
	{
		delete stakings[msg.sender];
	}

	return true;
    }

    /**
     * @notice claim all ESG token mined in contract 
     * @return Success indicator for success 
     */
    function claimEsg() external returns (bool) {

	Checkpoint storage cp = stakings[msg.sender];
	require(cp.isUsed == true, "account no exists");

	uint256 accReward = block.number.sub(lastStakeBlock).mul(esg_per_day).div(BLOCKS_PER_DAY);
	if(totalHashRate > 0)
		accRewardTokenPerShare = accRewardTokenPerShare.add(accReward.mul(REWARD_SHARE_MULTIPLIER).div(totalHashRate));
	uint256 reward = cp.hashRate.mul(accRewardTokenPerShare).div(REWARD_SHARE_MULTIPLIER).sub(cp.rewardDebt);
	cp.rewardDebt = cp.hashRate.mul(accRewardTokenPerShare).div(REWARD_SHARE_MULTIPLIER);
	cp.rewardTotal = cp.rewardTotal.add(reward);

	uint256 amount = cp.rewardTotal.sub(cp.rewardPayout);
	if(amount > esg.balanceOf(address(this)))
		amount = esg.balanceOf(address(this));
	cp.rewardPayout = cp.rewardPayout.add(amount);

	esgRewardTotal = esgRewardTotal.add(amount);
	lastStakeBlock = block.number;

	esg.transfer(msg.sender, amount);

	emit EsgClaimed (msg.sender, amount); 

	if(cp.hashRate == 0 && cp.rewardPayout == cp.rewardTotal)
	{
		delete stakings[msg.sender];
	}

	return true;
    }

    /**
     * @notice Returns stake info 
     * @param account The address of the account 
     * @return hash_rate Checkpoint info of account
     */
    function getStakingInfo(address account) external view returns (uint256 hash_rate, uint256 reward_debt, uint256 reward_total, uint256 reward_payout, bool is_used) {
	Checkpoint memory cp = stakings[account];
	hash_rate = cp.hashRate;
	reward_debt = cp.rewardDebt;
	reward_total = cp.rewardTotal;
	reward_payout =  cp.rewardPayout;
	is_used = cp.isUsed;
    }

    /**
     * @notice Returns hash rate mapping info 
     * @param level The level of NFT
     * @return hash rate of this level
     */
    function getHashRateInfo(uint256 level) external view returns (uint256) {
	return hashRateOf[level];
    }

    /**
     * @notice Returns the list of NFTs an account has staked
     * @param account The address of the account 
     * @return the length of NFT tokenId list
     */
    function getStakingNFTLength(address account) external view returns (uint256) {
	return EnumerableSet.length(userTokenIds[account]);	
    }

    /**
     * @notice Returns the NFT tokenId of an account staked
     * @param account The address of the account 
     * @param index The index of the NFT tokenId list
     * @return the tokenId of NFT
     */
    function getStakingNFT(address account, uint256 index) external view returns (uint256) {
	return EnumerableSet.at(userTokenIds[account], index);	
    }

    /**
     * @notice Return the unclaimed reward ESG of staking 
     * @param account The address of the account 
     * @return The amount of unclaimed ESG 
     */
    function getUnclaimedEsg(address account) public view returns (uint256) {
	Checkpoint memory cp = stakings[account];
	if(cp.isUsed == false)
		return 0;
	if(totalHashRate == 0)
	{
		if(cp.rewardTotal.sub(cp.rewardPayout) > 0)
			return cp.rewardTotal.sub(cp.rewardPayout);
		return 0;
	}

	uint256 accReward = block.number.sub(lastStakeBlock).mul(esg_per_day).div(BLOCKS_PER_DAY);
 	uint256	accShare = accRewardTokenPerShare.add(accReward.mul(REWARD_SHARE_MULTIPLIER).div(totalHashRate));
	uint256 reward = cp.hashRate.mul(accShare).div(REWARD_SHARE_MULTIPLIER).sub(cp.rewardDebt);
	uint256 amount = cp.rewardTotal.add(reward).sub(cp.rewardPayout);
	return amount;
    }

    /**
     * @notice Update hash rate mapping info 
     * @param level The level of NFT
     * @param hash_rate The hash rate of this level
     */
    function _updateHashRateInfo(uint256 level, uint256 hash_rate) external onlyOwner {
	hashRateOf[level] = hash_rate;
    }

    /**
     * @notice Update ESG mined per day 
     * @param amount The amount of ESG per day
     */
    function _updateEsgPerDay(uint256 amount) external onlyOwner {
	esg_per_day = amount;
    }


    /**
     * @notice The function is not implemented by the recipient, the transfer will be reverted
     * @param operator The caller of the safeTransferFrom()
     * @param from The previous owner 
     * @param tokenId The tokenId of NFT
     * @param data The data of call
     * @return The selector of onERC721Received() 
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) override external returns (bytes4) {
	require(msg.sender == address(nft), "Unsupported NFT");
	emit NFTReceived(operator, from, tokenId, data);
        return IERC721Receiver.onERC721Received.selector;
    }
}

