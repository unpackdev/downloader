pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SilToken.sol";
import "./IMatchPair.sol";
import "./IWETH.sol";
import "./IMintRegulator.sol";
import "./IProxyRegistry.sol";
import "./TrustList.sol";
import "./PausePool.sol";



// SilMaster is the master of Sil. He can make Sil and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SIL is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract SilMaster is Ownable , TrustList, IProxyRegistry, PausePool{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 buff;       // if not `0`,1000-based, allow NFT Manager adjust the value of buff 

        uint256 totalDeposit;
        uint256 totalWithdraw;
    }

    // Info of each pool.
    struct PoolInfo {
        IMatchPair matchPair;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SILs to distribute per block.

        uint256 lastRewardBlock;  // Last block number that SILs distribution occurs by token0.

        uint256 totalDeposit0;  // totol deposit token0
        uint256 totalDeposit1;  // totol deposit token0

        uint256 accSilPerShare0; // Accumulated SILs per share, times 1e12. See below.
        uint256 accSilPerShare1; // Accumulated SILs per share, times 1e12. See below.
    }

    // The SIL TOKEN!
    SilToken public sil;
    // Dev address.
    address public devaddr;
    // 10% is the community reserve, which is used by voting through governance contracts
    address public ecosysaddr;
    // 0.5% fee will be collect , then repurchase Sil and distribute to depositor
    address public repurchaseaddr;
    // NFT will be published in future, for a interesting mining mode  
    address public nftProphet;

    address public WETH;
    //IMintRegulator 
    address public mintRegulator;
    // Block number when bonus SIL period ends.
    uint256 public bonusEndBlock;
    // SIL tokens created per block.
    uint256 public baseSilPerBlock;
    uint256 public silPerBlock;
    // Bonus muliplier for early sil makers.
    uint256 public bonus_multiplier;
    uint256 public maxAcceptMultiple = 3;
    uint256 public maxAcceptMultipleDenominator = 9;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SIL mining starts.
    uint256 public startBlock;
    // Fee repurchase SIL and redistribution
    uint256 public periodFinish;
    uint256 public feeRewardRate;
    // Prevent the invasion of giant whales
    bool public whaleSpear;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP(token0/token1) tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo0;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo1;
    // MatchPair delegatecall implmention
    mapping (uint256 => address) public matchPairRegistry;
    mapping (uint256 => bool) public matchPairPause;
    
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SilPerBlockUpdated(address indexed user, uint256 _molecular, uint256 _denominator);
    event WithdrawSilToken(address indexed user, uint256 indexed pid, uint256 silAmount0, uint256 silAmount1);

    constructor(
            SilToken _sil,
            address _devaddr,
            address _ecosysaddr,
            address _repurchaseaddr,
            address _weth
        ) public {
        sil = _sil;
        devaddr = _devaddr;
        ecosysaddr = _ecosysaddr;
        repurchaseaddr = _repurchaseaddr;
        WETH = _weth;
    }

    function initSetting(
        uint256 _silPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _bonus_multiplier)
        public
        onlyOwner()
    {
        require(startBlock == 0, "Init only once" );
        silPerBlock = _silPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        baseSilPerBlock = _silPerBlock;
        bonus_multiplier = _bonus_multiplier;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    /**
     * @dev adjust mint number by regulater.getScale()
     */
    function setMintRegulator(address _regulator) public onlyOwner() {
        mintRegulator = _regulator;
    }
    /**
     * @notice register delegate implementation
     */
    function matchPairRegister(uint256 _index, address _implementation) public onlyOwner() {
        matchPairRegistry[_index] = _implementation;
    }
    /**
     * @dev setting max accept multiple. must > 1
     * maxDepositAmount = pool.lp.tokenAmount * multiple - pool.pendingAmount
     */
    function setMintRegulator(uint _maxAcceptMultiple, uint _maxAcceptMultipleDenominator) public onlyOwner() {
        maxAcceptMultiple = _maxAcceptMultiple;
        maxAcceptMultipleDenominator = _maxAcceptMultipleDenominator;
    } 
    
    function setNFTProphet(address _nftProphet) public onlyOwner()  {
        nftProphet = _nftProphet;
    }
    
    function updateSilPerBlock() public {
        require(mintRegulator != address(0), "IMintRegulator not setting");

        (uint256 _molecular, uint256 _denominator)  = IMintRegulator(mintRegulator).getScale();
        uint256 silPerBlockNew = baseSilPerBlock.mul(_molecular).div(_denominator);
        if(silPerBlock != silPerBlockNew) {
             massUpdatePools();
             silPerBlock = silPerBlockNew;
        }
    
        emit SilPerBlockUpdated(msg.sender, _molecular, _denominator);
    }
    //Reserve shares for cross-chain
    function reduceSil(uint256 _reduceAmount) public onlyOwner() {

        baseSilPerBlock = baseSilPerBlock.sub(baseSilPerBlock.mul(_reduceAmount).div(sil.maxMint()));
        sil.reduce(_reduceAmount);
        //update Pool
        massUpdatePools();
        //update silPerBlock
        if(mintRegulator != address(0)) {
            updateSilPerBlock();
        }else {
            silPerBlock = baseSilPerBlock;
        }

    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IMatchPair _matchPair) public onlyOwner {

        // if (_withUpdate) {
        massUpdatePools();
        // }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            matchPair: _matchPair,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            totalDeposit0: 0,
            totalDeposit1: 0,
            accSilPerShare0: 0,
            accSilPerShare1: 0
            }));
    }
    //@notice Prevent unilateral mining of large amounts of funds
    function holdWhaleSpear(bool _hold) public onlyOwner {
        whaleSpear = _hold;
    }
    //@notice Update the given pool's SIL allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {

        massUpdatePools();
        
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {

        if(_from < startBlock) {
            _from = startBlock;
        }

        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(bonus_multiplier);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(bonus_multiplier).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    // View function to see pending SILs on frontend.
    function pendingSil(uint256 _pid, uint256 _index, address _user) external view   returns (uint256) {
        //if over limit pending is burn
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = _index == 0? userInfo0[_pid][_user] : userInfo1[_pid][_user];

        uint256 accSilPerShare = _index == 0? pool.accSilPerShare0 : pool.accSilPerShare1;
        uint256 lpSupply = _index == 0? pool.totalDeposit0 : pool.totalDeposit1;


        if (block.number > pool.lastRewardBlock && lpSupply != 0) {            
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            
            uint256 silReward = multiplier.mul(silPerBlock).mul(pool.allocPoint).div(totalAllocPoint);//
            uint256 totalMint = sil.balanceOf(address(this));
            if(sil.maxMint()< totalMint.add(silReward)) {
                silReward = sil.maxMint().sub(totalMint);
            }
            silReward = getFeeRewardAmount(pool.allocPoint, pool.lastRewardBlock).add(silReward);
            accSilPerShare = accSilPerShare.add(silReward.mul(1e12).div(lpSupply).div(2));
        } 
        return  amountBuffed(user.amount, user.buff).mul(accSilPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {

        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply0 = pool.totalDeposit0;
        uint256 lpSupply1 = pool.totalDeposit1;

        if(lpSupply0.add(lpSupply1) > 0 ) {
            uint256 silReward;
            if(!sil.mintOver()) {
                uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
                silReward = multiplier.mul(silPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            }
            //add fee Reward if exist
            silReward = getFeeRewardAmount(pool.allocPoint, pool.lastRewardBlock).add(silReward);
            // token0 side
            if(lpSupply0 > 0) {
                pool.accSilPerShare0 = pool.accSilPerShare0.add(silReward.mul(1e12).div(lpSupply0).div(2));
            }
            // token1 side
            if(lpSupply1 > 0) {
                pool.accSilPerShare1 = pool.accSilPerShare1.add(silReward.mul(1e12).div(pool.totalDeposit1).div(2));
            }
            if(lpSupply0 ==0 || lpSupply1==0) {
                silReward = silReward.div(2);
            }



            if(silReward > 0){        
                sil.mint(devaddr, silReward.mul(17).div(68)); // 17%
                sil.mint(ecosysaddr, silReward.mul(15).div(68)); // 15%
                sil.mint(address(this), silReward); // 68%
            }
        }
        
        pool.lastRewardBlock = block.number;
    }

    function getFeeRewardAmount(uint allocPoint, uint256 lastRewardBlock ) private view returns (uint256 feeReward) {
        if(feeRewardRate > 0) {

            uint256 endPoint = block.number < periodFinish ? block.number : periodFinish;
            if(endPoint > lastRewardBlock) {
                feeReward = endPoint.sub(lastRewardBlock).mul(feeRewardRate).mul(allocPoint).div(totalAllocPoint);
            }
        }
    }

    function batchGrantBuff(uint256[] calldata _pid, uint256[] calldata _index, uint256[] calldata _value, address[] calldata _user) public {
        require(msg.sender == nftProphet, "Grant buff: Prophet allowed");
        require(_pid.length > 0 , "_pid.length is zore");
        require(_pid.length ==  _index.length ,   "Require length equal: pid, index");
        require(_index.length ==  _value.length , "Require length equal: index, _value");
        require(_value.length ==  _user.length ,  "Require length equal: _value, _user");
        
        uint256 length = _pid.length;

        for (uint256 i = 0; i < length; i++) {
           grantBuff(_pid[i], _index[i], _value[i], _user[i]);
        }
    }

    function grantBuff(uint256 _pid, uint256 _index, uint256 _value, address _user) public {
        require(msg.sender == nftProphet, "Grant buff: Prophet allowed");

        UserInfo storage user = _index == 0  ? userInfo0[_pid][_user] : userInfo1[_pid][_user];
        // if user.amount == 0, just set `buff` value
        if (user.amount > 0 && !sil.mintOver()) {
            updatePool(_pid);

            PoolInfo storage pool = poolInfo[_pid];
            uint256 accPreShare;
            if(_index == 0) {
               accPreShare = pool.accSilPerShare0;
               pool.totalDeposit0 = pool.totalDeposit0
                                    .sub(amountBuffed(user.amount, user.buff))
                                    .add(amountBuffed(user.amount, _value));
            }else {
               accPreShare = pool.accSilPerShare1;
               pool.totalDeposit1 = pool.totalDeposit1
                                    .sub(amountBuffed(user.amount, user.buff))
                                    .add(amountBuffed(user.amount, _value));
            }

            uint256 pending = amountBuffed(user.amount, user.buff).mul(accPreShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeSilTransfer(_user, pending);
            }
            user.rewardDebt = amountBuffed(user.amount, _value).mul(accPreShare).div(1e12);
        }
        user.buff = _value;
    }

    function depositEth(uint256 _pid, uint256 _index ) public payable { 
        uint256 _amount = msg.value;
        uint256 acceptAmount;
        if(whaleSpear) {
            PoolInfo storage pool = poolInfo[_pid];
            acceptAmount = pool.matchPair.maxAcceptAmount(_index, maxAcceptMultiple, maxAcceptMultipleDenominator, _amount);
        }else {
            acceptAmount = _amount;
        }
        IWETH(WETH).deposit{value: acceptAmount}();
        deposit(_pid, _index, acceptAmount);
        //chargeback
        if(_amount > acceptAmount) {
            safeTransferETH(msg.sender , _amount.sub(acceptAmount));
        }
    }

    // Deposit LP tokens to SilMaster.
    function deposit(uint256 _pid, uint256 _index,  uint256 _amount) whenNotPaused(_pid) public  {
        //check account (normalAccount || trustable)
        checkAccount(msg.sender);
        bool _index0 = _index == 0;
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = _index0 ? userInfo0[_pid][msg.sender] : userInfo1[_pid][msg.sender];
        updatePool(_pid);
        if(whaleSpear) {

            _amount = pool.matchPair.maxAcceptAmount(_index, maxAcceptMultiple, maxAcceptMultipleDenominator, _amount);

        }
        
        uint256 accPreShare = _index0 ? pool.accSilPerShare0 : pool.accSilPerShare1;
       
        if (user.amount > 0 && !sil.mintOver()) {
            uint256 pending = amountBuffed(user.amount, user.buff).mul(accPreShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeSilTransfer(msg.sender, pending);
            }
        }

        if(_amount > 0) {
            address tokenTarget = pool.matchPair.token(_index);
            if(tokenTarget == WETH) {
                safeTransfer(WETH, address(pool.matchPair), _amount);
            }else{
                safeTransferFrom( pool.matchPair.token(_index), msg.sender,  address(pool.matchPair), _amount);
            }
            //stake to MatchPair
            pool.matchPair.stake(_index, msg.sender, _amount);
            user.amount = user.amount.add(_amount);
            user.totalDeposit = user.totalDeposit.add(_amount); 
            if(_index0) {
                pool.totalDeposit0 = pool.totalDeposit0.add(amountBuffed(_amount, user.buff));
            }else {
                pool.totalDeposit1 = pool.totalDeposit1.add(amountBuffed(_amount, user.buff));
            }
        }


        user.rewardDebt = amountBuffed(user.amount, user.buff).mul(accPreShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdrawToken(uint256 _pid, uint256 _index, uint256 _amount) public { 
        address _user = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];

        //withdrawToken from MatchPair

        uint256 untakeTokenAmount = pool.matchPair.untakeToken(_index, _user, _amount);
        address targetToken = pool.matchPair.token(_index);


        uint256 userAmount = untakeTokenAmount.mul(995).div(1000);

        withdraw(_pid, _index, _user, untakeTokenAmount);
        if(targetToken == WETH) {

            IWETH(WETH).withdraw(untakeTokenAmount);

            safeTransferETH(_user, userAmount);
            safeTransferETH(repurchaseaddr, untakeTokenAmount.sub(userAmount) );
        }else {
            safeTransfer(pool.matchPair.token(_index),  _user, userAmount);
            safeTransfer(pool.matchPair.token(_index),  repurchaseaddr, untakeTokenAmount.sub(userAmount));
        }
    }
    // Withdraw LP tokens from SilMaster.
    function withdraw( uint256 _pid, uint256 _index, address _user, uint256 _amount) whenNotPaused(_pid)  private {
        
        bool _index0 = _index == 0;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = _index0? userInfo0[_pid][_user] :  userInfo1[_pid][_user];
        //record withdraw origin Amount
        user.totalWithdraw = user.totalWithdraw.add(_amount);
        if(user.amount < _amount) {
            _amount = user.amount;
        }
        updatePool(_pid);

        uint256 accPreShare = _index0 ? pool.accSilPerShare0 : pool.accSilPerShare1;
        uint256 pending = amountBuffed(user.amount, user.buff).mul(accPreShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeSilTransfer(_user, pending);
        }

        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            if(_index0) {
                pool.totalDeposit0 = pool.totalDeposit0.sub(amountBuffed(_amount, user.buff));
            }else {
                pool.totalDeposit1 = pool.totalDeposit1.sub(amountBuffed(_amount, user.buff));
            }
        }
        user.rewardDebt = amountBuffed(user.amount, user.buff).mul(accPreShare).div(1e12);
        emit Withdraw(_user, _pid, _amount);
    }
    /**
     * @dev withdraw SILToken mint by deposit token0 & token1
     */
    function withdrawSil(uint256 _pid) public {

        updatePool(_pid);

        uint256 silAmount0 = withdrawSilCalcu(_pid, 0, msg.sender);
        uint256 silAmount1 = withdrawSilCalcu(_pid, 1, msg.sender);

        safeSilTransfer(msg.sender, silAmount0.add(silAmount1));
        
        emit WithdrawSilToken(msg.sender, _pid, silAmount0, silAmount1);
    }

    function withdrawSilCalcu(uint256 _pid, uint256 _index,  address _user) private returns (uint256 silAmount) {
        bool _index0 = _index == 0;
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = _index0 ? userInfo0[_pid][_user] : userInfo1[_pid][_user];
        
        uint256 accPreShare = _index0 ? pool.accSilPerShare0 : pool.accSilPerShare1;

        if (user.amount > 0) {
            silAmount = amountBuffed(user.amount, user.buff).mul(accPreShare).div(1e12).sub(user.rewardDebt);
        }
        user.rewardDebt = amountBuffed(user.amount, user.buff).mul(accPreShare).div(1e12);
    }

    // Safe sil transfer function, just in case if rounding error causes pool to not have enough SILs.
    function safeSilTransfer(address _to, uint256 _amount) internal {
        uint256 silBal = sil.balanceOf(address(this));
        if (_amount > silBal) {
            sil.transfer(_to, silBal);
        } else {
            sil.transfer(_to, _amount);
        }
    }

    function amountBuffed(uint256 amount, uint256 buff) private pure returns (uint256) {
        if(buff == 0) {
            return amount;
        }else {
            return amount.mul(buff).div(1000);
        }
    }

    function mintableAmount(uint256 _pid, uint256 _index, address _user) external view returns (uint256) {

        UserInfo storage user = _index == 0? userInfo0[_pid][_user] :  userInfo1[_pid][msg.sender];
        return user.amount;
    }


    function getProxy(uint256 _index) external  view override returns(address) {
        require(!matchPairPause[_index], "Proxy paused, waiting upgrade via governance");
        return matchPairRegistry[_index];
    }

    /**
     * @notice to protect fund of users, 
     * allow developers to pause then upgrade via community governor
     */
    function pauseProxy(uint256 _pid, bool _paused) public {
        require(msg.sender == devaddr, "dev sender required");
        matchPairPause[_pid] = _paused;
    }

    function pause(uint256 _pid, bool _paused) public {
        require(msg.sender == devaddr, "dev sender required");
        pausePoolViaPid(_pid, _paused);
    }
    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function ecosys(address _ecosysaddraddr) public {
        require(msg.sender == ecosysaddr, "ecosys: wut?");
        ecosysaddr = _ecosysaddraddr;
    }
    
    function repurchase(address _repurchaseaddr) public {
        require(msg.sender == repurchaseaddr, "repurchase: wut?");
        repurchaseaddr = _repurchaseaddr;
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'MasterTransfer: TRANSFER_FROM_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'MasterTransfer: TRANSFER_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'MasterTransfer: ETH_TRANSFER_FAILED');
    }

    function notifyRewardAmount(uint256 reward, uint256 duration)
        onlyOwner
        external
    {
        //update all poll first
        massUpdatePools();
        if (block.number >= periodFinish) {
            feeRewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.number);
            uint256 leftover = remaining.mul(feeRewardRate);
            feeRewardRate = reward.add(leftover).div(duration);
        }
        periodFinish = block.number.add(duration);

    }

    function checkAccount(address _account) private {
        require(!_account.isContract() || trustable(_account) , "High risk account");
    }

    receive() external payable {
        require(msg.sender == WETH, "only accept from WETH"); // only accept ETH via fallback from the WETH contract
    }
}
