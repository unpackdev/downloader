// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./AddressPayable.sol";

import "./INestPool.sol";
import "./INestStaking.sol";

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";

/// @title NestStaking
/// @author Inf Loop - <inf-loop@nestprotocol.org>
/// @author Paradox  - <paradox@nestprotocol.org>

contract NestStaking is INestStaking, ReentrancyGuard {

    using SafeMath for uint256;

    /* ========== STATE ============== */

    /// @dev  The flag of staking global state
    uint8 public flag;      // = 0: uninitialized
                            // = 1: active
                            // = 2: no staking
                            // = 3: paused 

    uint248 private _reserved1;

    uint8 constant STAKING_FLAG_UNINITIALIZED    = 0;
    uint8 constant STAKING_FLAG_ACTIVE           = 1;
    uint8 constant STAKING_FLAG_NO_STAKING       = 2;
    uint8 constant STAKING_FLAG_PAUSED           = 3;

    /// @dev The balance of savings w.r.t a ntoken(or nest-token)
    ///     _pending_saving_Amount: ntoken => saving amount
    //mapping(address => uint256) private _pending_saving_amount;

    /// @dev The per-ntoken-reward (ETH) w.r.t a ntoken(or nest-token)
    ///     _reward_per_ntoken_stored: ntoken => amount
    mapping(address => uint256) private _reward_per_ntoken_stored;

    // _reward_per_ntoken_claimed: (ntoken, acount, amount) => amount
    mapping(address => mapping(address => uint256)) _reward_per_ntoken_claimed;

    // ntoken => last reward 
    mapping(address => uint256) public lastRewardsTotal;

    // _ntoken_total: ntoken => amount
    mapping(address => uint256) _ntoken_staked_total;

    // _staked_balances: (ntoken, account) => amount
    mapping(address => mapping(address => uint256)) private _staked_balances;

    // rewardsTotal: (ntoken) => amount
    mapping(address => uint256) public rewardsTotal;
    
    // _rewards_balances: (ntoken, account) => amount
    mapping(address => mapping(address => uint256)) public rewardBalances;

    /* ========== PARAMETERS ============== */
    
    /// @dev The percentage of dividends 
    uint8 private _dividend_share; // = 100 as default;

    uint8 constant STAKING_DIVIDEND_SHARE_PRECENTAGE = 100;

    uint248 private _reserved2;

    /* ========== ADDRESSES ============== */

    address private C_NestToken;
    address private C_NestPool;

    address private governance;

    /* ========== CONSTRUCTOR ========== */

    receive() external payable {}

    // NOTE: to support open-zeppelin/upgrades, leave it blank
    constructor() public { }

    /// @dev It is called by the proxy (open-zeppelin/upgrades), only ONCE!
    function initialize(address NestPool) external 
    {
        require(flag == STAKING_FLAG_UNINITIALIZED, "Nest:Stak:!flag");
        governance = msg.sender;
        _dividend_share = STAKING_DIVIDEND_SHARE_PRECENTAGE;
        flag = STAKING_FLAG_ACTIVE;
        C_NestPool = NestPool;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovOrBy(address _contract) 
    {
        require(msg.sender == governance || msg.sender == _contract, "Nest:Stak:!sender");
        _;
    }

    modifier whenActive() 
    {
        require(flag == STAKING_FLAG_ACTIVE, "Nest:Stak:!flag");
        _;
    }

    modifier onlyGovernance() 
    {
        require(msg.sender == governance, "Nest:Stak:!gov");
        _;
    }

    mapping(uint256 => mapping(address => bool)) private _status;

    modifier onlyOneBlock() {
        require(
            !_status[block.number][tx.origin],
            'Nest:Stak:!block'
        );
        require(
            !_status[block.number][msg.sender],
            'Nest:Stak:!block'
        );

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }

    /* ========== GOVERNANCE ========== */

    function loadContracts() override external onlyGovOrBy(C_NestPool)
    {
        C_NestToken = INestPool(C_NestPool).addrOfNestToken();
    }

    /// @dev To ensure that all of governance-addresses be consist with each other
    function loadGovernance() override external 
    { 
        governance = INestPool(C_NestPool).governance();
    }

    /// @dev Stop service for emergency
    function pause() override external onlyGovernance
    {
        require(flag == STAKING_FLAG_ACTIVE, "Nest:Stak:!flag");
        flag = STAKING_FLAG_PAUSED;
        emit FlagSet(address(msg.sender), uint256(STAKING_FLAG_PAUSED));
    }

    /// @dev Resume service 
    function resume() override external onlyGovernance
    {
        require(flag == STAKING_FLAG_PAUSED, "Nest:Stak:!flag");
        flag = STAKING_FLAG_ACTIVE;
        emit FlagSet(address(msg.sender), uint256(STAKING_FLAG_ACTIVE));
    }

    /*
    // exist bug
    function withdrawSavingByGov(address ntoken, address to, uint256 amount) 
        external 
        nonReentrant 
        onlyGovernance 
    {
        require(flag == STAKING_FLAG_PAUSED, "Nest:Stak:!flag");

        _pending_saving_amount[ntoken] = _pending_saving_amount[ntoken].sub(amount);

        // must refresh WETH balance record after updating WETH balance
        // or lastRewardsTotal could be less than the newest WETH balance in the next update
        uint256 _newTotal = rewardsTotal[ntoken].sub(amount);
        lastRewardsTotal[ntoken] = _newTotal;
        rewardsTotal[ntoken] = _newTotal;
        emit SavingWithdrawn(ntoken, to, amount);
        TransferHelper.safeTransferETH(to, amount);      
    }
   
    function setParams(uint8 dividendShareRate) override external onlyGovernance
    {
        if (dividendShareRate > 0 && dividendShareRate <= 100) {
            _dividend_share = dividendShareRate;
        }
    }
    */
    /* ========== VIEWS ========== */
    /*
    function totalSaving(address ntoken)
        external view returns (uint256) 
    {
       return  _pending_saving_amount[ntoken];
    }
    */
    function totalRewards(address ntoken)
        external view returns (uint256) 
    {
       return  rewardsTotal[ntoken];
    }

    function totalStaked(address ntoken) 
        external override view returns (uint256) 
    {
        return _ntoken_staked_total[ntoken];
    }

    function stakedBalanceOf(address ntoken, address account) 
        external override view returns (uint256) 
    {
        return _staked_balances[ntoken][account];
    }

    // CM: <tokenShare> = <OldTokenShare> + (<NewTokenShare> * _dividend_share% / <tokenAmount>) 
    function rewardPerToken(address ntoken) 
        public 
        view 
        returns (uint256) 
    {
        uint256 _total = _ntoken_staked_total[ntoken];
        if (_total == 0) {
            // use the old rewardPerTokenStored
            // if not, the new accrued amount will never be distributed to anyone
            return _reward_per_ntoken_stored[ntoken];
        }
        uint256 _rewardPerToken = _reward_per_ntoken_stored[ntoken].add(
                accrued(ntoken).mul(1e18).mul(_dividend_share).div(_total).div(100)
            );
        return _rewardPerToken;
    }

    // CM: <NewTokenShare> = <rewardToken blnc> - <last blnc>
    function accrued(address ntoken) 
        public 
        view 
        returns (uint256) 
    {
        // eth increment of eth since last update
        uint256 _newest = rewardsTotal[ntoken];
        // lastest must be larger than lastUpdate
        return _newest.sub(lastRewardsTotal[ntoken]); 
    }

    // CM: <user share> = [<tokenAmonut> * (<tokenShare> - <tokenShareCollected>) / 1e18] + <reward>
    function earned(address ntoken, address account) 
        public 
        view 
        returns (uint256) 
    {
        return _staked_balances[ntoken][account].mul(
                        rewardPerToken(ntoken).sub(_reward_per_ntoken_claimed[ntoken][account])
                    ).div(1e18).add(rewardBalances[ntoken][account]);
    }
    /*  // it is extra
    // calculate
    function _rewardPerTokenAndAccrued(address ntoken) 
        internal
        view 
        returns (uint256, uint256) 
    {
        uint256 _total = _ntoken_staked_total[ntoken];
        if (_total == 0) {
            // use the old rewardPerTokenStored, and accrued should be zero here
            // if not the new accrued amount will never be distributed to anyone
            return (_reward_per_ntoken_stored[ntoken], 0);
        }
        uint256 _accrued = accrued(ntoken);
        uint256 _rewardPerToken = _reward_per_ntoken_stored[ntoken].add(
                _accrued.mul(1e18).mul(_dividend_share).div(_total).div(100) 
            ); // 80% of accrued to NEST holders as dividend
        return (_rewardPerToken, _accrued);
    }
    */
    /* ========== STAK/UNSTAK/CLAIM ========== */

    modifier updateReward(address ntoken, address account) 
    {
        uint256 _total = _ntoken_staked_total[ntoken];
        uint256 _accrued = rewardsTotal[ntoken].sub(lastRewardsTotal[ntoken]);
        uint256 _rewardPerToken;      

        if (_total == 0) {
            // use the old rewardPerTokenStored, and accrued should be zero here
            // if not the new accrued amount will never be distributed to anyone
            _rewardPerToken = _reward_per_ntoken_stored[ntoken];
        } else {
            // 80% of accrued to NEST holders as dividend
            _rewardPerToken = _reward_per_ntoken_stored[ntoken].add(
                _accrued.mul(1e18).mul(_dividend_share).div(_total).div(100) 
            );
            // update _reward_per_ntoken_stored
            _reward_per_ntoken_stored[ntoken] = _rewardPerToken;
            lastRewardsTotal[ntoken] = rewardsTotal[ntoken];
            //uint256 _newSaving = _accrued.sub(_accrued.mul(_dividend_share).div(100)); // left 20%
            //_pending_saving_amount[ntoken] = _pending_saving_amount[ntoken].add(_newSaving);
        }

        uint256 _newEarned = _staked_balances[ntoken][account].mul(
                _rewardPerToken.sub(_reward_per_ntoken_claimed[ntoken][account])
            ).div(1e18);

        if (account != address(0)) { // Q: redundant
            rewardBalances[ntoken][account] = rewardBalances[ntoken][account].add(_newEarned);
            _reward_per_ntoken_claimed[ntoken][account] = _reward_per_ntoken_stored[ntoken];
        }
        _;
    }

    /// @notice Stake NTokens to get the dividends
    function stake(address ntoken, uint256 amount)
        external 
        override 
        nonReentrant 
        onlyOneBlock
        whenActive
        updateReward(ntoken, msg.sender) 
    {
        require(amount > 0, "Nest:Stak:!amount");
        _ntoken_staked_total[ntoken] = _ntoken_staked_total[ntoken].add(amount);
        _staked_balances[ntoken][msg.sender] = _staked_balances[ntoken][msg.sender].add(amount);
        //TransferHelper.safeTransferFrom(ntoken, msg.sender, address(this), amount);
        emit NTokenStaked(ntoken, msg.sender, amount);
        TransferHelper.safeTransferFrom(ntoken, msg.sender, address(this), amount);

    }

    /// @notice Stake NTokens to get the dividends
    function stakeFromNestPool(address ntoken, uint256 amount) 
        external 
        override 
        nonReentrant 
        onlyOneBlock
        whenActive
        updateReward(ntoken, msg.sender) 
    {
        require(amount > 0, "Nest:Stak:!amount");
        _ntoken_staked_total[ntoken] = _ntoken_staked_total[ntoken].add(amount);
        _staked_balances[ntoken][msg.sender] = _staked_balances[ntoken][msg.sender].add(amount);
        INestPool(C_NestPool).withdrawNTokenAndTransfer(msg.sender, ntoken, amount, address(this));
        emit NTokenStaked(ntoken, msg.sender, amount);
    }

    /// @notice Unstake NTokens
    function unstake(address ntoken, uint256 amount) 
        public 
        override 
        nonReentrant 
        onlyOneBlock
        whenActive
        updateReward(ntoken, msg.sender)
    {
        require(amount > 0, "Nest:Stak:!amount");
        _ntoken_staked_total[ntoken] = _ntoken_staked_total[ntoken].sub(amount);
        _staked_balances[ntoken][msg.sender] = _staked_balances[ntoken][msg.sender].sub(amount);
        //TransferHelper.safeTransfer(ntoken, msg.sender, amount);
        emit NTokenUnstaked(ntoken, msg.sender, amount);
        TransferHelper.safeTransfer(ntoken, msg.sender, amount);

    }

    /// @notice Claim rewards
    function claim(address ntoken) 
        public 
        override 
        nonReentrant 
        whenActive
        updateReward(ntoken, msg.sender) 
        returns (uint256)
    {
        uint256 _reward = rewardBalances[ntoken][msg.sender];
        if (_reward > 0) {
            rewardBalances[ntoken][msg.sender] = 0;
            // WETH balance decreased after this
            //TransferHelper.safeTransferETH(msg.sender, _reward);
            // must refresh WETH balance record after updating WETH balance
            // or lastRewardsTotal could be less than the newest WETH balance in the next update
            uint256 _newTotal = rewardsTotal[ntoken].sub(_reward);
            lastRewardsTotal[ntoken] = _newTotal;
            rewardsTotal[ntoken] = _newTotal;         
           
            emit RewardClaimed(ntoken, msg.sender, _reward);

             TransferHelper.safeTransferETH(msg.sender, _reward);
        }
        return _reward;
    }

    /* ========== INTER-CALLS ========== */

    function addETHReward(address ntoken) 
        override 
        external 
        payable 
    {
        // NOTE: no need to update reward here
        // support for sending ETH for rewards
        rewardsTotal[ntoken] = rewardsTotal[ntoken].add(msg.value); 
    }

}
