// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Holder.sol";
import "./SafeERC20.sol";
import "./INoone.sol";
import "./IRewardToken.sol";
import "./IUniswapV2Router02.sol";
import "./INFT.sol";


contract NooneStaking is Ownable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;
	
    // Info of each user.
    struct UserInfo {
        uint16 boostPointsBP;	    
        uint16 lockTimeBoost;          
        uint32 lockedUntil;        
        uint96 claimableNooneGovernanceToken;
		uint96 claimableETH;
        uint112 amount;             
        uint112 weightedBalance;    
        uint112 rewardDebt;		    
		uint112 ETHrewardDebt;
        address[] NFTContracts;         
        uint[] NFTTokenIDs;
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint64 allocPoint;          // How many allocation points assigned to this pool. EGGs to distribute per block.
        uint64 lastRewardBlock;     // Last block number that rewards distribution occurs.
        uint112 accRwtPerShare;     // Accumulated NooneGovernanceTokens per share, times 1e12.
        uint112 accETHPerShare;     // Accumulated ETH rewards  per share, times 1e12. 
		uint112 weightedBalance;    // The total of all weightedBalances from users. 
    }

    struct UsersNFTs {
        address NFTContract;
        uint256 TokenId;
    }

  
    // The Noone token
    INoone public Noone;
	// The reward token 
	IRewardToken public nooneGovernanceToken;
	// The uniswap V2 router
	address public router;
	// The WETH token contract
	address public WETH;
	// The boost nft contracts 
	mapping (address => bool) public isNFTContract;
    // NooneGovernanceToken tokens created per block.
    uint256 public nooneGovernanceTokenPerBlock;
    // The ETHBank address
	address public ETHBank;
    // ETH distributed per block 
	uint256 public ETHPerBlock;
	// ETH not distributed yet (should be address(this).balance - ETHLeftUnclaimed)
	uint256 public ETHLeftUnshared;
	// ETH distributed  but not claimed yet 
	uint256 public ETHLeftUnclaimed;
    // Days 
    uint256 public numdays;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when the farm starts mining starts.
    uint256 public startBlock;
	// Has the secondary reward token been released yet? 
	bool public tokenReleased;
	bool public isEmergency;
	event RewardTokenSet(address indexed tokenAddress, uint256 indexed nooneGovernanceTokenPerBlock, uint256 timestamp);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateEmissionRate(address indexed user, uint256 nooneGovernanceTokenPerBlock);
	event NFTStaked(address indexed user, address indexed NFTContract, uint256 tokenID);
	event NFTWithdrawn(address indexed user, address indexed NFTContract, uint256 tokenID);
	event TokensLocked(address indexed user, uint256 timestamp, uint256 lockTime);
	event Emergency(uint256 timestamp, bool ifEmergency);
    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }
    
    modifier onlyEmergency {
        require(isEmergency == true, "onlyEmergency: Emergency use only!");
        _;
    }
    mapping(address => bool) public authorized;
    modifier onlyAuthorized {
        require(authorized[msg.sender] == true, "onlyAuthorized: address not authorized");
        _;
    }
    constructor(
        INoone _noone,
		address _router
    ) {
        Noone = _noone;
        router = _router;
		WETH = IUniswapV2Router02(router).WETH();
		startBlock = type(uint256).max;
        numdays = 13;
    }

    // Return number of pools
	function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return (_to - _from);
    }

    function pendingRewards(uint256 _pid, address _user) external view returns (uint256, uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 userWeightedAmount = user.weightedBalance;
        uint256 accRwtPerShare = pool.accRwtPerShare;
        uint256 accETHPerShare = pool.accETHPerShare;
        uint256 weightedBalance = pool.weightedBalance;
        uint256 PendingNooneGovernanceToken;
        uint256 PendingETH;
        if (block.number > pool.lastRewardBlock && weightedBalance != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 nooneGovernanceTokenReward = multiplier * nooneGovernanceTokenPerBlock * pool.allocPoint / totalAllocPoint;
            accRwtPerShare = accRwtPerShare + nooneGovernanceTokenReward * 1e12 / weightedBalance;
            uint256 ETHReward = multiplier * ETHPerBlock * pool.allocPoint / totalAllocPoint;
            accETHPerShare = accETHPerShare + ETHReward * 1e12 / weightedBalance;
            PendingNooneGovernanceToken = (userWeightedAmount * accRwtPerShare / 1e12) - user.rewardDebt + user.claimableNooneGovernanceToken;
            PendingETH = (userWeightedAmount * accETHPerShare / 1e12) - user.ETHrewardDebt + user.claimableETH;
        }
        return(PendingNooneGovernanceToken, PendingETH);
    }

    function getUsersNFTs(uint256 _pid, address _user) public view returns (address[] memory, uint256[] memory){
        UserInfo storage user = userInfo[_pid][_user];
        uint256 nftCount = user.NFTContracts.length;
        
        address[] memory _nftContracts = new address[](nftCount);
        uint256[] memory _nftTokenIds = new uint256[](nftCount);

        for (uint i = 0; i < nftCount; i++) {
            _nftContracts[i] = user.NFTContracts[i];
            _nftTokenIds[i] = user.NFTTokenIDs[i];
        }

        return (_nftContracts, _nftTokenIds);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    
	//Receive ETH from the tax splitter contract. triggered on a walue transfer with .call("arbitraryData").
    fallback() external payable {
        ETHLeftUnshared += msg.value;
        updateETHRewards();
    }
	//Receive ETH sent through .send, .transfer, or .call(""). These wont be taken into account in the rewards. 
    receive() external payable {
        require(msg.sender != ETHBank);
    }
    
    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.weightedBalance;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = uint64(block.number);
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        if(tokenReleased) {
            uint256 nooneGovernanceTokenReward = multiplier * nooneGovernanceTokenPerBlock * pool.allocPoint / totalAllocPoint;
            pool.accRwtPerShare = uint112(pool.accRwtPerShare + nooneGovernanceTokenReward * 1e12 / lpSupply);
        }
        uint256 ETHReward = multiplier * ETHPerBlock * pool.allocPoint / totalAllocPoint;
        ETHLeftUnclaimed = ETHLeftUnclaimed + ETHReward;
        ETHLeftUnshared = ETHLeftUnshared - ETHReward;
        pool.accETHPerShare = uint112(pool.accETHPerShare + ETHReward * 1e12 / lpSupply);
        pool.lastRewardBlock = uint64(block.number);
    }

    // Deposit tokens for rewards.
    function deposit(uint256 _pid, uint256 _amount, uint256 lockTime) public nonReentrant {
        _deposit(msg.sender, _pid, _amount, lockTime);
    }

    // Withdraw unlocked tokens.
    function withdraw(uint32 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.lockedUntil < block.timestamp, "withdraw: Tokens locked, if you're trying to claim your rewards use the deposit function");
        require(user.amount >= _amount && _amount > 0, "withdraw: not good");
        updatePool(_pid);
        if (user.weightedBalance > 0){
            _addToClaimable(_pid, msg.sender);
            if(tokenReleased) {
                if (user.claimableNooneGovernanceToken > 0) {
                    safeNooneGovernanceTokenTransfer(msg.sender, user.claimableNooneGovernanceToken);
                    user.claimableNooneGovernanceToken = 0;
                }
            }
            if (user.claimableETH > 0) { 
                safeETHTransfer(msg.sender, user.claimableETH);
                user.claimableETH = 0;
            }
        }
        user.amount = uint112(user.amount - _amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        updateUserWeightedBalance(_pid, msg.sender);

        emit Withdraw(msg.sender, _pid, _amount);
    }
    
    // Withdraw unlocked tokens without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant onlyEmergency {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        pool.weightedBalance -= user.weightedBalance;
        user.amount = 0;
        user.weightedBalance = 0;
        user.ETHrewardDebt = 0;
        user.rewardDebt = 0;
        user.claimableETH = 0;
        user.claimableNooneGovernanceToken = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function reinvestETHRewards(uint256 amountOutMin) public nonReentrant {
            UserInfo storage user = userInfo[1][msg.sender];
            require(user.lockedUntil >= block.timestamp);
            updatePool(1);
            uint256 ETHPending = (user.weightedBalance * poolInfo[1].accETHPerShare / 1e12) - user.ETHrewardDebt + user.claimableETH;
            require(ETHPending > 0);
            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = address(Noone);
            if(ETHPending > ETHLeftUnclaimed) {
                ETHPending = ETHLeftUnclaimed;
            }
            uint256 balanceBefore = Noone.balanceOf(address(this));
            IUniswapV2Router02(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: ETHPending}(
            amountOutMin,
            path,
            address(this),
            block.timestamp
            );
            uint256 amountSwapped = Noone.balanceOf(address(this)) - balanceBefore;
            user.amount += uint112(amountSwapped);
            user.claimableETH = 0;
            updateUserWeightedBalance(1, msg.sender);
            emit Deposit(msg.sender, 1, amountSwapped);
    }
    

    // Withdraw previously staked NFT, loosing the rewards boost
	function withdrawNFT(uint256 _pid, address NFTContract, uint tokenID) public nonReentrant {
        address sender = msg.sender;
		uint256 NFTIndex;
        bool tokenFound;
        uint length = userInfo[_pid][sender].NFTContracts.length;
        updatePool(_pid);
        _addToClaimable(_pid, sender);
        for (uint i; i < userInfo[_pid][sender].NFTContracts.length; i++) {
            if (userInfo[_pid][sender].NFTContracts[i] == NFTContract) {
                if(userInfo[_pid][sender].NFTTokenIDs[i] == tokenID) {
                tokenFound = true;
                NFTIndex = i;
				break;
				}
            }
		}
        require(tokenFound == true, "withdrawNFT, token not found");
		userInfo[_pid][sender].boostPointsBP -= 250;
		userInfo[_pid][sender].NFTContracts[NFTIndex] = userInfo[_pid][sender].NFTContracts[length -1];
		userInfo[_pid][sender].NFTContracts.pop();
		userInfo[_pid][sender].NFTTokenIDs[NFTIndex] = userInfo[_pid][sender].NFTTokenIDs[length -1];
		userInfo[_pid][sender].NFTTokenIDs.pop();
		updateUserWeightedBalance(_pid, sender);
		INFT(NFTContract).safeTransferFrom(address(this), sender, tokenID);
			emit NFTWithdrawn(sender, NFTContract, tokenID);
    }

    function boostWithNFT(uint256 _pid, address NFTContract, uint tokenID) public nonReentrant {
        // We allow vaults to interact with our contracts, but we believe that they shouldnt be allowed to stake NFTs to have all their users enjoy boosted rewards as a group.
        // In an effort to prevent this we dont allow other contracts to interact with this function. 
        // All other functions public functions are accessible and devs are more than welcomed to build on top of our contracts.
        require(msg.sender == tx.origin, "boostWithNFT : no contracts"); 
        require(isNFTContract[NFTContract], "boostWithNFT: incorrect contract address");
        require(userInfo[_pid][msg.sender].lockedUntil >= block.timestamp);
        updatePool(_pid);
        _addToClaimable(_pid, msg.sender);
        INFT(NFTContract).safeTransferFrom(msg.sender, address(this), tokenID);
        userInfo[_pid][msg.sender].NFTContracts.push(NFTContract);
		userInfo[_pid][msg.sender].NFTTokenIDs.push(tokenID);
        userInfo[_pid][msg.sender].boostPointsBP += 250;
        updateUserWeightedBalance(_pid, msg.sender);
		emit NFTWithdrawn(msg.sender, NFTContract, tokenID);
    }
    
    function addToClaimable(uint256 _pid, address sender) public nonReentrant {
        require(userInfo[_pid][sender].lockedUntil >= block.timestamp);
        updatePool(_pid);
        _addToClaimable(_pid, sender);
    }

    function depositFor(address sender, uint256 _pid, uint256 amount, uint256 lockTime) public onlyAuthorized {
        _deposit(sender, _pid, amount, lockTime);
    }

    function add(uint64 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint64 lastRewardBlock = uint64(block.number > startBlock ? block.number : startBlock);
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accRwtPerShare : 0,
        accETHPerShare : 0,
        weightedBalance : 0
        }));
    }

	function addNFTContract(address NFTcontract) public onlyOwner {
		isNFTContract[NFTcontract] = true;
	}

	function setETHBank(address _ETHBank) public onlyOwner {
	    ETHBank = _ETHBank;
	}

    function setRouter(address _router) public onlyOwner {
        router = _router;
    }
	
	// Pull out tokens accidentally sent to the contract. Doesnt work with the reward token or any staked token. Can only be called by the owner.
    function rescueToken(address tokenAddress) public onlyOwner {
        require((tokenAddress != address(nooneGovernanceToken)) && !poolExistence[IERC20(tokenAddress)], "rescueToken : wrong token address");
        uint256 bal = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(msg.sender, bal);
    }

    function set(uint256 _pid, uint64 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint ;
        poolInfo[_pid].allocPoint = _allocPoint;
    }
	
    function startRewards() public onlyOwner {
        require(startBlock > block.number, "startRewards: rewards already started");
        startBlock = block.number;
        for (uint i; i < poolInfo.length; i++) {
            poolInfo[i].lastRewardBlock = uint64(block.number);            
        }
    }

    function updateEmissionRate(uint256 _nooneGovernanceTokenPerBlock) public onlyOwner {
        require(tokenReleased == true, "updateEmissionRate: Reward token not set");
		massUpdatePools();
        nooneGovernanceTokenPerBlock = _nooneGovernanceTokenPerBlock;
        emit UpdateEmissionRate(msg.sender, _nooneGovernanceTokenPerBlock);
    }

    function setRewardToken(address _NooneGovernanceToken, uint _nooneGovernanceTokenPerBlock) public onlyOwner {
        require(tokenReleased == false, "Reward token already set");
        nooneGovernanceToken = IRewardToken(_NooneGovernanceToken);
        nooneGovernanceTokenPerBlock = _nooneGovernanceTokenPerBlock;
		tokenReleased = true;
        emit RewardTokenSet(_NooneGovernanceToken, _nooneGovernanceTokenPerBlock, block.timestamp);
    }
    
    function emergency(bool _isEmergency) public onlyOwner {
        isEmergency = _isEmergency;
        emit Emergency(block.timestamp, _isEmergency);
    }
    function authorize(address _address) public onlyOwner {
        authorized[_address] = true;
    }
    function unauthorize(address _address) public onlyOwner {
        authorized[_address] = false;
    }
    function setnumdays(uint256 _days) public onlyOwner {
        require(_days > 0 && _days < 14);
        numdays = _days;
    }
    
    function _deposit(address sender, uint256 _pid, uint256 _amount, uint256 lockTime) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][sender];
        updatePool(_pid);
        if (user.weightedBalance > 0) {
            if (_amount == 0 && lockTime == 0) {
                if(tokenReleased) {
                    uint256 pending = (user.weightedBalance * pool.accRwtPerShare / 1e12) - user.rewardDebt + user.claimableNooneGovernanceToken;
                    if (pending > 0) {
                        safeNooneGovernanceTokenTransfer(sender, pending);
                    }
                    user.rewardDebt = user.weightedBalance * pool.accRwtPerShare / 1e12;
                }
                uint256 ETHPending = (user.weightedBalance * pool.accETHPerShare / 1e12) - user.ETHrewardDebt + user.claimableETH;
                if (ETHPending > 0) { 
                    safeETHTransfer(sender, ETHPending);
                    user.ETHrewardDebt = user.weightedBalance * pool.accETHPerShare / 1e12;

                }
                user.claimableNooneGovernanceToken = 0;
                user.claimableETH = 0;
            }
            else {
                _addToClaimable(_pid, sender);
            }
        }
        if (_amount > 0) {
            require((lockTime >= 604800 && lockTime <= 31449600 && user.lockedUntil <= lockTime + block.timestamp) || (lockTime == 0 && user.lockedUntil >= block.timestamp), "deposit : Can't lock tokens for less than 1 week");
            //Still takes the tokens from msg.sender (intended)
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = uint112(user.amount + _amount);
            if (lockTime == 0) {
                updateUserWeightedBalance(_pid, sender);
            }
        }
		if (lockTime > 0) {
		    lockTokens(sender, _pid, lockTime);
		}
		if (user.lockedUntil < block.timestamp) {
		    updateUserWeightedBalance(_pid, sender);
		}
        emit Deposit(sender, _pid, _amount);
    }
    
    //Lock tokens up to 52 weeks for rewards boost, ( max rewards = x3, rewards increase linearly with lock time)
    function lockTokens(address sender, uint256 _pid, uint256 lockTime) internal {
        UserInfo storage user = userInfo[_pid][sender]; 
        require(user.amount > 0, "lockTokens: No tokens to lock"); 
        require(user.lockedUntil <= block.timestamp + lockTime, "lockTokens: Tokens already locked");
        require(lockTime >= 604800, "lockTokens: Lock time too short");
        require(lockTime <= 31449600, "lockTokens: Lock time too long");
        user.lockedUntil = uint32(block.timestamp + lockTime);
        user.lockTimeBoost = uint16(2 * 1000 * (lockTime-604800) / 30844800); // 0 - 2000 
        updateUserWeightedBalance(_pid, sender);
		emit TokensLocked(sender, block.timestamp, lockTime);
    }
    
    // calculate and update the user weighted balance
	function updateUserWeightedBalance(uint256 _pid, address _user) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
		uint256 poolBalance = pool.weightedBalance - user.weightedBalance;
		if (user.lockedUntil < block.timestamp) {
		    user.weightedBalance = 0;
		    user.lockTimeBoost = 0;
		}
		else {
            user.weightedBalance = user.amount * (1000 + user.lockTimeBoost) * (1000 + user.boostPointsBP) / 1000000;
        }
        pool.weightedBalance = uint112(poolBalance + user.weightedBalance);
		user.rewardDebt = user.weightedBalance * pool.accRwtPerShare / 1e12;
		user.ETHrewardDebt = user.weightedBalance * pool.accETHPerShare / 1e12;
    }
    

    function updateETHRewards() internal {
        massUpdatePools();
        ETHPerBlock = ETHLeftUnshared / (6400 * numdays);
    }
    
    function _addToClaimable(uint256 _pid, address sender) internal {
        UserInfo storage user = userInfo[_pid][sender];
        PoolInfo storage pool = poolInfo[_pid];
        if(tokenReleased) {
                uint256 pending = (user.weightedBalance * pool.accRwtPerShare / 1e12) - user.rewardDebt;
                if (pending > 0) {
                    user.claimableNooneGovernanceToken += uint96(pending);
                    user.rewardDebt = user.weightedBalance * pool.accRwtPerShare / 1e12;
                }
            }
            uint256 ETHPending = (user.weightedBalance * pool.accETHPerShare / 1e12) - user.ETHrewardDebt;
            if (ETHPending > 0) { 
                user.claimableETH += uint96(ETHPending);
                user.ETHrewardDebt = user.weightedBalance * pool.accETHPerShare / 1e12;
            }
    }

    // Safe transfer function, just in case if rounding error causes pool to not have enough NooneGovernanceTokens.
    function safeNooneGovernanceTokenTransfer(address _to, uint256 _amount) internal {
        uint256 nooneGovernanceTokenBal = nooneGovernanceToken.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > nooneGovernanceTokenBal) {
            transferSuccess = nooneGovernanceToken.transfer(_to, nooneGovernanceTokenBal);
        } else {
            transferSuccess = nooneGovernanceToken.transfer(_to, _amount);
        }
        require(transferSuccess, "safeNooneGovernanceTokenTransfer: transfer failed");
    }

    function safeETHTransfer(address _to, uint256 _amount) internal {
        if (_amount > ETHLeftUnclaimed) {
            _amount = ETHLeftUnclaimed;
        }
            payable(_to).transfer(_amount);
            ETHLeftUnclaimed-= _amount;
    }
}