// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
//pragma experimental ABIEncoderV2;

// --------------------------------------------------------------------------------------
// GENESISVault.sol - 3/16/2021 by CryptoGamblers
// - A staking vault that accepts wbtc
// - Call Terminated to end Staking
// - At Genesis
//     - mints lfbtc = wbtc staked (generates IdeaFund wbtc/lfbtc LP)
//     - mints multiplied value of wbtc into proper values of lfbtc/lift, adds pair to liqudity token, stakes into LquidityProvider Vault on behalf of staker
// - Final step call Migrate to migrate token ownership to Treasury

// Webpage:
// Allows people to stake wbtc, shows the total staked wbtc, lfbtc value, lift value (formula), 
// calculates and shows the initial pool values
// 
// shows list of addresses with amount staked. (may require making the staker list / struct public?)

import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IOracle.sol";
import "./IBasisAsset.sol";
import "./ISimpleERCFund.sol";
import "./ILPTokenSharePool.sol";

import "./UniswapV2Library.sol";
import "./Babylonian.sol";
import "./FixedPoint.sol";

import "./Operator.sol";
import "./ContractGuard.sol";

import "./console.sol";

abstract contract TokenVault is Operator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public stakingToken; //WBTC

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    //We should only accept wbtc into the STAKE in any quanitity.
    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
    }
}

contract GenesisVault is TokenVault, ContractGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== DATA STRUCTURES ========== */
    uint public currentMultiplier = 5; // change to 2.5 after 1m total value staked in wbtc
    uint public weeklyEmissions = 20000;
    uint public variableReduction = 8;
    uint256 public totalMultipliedWBTCTokens = 0;
    address public pairTo;

    bool public migrated = false;
    bool public terminated = false;
    bool public generated = false;

    struct StakingSeat {
        //staked tokens * currentMultiplier
        uint256 multipliedNumWBTCTokens;
        bool isEntity;
    }

    /* ========== STATE VARIABLES ========== */

    address public peg; //LFBTC
    address public share; //LIFT
    address public ideaFund; //Where the LP goes
    address public lfbtcliftLPPool; // where the stakers get LP staked

    IUniswapV2Router02 public router;

    address public theOracle;

    mapping(address => StakingSeat) private stakers;
    address[] private stakersList;
    
    /* ========== CONSTRUCTOR ========== */
    // Oracle - Oracle Address
    // PEG - lfbtc
    // Share - LIFT
    // StakingToken - wBTC
    // StakingTokenPartner - any token that is paired in UniSwap with wBTC (kBTC)
    // lfbtc + LIFT liqudity pool
    // router - Uniswap Router
    // IdeaFund - Idea Fund Address
    constructor(address _theOracle, address _peg, address _share, address _stakingToken, address _lfbtcliftLPPool, address _router, address _ideaFund) {
        theOracle = _theOracle;
        peg = _peg;
        share = _share;
        stakingToken = _stakingToken;
        ideaFund = _ideaFund;
        lfbtcliftLPPool = _lfbtcliftLPPool;
        router = IUniswapV2Router02(_router);
    }

    // MODIFIERS

    modifier checkOperator {
        require(
            IBasisAsset(peg).operator() == address(this) &&
            IBasisAsset(share).operator() == address(this),
            'Genesis - BigBang: need more permission'
        );
        _;
    }

    modifier notTerminated() {
        require(
            terminated == false,
            'GenesisVault: is Terminated'
        );
        _;
    }

    modifier checkMigration {
        require(!migrated, 'GenesisVault: migrated');

        _;
    }

    modifier onlyOnce {
        require(!generated, 'Genesis has been executed before');
        _;
    }

    modifier updateStaking(address staker, uint256 amount) {
        if (staker != address(0)) {

            //gives us a list of stakers to iterate on for the genesis moment.
            if(!(stakers[staker].isEntity)) {
                stakersList.push(staker);
            }

            totalMultipliedWBTCTokens += amount.mul(currentMultiplier);
            StakingSeat memory seat = stakers[staker];
            seat.multipliedNumWBTCTokens += amount.mul(currentMultiplier);
            seat.isEntity = true;
            stakers[staker] = seat;   
        }
        _;
    }

    function terminateStaking() onlyOperator public {
        terminated = true;
    }

    function setCurrentMultplier(uint _newMultiplier) onlyOperator public {
        currentMultiplier = _newMultiplier;
    }

    function totalStakedValue() public view returns (uint256) {
        return totalSupply().mul(getStakingTokenPrice().div(1e18));
    }

    function getStakingTokenPrice() public view returns (uint256) {
        return IOracle(theOracle).wbtcPriceOne();
    }

    function getShareTokenPrice() public view returns (uint256) {
        return (totalSupply().mul(2) + totalMultipliedWBTCTokens).mul(getStakingTokenPrice()).div(weeklyEmissions).div(variableReduction).div(1e18);
    }

    // mints required peg (lfbtc) token and creates the initial staking/peg LP (wbtc/lfbtc)
    function beginGenesis() onlyOperator onlyOnce public {
        // PHASE 1 - Create the stakingToken/Peg Pair
        //in lfBTC mint = totalStakedValue
        //create LP of wbtc and lfbtc to IdeaFund

        //makes sure we arent allowing any more staking before starting genesis
        require(terminated, 'You must terminate before executing genesis');

        //to many variables "stack to deep" compile error forced some of this sloppiness 
        
        //uint256 totalStakingTokens = IERC20(stakingToken).balanceOf(address(this));
        uint256 initialStakingTokenBalance = IERC20(stakingToken).balanceOf(address(this));
        require(initialStakingTokenBalance > 0, 'No stakingToken to begin genesis');     

        //allows us to only call this function once.
        generated = true;

        IBasisAsset(peg).mint(address(this), initialStakingTokenBalance);

        //uint256 totalPegToken = IERC20(peg).balanceOf(address(this));
        require(IERC20(peg).balanceOf(address(this)) > 0, 'No pegToken minted for genesis');

        require(IERC20(peg).balanceOf(address(this)) == initialStakingTokenBalance, 'We dont have equal parts staking and peg token, wtf');
        
        uint256 liquidityTokens;

        IERC20(stakingToken).approve(address(router), initialStakingTokenBalance);
        IERC20(peg).approve(address(router), initialStakingTokenBalance);

        IUniswapV2Factory(router.factory()).createPair(stakingToken, peg);
        (,,liquidityTokens) = router.addLiquidity(stakingToken, peg, initialStakingTokenBalance, initialStakingTokenBalance, 0, 0, ideaFund, block.timestamp + 15);

        emit Staked(address(ideaFund), liquidityTokens);

        //need to validate that this returns the wbtc price
        //uint256 stakingTokenPrice = getStakingTokenPrice();

        // Take the total multipliedStakingTokens / split the value in half / mint lfbtc tokens @ numberwbtc/2, mint lift tokens @ numwbtc/2/share value
        IBasisAsset(peg).mint(address(this), totalMultipliedWBTCTokens.div(2));
        IBasisAsset(share).mint(address(this), totalMultipliedWBTCTokens.div(2).mul(getStakingTokenPrice()).div(getShareTokenPrice()));
         //= IOracle(theOracle).pairFor(router.factory(), peg, share);

        pairTo = IUniswapV2Factory(router.factory()).createPair(peg, share);

        for (uint256 i = 0; i < stakersList.length; i++) {
            StakingSeat memory seat = stakers[stakersList[i]];
            uint256 pegAmount = seat.multipliedNumWBTCTokens.div(2);
            uint256 shareAmount = seat.multipliedNumWBTCTokens.div(2).mul(getStakingTokenPrice()).div(getShareTokenPrice());
            
            IERC20(peg).approve(address(router), pegAmount);      
            IERC20(share).approve(address(router), shareAmount);

            (,,liquidityTokens) = router.addLiquidity(peg, share, pegAmount, shareAmount, 0, 0, address(this), block.timestamp + 15);

            IERC20(pairTo).approve(lfbtcliftLPPool, liquidityTokens);
            //this should be stake the LP on behalf of the original staker, locked for timerpriod in the Vault
            ILPTokenSharePool(lfbtcliftLPPool).stakeLP(address(stakersList[i]), address(this), liquidityTokens, true);

            emit Staked(address(stakersList[i]), liquidityTokens);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount)
        public
        override
        onlyOneBlock
        notTerminated
        updateStaking(msg.sender, amount)
    {
        require(amount > 0, 'GenesisVault: Cannot stake 0');
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    // RESCUE Functions -- call after Genesis to migrate token owner/operator to Treasury
    function migrate(address target) public onlyOperator checkOperator {
        require(!migrated, 'GenesisVault: migrated');

        // lfbtc
        Operator(peg).transferOperator(target);
        Operator(peg).transferOwnership(target);
        IERC20(peg).transfer(target, IERC20(peg).balanceOf(address(this)));

        // lift
        Operator(share).transferOperator(target);
        Operator(share).transferOwnership(target);
        IERC20(share).transfer(target, IERC20(share).balanceOf(address(this)));

        // wbtc
        IERC20(stakingToken).transfer(target, IERC20(stakingToken).balanceOf(address(this)));

        migrated = true;
        emit Migration(target);
    }

    // If anyone sends tokens directly to the contract we can refund them.
    function cleanUpDust(uint256 amount, address tokenAddress, address sendTo) onlyOperator public  {     
        require(tokenAddress != stakingToken, 'If you need to withdrawl wbtc use the DAO to migrate to a new contract');

        IERC20(tokenAddress).safeTransfer(sendTo, amount);
    }

    function updateOracle(address newOracle) public onlyOperator {
        theOracle = newOracle;
    }

    function updateStakingToken(address newToken) public onlyOperator {
        stakingToken = newToken;
    }

    function setIdeaFund(address newFund) public onlyOperator {
        ideaFund = newFund;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Migration(address target);
}