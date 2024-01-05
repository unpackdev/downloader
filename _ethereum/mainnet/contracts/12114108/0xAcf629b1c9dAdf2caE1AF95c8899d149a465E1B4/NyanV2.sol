pragma solidity ^0.6.6;

import "./ERC20.sol";


interface CatnipV2 {
    function nyanV2LPStaked(address, uint256) external;   
    function nyanV2LPUnstaked(address, uint256) external;
    function dNyanV2LPStaked(address, uint256) external;
    function dNyanV2LPUnstaked(address, uint256) external;
}

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

contract LibraryLockDataLayout {
  bool public initialized = false;
}

contract LibraryLock is LibraryLockDataLayout {
    // Ensures no one can manipulate the Logic Contract once it is deployed.
    // PARITY WALLET HACK PREVENTION

    modifier delegatedOnly() {
        require(initialized == true, "The library is locked. No direct 'call' is allowed");
        _;
    }
    function initialize() internal {
        initialized = true;
    }
}

contract NyanV2DataLayout is LibraryLock {
    address public owner;
    address public fundAddress;
    address public catnipV2;
    uint256 public lastBlockSent;
    uint256 public totalNyanV1Swapped;
    
    address public nyanV1;
    address public nyanV2LP;
    address public dNyanV2LP;
    
    uint256 public rewardsPercentage;
    
    // Track user's staked Nyan LP
    struct stakeTracker {
        uint256 stakedNyanV2LP;
        uint256 stakedDNyanV2LP;
        uint256 nyanV2Rewards;
        uint256 lastBlockChecked;
        uint256 blockStaked;
    }
    mapping(address => stakeTracker) public userStake;

    struct lpRestriction {
        bool restricted;
    }
    mapping(address => lpRestriction) public restrictedLP;
    
    uint256 public ETHLGEEndBlock;
    uint256 public totalNyanSupplied;
    uint256 public totalETHSupplied;
    uint256 public lpTokensGenerated;
    bool public isETHLGEOver;
    
    struct ETHLGETracker {
        uint256 nyanContributed;
        uint256 ETHContributed;
        bool claimed;
    }
    mapping(address => ETHLGETracker) public userETHLGE;
    
    address public votingContract;
    
    address public nyanV1LP;
    
    address public nyanNFT;
    address public dNyanV2;

    using SafeMath for uint112;

    bool isVotingStakingLive;

    uint256 public lastLPCount;
    uint256 public nyanPoolMax;

    uint256 public nyanRewardsPerDay;
    uint256 public rewardsClaimed;
    uint256 public lastNyanCheckpoint;

    struct rewardsSync {
      uint256 currentStakerCheckpoint;
      uint256 currentContractNyanHeld;
    }
    mapping(address => rewardsSync) public rSync;
    uint256 public initialNyanCheckpoint;
    uint256 public initialContractNyanHeld;
    bool public checkpointReset;
    uint256 public totalNyanV2Held;

    bool public rewardsWithdrawalPaused;
    struct rewardsReset {
      bool isRewardsReset;
    }
    mapping(address => rewardsReset) public rReset;
    uint256 public miningDifficulty; //initial difficulty

    struct swapTracker {
      uint256 swapMaximum;
      bool nyanMaxSet;
      bool nyanLPMaxSet;
    }
    mapping(address => swapTracker) public swapTrackerMap; 

    address public easyBid;
    mapping(address => bool) public LPWithdrawalLocked;

    bool public stakingAllowed;
    bool public isExitPeriod;
    mapping(address => bool) public hasExited;
    uint256 public finalLPAmount;
    mapping(address => bool) public userCanStake;
    
    struct claimLock {
        uint256 unlockBlock;
    }
    mapping(address => claimLock) public userClaimLock;
    uint256 public lockPeriod;
    
    mapping(address => bool) public canContractLock;
}

contract NyanV2 is ERC20, NyanV2DataLayout, Proxiable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    //modifier for updating staker rewards
    modifier _updateRewards() {
        // if (!rReset[msg.sender].isRewardsReset 
        //     && userStake[msg.sender].blockStaked < 11225955
        //     && userStake[msg.sender].blockStaked > 1000) {
        //   if (userStake[msg.sender].lastBlockChecked < lastNyanCheckpoint) {
        //     userStake[msg.sender].lastBlockChecked = lastNyanCheckpoint;
        //   }
          
        //   userStake[msg.sender].nyanV2Rewards = 0;
        //   rReset[msg.sender].isRewardsReset = true;
        // }
        // if (miningDifficulty < 250000) {
        //   miningDifficulty = 250000;
        // }
        
        // if (block.number > userStake[msg.sender].lastBlockChecked) {
        //     uint256 rewardBlocks = block.number.sub(userStake[msg.sender].lastBlockChecked);
        //     uint256 stakedAmount = userStake[msg.sender].stakedNyanV2LP;
        //     if (userStake[msg.sender].stakedDNyanV2LP > 0) {
        //         stakedAmount = stakedAmount.add(userStake[msg.sender].stakedDNyanV2LP);
        //     }
        //     if (userStake[msg.sender].stakedNyanV2LP > 0) {
        //         uint256 reward = stakedAmount.mul(rewardBlocks) / miningDifficulty;
        //         userStake[msg.sender].nyanV2Rewards = userStake[msg.sender].nyanV2Rewards.add(reward);
        //         userStake[msg.sender].lastBlockChecked = block.number;
        //     }
        //     rReset[msg.sender].isRewardsReset = true;
        // }

        _;
    }
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event nyanV1Swapped(address indexed user, uint256 amount);
    event nyanV2LPStaked(address indexed user, uint256 amount);
    event nyanV2LPUnstaked(address indexed user, uint256 amount);
    event dNyanV2LPStaked(address indexed user, uint256 amount);
    event dNyanV2LPUnstaked(address indexed user, uint256 amount);
    event nyanV2RewardsClaimed(address indexed user, uint256 amount);
    event transferFeeSubtracted(address indexed user, uint256 amount);
    event nyanV2LPAddressSet(address newAddress);
    event dNyanV2LPAddressSet(address newAddress);
    event logicContractUpdated(address newAddress);
    event NyanFundAddressSet(address newAddress);


    constructor() public payable ERC20("Nyan V2", "NYAN-2") {
        
    }
    
    function nyanConstructor(address _nyanV1, address _fundAddress, uint256 _rewardsPercentage, uint256 _ETHLGEEndBlock) public  {
        require(!initialized);
        constructor1("Nyan V2", "NYAN-2");
        rewardsPercentage = _rewardsPercentage;
        nyanV1 = _nyanV1;
        fundAddress = _fundAddress;
        lastBlockSent = block.number;
        owner = msg.sender;
        ETHLGEEndBlock = _ETHLGEEndBlock;
        initialize();
    }
    
    /** @notice Sets contract owner.
      * @param _owner  Address of the new owner.
      */
    function setOwner(address _owner) public _onlyOwner delegatedOnly  {
        owner = _owner;
    }
    
    /** @notice Updates the logic contract.
      * @param newCode  Address of the new logic contract.
      */
    function updateCode(address newCode) public _onlyOwner delegatedOnly  {
        updateCodeAddress(newCode);
        
        emit logicContractUpdated(newCode);
    }
    
    /** @notice Swaps an amount NyanV1 for NyanV2.
      * @param _amount Amount of Nyan being swapped.
      */
    function swapNyanV1(uint256 _amount) public delegatedOnly {
       require(isETHLGEOver, "ETH LGE is ongoing");
       require(_amount <= swapTrackerMap[msg.sender].swapMaximum);
       IERC20(nyanV1).safeTransferFrom(msg.sender, address(this), _amount);
       uint256 currentBalance = balanceOf(msg.sender);
       _mint(msg.sender, _amount);
       require(balanceOf(msg.sender).sub(currentBalance) == _amount, "Swap failed");
       totalNyanV1Swapped = totalNyanV1Swapped.add(_amount);
       swapTrackerMap[msg.sender].swapMaximum = swapTrackerMap[msg.sender].swapMaximum.sub(_amount);
       
       emit nyanV1Swapped(msg.sender, _amount);
    }
    
    /** @notice Stake an amount of NyanV2 LP tokens.
      * @param _amount Amount of liquidity tokens being staked.
      */
    function stakeNyanV2LP(uint256 _amount) public delegatedOnly _updateRewards {
       IERC20(nyanV2LP).safeTransferFrom(msg.sender, address(this), _amount);
       userStake[msg.sender].stakedNyanV2LP = userStake[msg.sender].stakedNyanV2LP.add(_amount);
       userStake[msg.sender].blockStaked = block.number;
       //Notify CatnipV2 contract
       CatnipV2(catnipV2).nyanV2LPStaked(msg.sender, _amount);
       
       emit nyanV2LPStaked(msg.sender, _amount);
    }
    
    // /** @notice Unstake an amount of NyanV2 LP tokens.
    //   * @param _amount Amount of liquidity tokens being unstaked.
    //   */
    function unstakeNyanV2LP(uint256 _amount) public _updateRewards delegatedOnly {
        //change to a time based lock
        require(!LPWithdrawalLocked[msg.sender], "LP Withdrawal locked");
        require(_amount <= userStake[msg.sender].stakedNyanV2LP, "Insufficient stake balance");
        IERC20(nyanV2LP).safeTransfer(msg.sender, _amount);
        userStake[msg.sender].stakedNyanV2LP = userStake[msg.sender].stakedNyanV2LP.sub(_amount);

        //Notify CatnipV2 contract
        CatnipV2(catnipV2).nyanV2LPUnstaked(msg.sender, _amount);
       
        emit nyanV2LPUnstaked(msg.sender, _amount);
    }
    
    // /** @notice Stake an amount of DNyanV2 LP tokens.
    //   * @param _amount Amount of liquidity tokens being staked.
    //   */
    function stakeDNyanV2LP(uint256 _amount) public _updateRewards delegatedOnly {
       IERC20(dNyanV2LP).safeTransferFrom(msg.sender, address(this), _amount);
       userStake[msg.sender].stakedDNyanV2LP = userStake[msg.sender].stakedDNyanV2LP.add(_amount);
       userStake[msg.sender].blockStaked = block.number;

       //Notify CatnipV2 contract
       CatnipV2(catnipV2).dNyanV2LPStaked(msg.sender, _amount);
       
       emit dNyanV2LPStaked(msg.sender, _amount);
    }
    
    /** @notice Unstake an amount of DNyanV2 LP tokens.
      * @param _amount Amount of liquidity tokens being unstaked.
      */
    function unstakeDNyanV2LP(uint256 _amount) public _updateRewards delegatedOnly {
       require(_amount <= userStake[msg.sender].stakedDNyanV2LP, "Insufficient stake balance");
       IERC20(dNyanV2LP).safeTransfer(msg.sender, _amount);
       userStake[msg.sender].stakedDNyanV2LP = userStake[msg.sender].stakedDNyanV2LP.sub(_amount);

       //Notify CatnipV2 contract
       CatnipV2(catnipV2).dNyanV2LPUnstaked(msg.sender, _amount);
       
       emit dNyanV2LPUnstaked(msg.sender, _amount);
    }
    
    /** @notice Get where last block the voter staked was.
      * @param _voter Address of the voter.
      */
    function getVoterBlockStaked(address _voter) delegatedOnly public view returns(uint256) {
        return userStake[_voter].blockStaked;
    }
    
    // function viewNyanRewards(address staker) delegatedOnly public view returns(uint256) {
    //     uint256 currentRewards = userStake[staker].nyanV2Rewards;
    //     uint256 stakerLastBlock = userStake[staker].lastBlockChecked;
    //     if (!rReset[staker].isRewardsReset) {
    //       stakerLastBlock = initialNyanCheckpoint;
    //       currentRewards = 0;
    //     } else {
    //       stakerLastBlock = userStake[staker].lastBlockChecked;
    //     }

    //     if (block.number > stakerLastBlock) {
    //         uint256 rewardBlocks = block.number.sub(stakerLastBlock);
            
    //         uint256 stakedAmount = userStake[staker].stakedNyanV2LP;
    //         if (userStake[staker].stakedDNyanV2LP > 0) {
    //             stakedAmount = stakedAmount.add(userStake[staker].stakedDNyanV2LP);
    //         }
    //         if (userStake[staker].stakedNyanV2LP > 0) {
    //             uint256 reward = stakedAmount.mul(rewardBlocks) / miningDifficulty;
    //             currentRewards = currentRewards.add(reward);
                
    //         }
            
    //     }

    //     return currentRewards;
    // } 
    
    // /** @notice Get the Nyan rewards of msg.sender.*/
    // function getNyanRewards() public _updateRewards delegatedOnly {
    //    require(!rewardsWithdrawalPaused);
    //    require(userStake[msg.sender].nyanV2Rewards > 0, "Zero rewards balance");
    //    IERC20(address(this)).safeTransfer(msg.sender, userStake[msg.sender].nyanV2Rewards);
       
    //    emit nyanV2RewardsClaimed(msg.sender, userStake[msg.sender].nyanV2Rewards);
    //    userStake[msg.sender].nyanV2Rewards = 0;
    // }
    
    /** @notice Override ERC20 transfer function with transfer fee and LP algo.
      * @param _recipient Recepient of the transfer.
      * @param _amount Amount of tokens being transferred.
      */
    function transfer(address _recipient, uint256 _amount) delegatedOnly public override returns(bool) {    
        //check if user is in lock period
        require(userClaimLock[msg.sender].unlockBlock < block.number);
        return super.transfer(_recipient, _amount);
    }
    
    /** @notice Override ERC20 transferFrom function with transfer fee.
      * @param _sender Owner of the tokens being transferred.
      * @param _recipient Recepient of the transfer.
      * @param _amount Amount of tokens being transferred.
      */
    function transferFrom(address _sender, address _recipient, uint256 _amount) delegatedOnly public override returns(bool) {
        //check if user is in lock period
        require(userClaimLock[_sender].unlockBlock < block.number);
        return super.transferFrom(_sender, _recipient, _amount);
    }
      
    event UniswapAddressesSet(address factory, address router);
    event LGEEndBlockSet(uint256 block);
    event NyanxETHSupplied(address indexed user, uint256 nyanAmount, uint256 ETHAmount);
    
    
    
    address public uniswapRouterV2;
    address public uniswapFactory;
    
    
    // /** @notice Allows an LGE participant to claim a portion of NyanV2/ETH LP held by the contract.
    //   */
    function claimETHLP() public {
        require(isETHLGEOver, "ETH LGE is still ongoing");
        require(userETHLGE[msg.sender].nyanContributed > 0);
        require(!userETHLGE[msg.sender].claimed);
        uint256 claimableLP = userETHLGE[msg.sender].nyanContributed.mul(lpTokensGenerated).div(totalNyanSupplied);
        ERC20(nyanV2LP).transfer(msg.sender, claimableLP);
        string memory tier;
        if (userETHLGE[msg.sender].ETHContributed < 3000000000000000000) {
            tier = "COMMON";
        }
        if (userETHLGE[msg.sender].ETHContributed < 6000000000000000000) {
            tier = "UNCOMMON";
        }
        if (userETHLGE[msg.sender].ETHContributed < 18000000000000000000) {
            tier = "RARE";
        }
        if (userETHLGE[msg.sender].ETHContributed < 36000000000000000000) {
            tier = "EPIC";
        }
        if (userETHLGE[msg.sender].ETHContributed > 36000000000000000000) {
            tier = "LEGENDARY";
        }
        NyanNFT(nyanNFT).createNFT(msg.sender, tier);
        userETHLGE[msg.sender].claimed = true;
    }
    

    // /** @notice Allows an LGE participant to claim a portion of NyanV2/ETH LP held by the contract and stake it.
    //   */
    function claimETHLPAndStake() public {
        require(isETHLGEOver, "ETH LGE is still ongoing");
        require(userETHLGE[msg.sender].nyanContributed > 0);
        require(!userETHLGE[msg.sender].claimed);
        uint256 claimableLP = userETHLGE[msg.sender].nyanContributed.mul(lpTokensGenerated).div(totalNyanSupplied);
        string memory tier;
        if (userETHLGE[msg.sender].ETHContributed < 3000000000000000000) {
            tier = "COMMON";
        }
        if (userETHLGE[msg.sender].ETHContributed < 6000000000000000000) {
            tier = "UNCOMMON";
        }
        if (userETHLGE[msg.sender].ETHContributed < 18000000000000000000) {
            tier = "RARE";
        }
        if (userETHLGE[msg.sender].ETHContributed < 36000000000000000000) {
            tier = "EPIC";
        }
        if (userETHLGE[msg.sender].ETHContributed >= 36000000000000000000) {
            tier = "LEGENDARY";
        }
        NyanNFT(nyanNFT).createNFT(msg.sender, tier);
        
        userStake[msg.sender].stakedNyanV2LP = userStake[msg.sender].stakedNyanV2LP.add(claimableLP);
        userStake[msg.sender].blockStaked = block.number;
        //Notify CatnipV2 contract
        CatnipV2(catnipV2).nyanV2LPStaked(msg.sender, userStake[msg.sender].stakedNyanV2LP);
        if (isVotingStakingLive) {
          NyanVoting(votingContract).nyanV2LPStaked(userStake[msg.sender].stakedNyanV2LP, msg.sender);
        }
        userETHLGE[msg.sender].claimed = true;
    }

    // /** @notice Sets if the Voting contract is live.
    //   * @param _isVoting bool
    //   */
    // function setIsVoting(bool _isVoting) public _onlyOwner {
    //     isVotingStakingLive = _isVoting;
    // }


    // function setIsRewarding(bool _isRewarding) public _onlyOwner {
    //   rewardsWithdrawalPaused = _isRewarding;
      
    // }

    // function setMiningDifficulty(uint256 _amount) public _onlyOwner {
    //   miningDifficulty = _amount;
    // }

    function setSwapMax(address holder, uint256 amount) public _onlyOwner delegatedOnly {
      swapTrackerMap[holder].swapMaximum = amount;
    }

    function setEasyBidAddress(address _easyBid) public _onlyOwner delegatedOnly {
      easyBid = _easyBid;
    }

    function lockUserLP(address staker, bool lock) public delegatedOnly {
      require(msg.sender == easyBid);
      LPWithdrawalLocked[staker] = lock;
    }
    
    function setLockPeriod(uint256 _amount) public _onlyOwner delegatedOnly {
        lockPeriod = _amount;
    }
    
    function setAllowedContracts(address _contract, bool status) public _onlyOwner delegatedOnly {
        canContractLock[_contract] = status;
    }
    
    function lockNyan(address holder) public delegatedOnly {
        require(canContractLock[msg.sender]);
        userClaimLock[holder].unlockBlock = block.number.add(lockPeriod);
    }
    
    function lockNyanLP(address staker) public delegatedOnly {
        require(canContractLock[msg.sender]);
        userClaimLock[staker].unlockBlock = block.number.add(lockPeriod);
    }

    function reduceLPAmount(address staker, uint256 amount) public delegatedOnly {
      require(msg.sender == easyBid);
      userStake[staker].stakedNyanV2LP = userStake[staker].stakedNyanV2LP.sub(amount);
      CatnipV2(catnipV2).nyanV2LPUnstaked(staker, amount);
    }

    function getStakedNyanV2LP(address staker) public view returns(uint256) {
      return userStake[staker].stakedNyanV2LP;
    }

    function getBlockStaked(address staker) public view returns(uint256) {
      return userStake[staker].blockStaked;
    }

    function setVotingContract(address _votingContract) public _onlyOwner delegatedOnly {
      votingContract = _votingContract;
    }

    receive() external payable {
        
    }

} 



interface NyanVoting {
    function nyanV2LPStaked(uint256, address) external;
    function nyanV2LPUnstaked(uint256, address) external;
}

interface NyanNFT {
    function createNFT(address, string calldata) external;
}

interface CatnipV1 {
    function getAddressStakeAmount(address _account) external returns(uint256);
}

interface Connector {
  function exitClaim(address user, uint256 amount) external;
}