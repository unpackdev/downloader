// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

//Contract deployed by LK Tech Club Incubator 2021 dba Lift.Kitchen - 4/24/2021

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

//import "./console.sol";

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
    function stake(uint256 amount, uint term) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount);
    }
}

contract GenesisVault is TokenVault, ContractGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== DATA STRUCTURES ========== */
    //uint public currentMultiplier = 5; // change to 2 after 1m total value staked in wbtc
    uint public weeklyEmissions = 10000;
    uint public variableReduction = 10;
    uint256 public totalMultipliedWBTCTokens = 0;
    address public pairTo;

    bool public migrated = false;
    bool public terminated = false;
    bool public generated = false;

    /* ========== STATE VARIABLES ========== */

    address public peg; //LFBTC
    address public share; //LIFT
    address public ideaFund; //Where the LP goes
    address public lfbtcliftLPPool; // where the stakers get LP staked
    uint256 public starttime;

    IUniswapV2Router02 public router;

    address public theOracle;

    struct StakingSeat {
        //staked tokens * currentMultiplier
        uint256 multipliedNumWBTCTokens2x;
        uint256 multipliedNumWBTCTokens3x;
        uint256 multipliedNumWBTCTokens4x;
        uint256 multipliedNumWBTCTokens5x;
        bool isEntity;
    }

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
    constructor(address _theOracle, 
                address _peg, 
                address _share, 
                address _stakingToken, 
                address _lfbtcliftLPPool, 
                address _router, 
                address _ideaFund, 
                uint256 _startTime) 
    {
        theOracle = _theOracle;
        peg = _peg;
        share = _share;
        stakingToken = _stakingToken;
        ideaFund = _ideaFund;
        lfbtcliftLPPool = _lfbtcliftLPPool;
        router = IUniswapV2Router02(_router);
        starttime = _startTime;
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

    modifier started() {
        require(block.timestamp > starttime, 'GenesisVault: is Not Started');
        _;
    }

    // term 1 = 2x, 30 days || 2 = 3x, 60 days || 3 = 4x, 90 days || 4 = 5x, 120 days
    modifier updateStaking(address staker, uint256 amount, uint term) {
            //gives us a list of stakers to iterate on for the genesis moment.
            require(term == 1 || term == 2 || term == 3 || term == 4, 'GenesisVault: requires term 1-4');

            if(!(stakers[staker].isEntity)) {
                stakersList.push(staker);
            }
    
            StakingSeat memory seat = stakers[staker];

            if (term == 1) {
                seat.multipliedNumWBTCTokens2x += amount.mul(2);
                totalMultipliedWBTCTokens += amount.mul(2);
            } else if (term == 2) {
                seat.multipliedNumWBTCTokens3x += amount.mul(3);
                totalMultipliedWBTCTokens += amount.mul(3);
            } else if (term == 3) {
                seat.multipliedNumWBTCTokens4x += amount.mul(4);
                totalMultipliedWBTCTokens += amount.mul(4);
            } else if (term == 4) {
                seat.multipliedNumWBTCTokens5x += amount.mul(5);
                totalMultipliedWBTCTokens += amount.mul(5);
            }
            
            seat.isEntity = true;
            stakers[staker] = seat;   
        _;
    }

    // function terminateStaking() onlyOperator public {
    //     terminated = true;
    // }

    // function setCurrentMultplier(uint _newMultiplier) onlyOperator public {
    //     currentMultiplier = _newMultiplier;
    // }

    function totalStakedValue() public view returns (uint256) {
        return totalSupply().mul(1e10).mul(getStakingTokenPrice()).div(1e18);
    }

    function getStakingTokenPrice() public view returns (uint256) {
        return IOracle(theOracle).wbtcPriceOne();
    }

    //returns share price as an 18 decimel number
    function getShareTokenPrice() public view returns (uint256) {
        return (totalSupply().mul(2) + totalMultipliedWBTCTokens).mul(1e10).mul(getStakingTokenPrice()).div(weeklyEmissions).div(variableReduction).div(1e18);
    }

    function mintPegToken() onlyOperator public {
        require(IERC20(stakingToken).balanceOf(address(this)) > 0, 'No stakingToken to begin genesis');     

        IBasisAsset(peg).mint(address(this), IERC20(stakingToken).balanceOf(address(this)).mul(1e10).add(totalMultipliedWBTCTokens.mul(1e10).div(2)));
    }

    function addliquidityForStakingPeg() onlyOperator public {
        IERC20(stakingToken).approve(address(router), IERC20(stakingToken).balanceOf(address(this)));
        IERC20(peg).approve(address(router), IERC20(stakingToken).balanceOf(address(this)).mul(1e10).add(totalMultipliedWBTCTokens.mul(1e10).div(2)));

        router.addLiquidity(stakingToken, peg, IERC20(stakingToken).balanceOf(address(this)).div(2), IERC20(stakingToken).balanceOf(address(this)).mul(1e10).div(2), 0, 0, ideaFund, block.timestamp + 15);

        IERC20(peg).transfer(ideaFund, IERC20(stakingToken).balanceOf(address(this)).mul(1e10));
        IERC20(stakingToken).transfer(ideaFund, IERC20(stakingToken).balanceOf(address(this)));  
    }

    function mintShareToken() onlyOperator public {
        IBasisAsset(share).mint(address(this), totalMultipliedWBTCTokens.mul(1e10).div(2).mul(getStakingTokenPrice()).div(getShareTokenPrice()));
    }

    function addliquidityForPegShare() onlyOperator public {
        uint256 liquidityTokens = 0;
        
        IERC20(peg).approve(address(router), totalMultipliedWBTCTokens.mul(1e10).div(2));      
        IERC20(share).approve(address(router), totalMultipliedWBTCTokens.mul(1e10).div(2).mul(getStakingTokenPrice()).div(getShareTokenPrice()));

        pairTo = IUniswapV2Factory(router.factory()).createPair(peg, share);
        (,,liquidityTokens) = router.addLiquidity(peg, share, totalMultipliedWBTCTokens.mul(1e10).div(2), totalMultipliedWBTCTokens.mul(1e10).div(2).mul(getStakingTokenPrice()).div(getShareTokenPrice()), 0, 0, address(this), block.timestamp + 15);    

        IERC20(pairTo).approve(lfbtcliftLPPool, liquidityTokens);    

        for (uint256 i = 0; i < stakersList.length; i++) {
            StakingSeat memory seat = stakers[stakersList[i]];
            
            uint256 pegPercentageAmount = ((seat.multipliedNumWBTCTokens2x.mul(1e10).mul(1e18)).div(totalMultipliedWBTCTokens.mul(1e10)));
            if (pegPercentageAmount > 0) {
                //this should be stake the LP on behalf of the original staker, locked for timerpriod in the Vault
                ILPTokenSharePool(lfbtcliftLPPool).stakeLP(address(stakersList[i]), address(this), liquidityTokens.mul(pegPercentageAmount).div(1e18), 1);
            }

            pegPercentageAmount = ((seat.multipliedNumWBTCTokens3x.mul(1e10).mul(1e18)).div(totalMultipliedWBTCTokens.mul(1e10)));
            if (pegPercentageAmount > 0) {
                //this should be stake the LP on behalf of the original staker, locked for timerpriod in the Vault
                ILPTokenSharePool(lfbtcliftLPPool).stakeLP(address(stakersList[i]), address(this), liquidityTokens.mul(pegPercentageAmount).div(1e18), 2);
            }

            pegPercentageAmount = ((seat.multipliedNumWBTCTokens4x.mul(1e10).mul(1e18)).div(totalMultipliedWBTCTokens.mul(1e10)));
            if (pegPercentageAmount > 0) {
                //this should be stake the LP on behalf of the original staker, locked for timerpriod in the Vault
                ILPTokenSharePool(lfbtcliftLPPool).stakeLP(address(stakersList[i]), address(this), liquidityTokens.mul(pegPercentageAmount).div(1e18), 3);
            }

            pegPercentageAmount = ((seat.multipliedNumWBTCTokens5x.mul(1e10).mul(1e18)).div(totalMultipliedWBTCTokens.mul(1e10)));
            if (pegPercentageAmount > 0) {
                //this should be stake the LP on behalf of the original staker, locked for timerpriod in the Vault
                ILPTokenSharePool(lfbtcliftLPPool).stakeLP(address(stakersList[i]), address(this), liquidityTokens.mul(pegPercentageAmount).div(1e18), 4);
            }            
        }
    }

    // mints required peg (lfbtc) token and creates the initial staking/peg LP (wbtc/lfbtc)
    function beginGenesis() onlyOperator public {
        mintPegToken();
      
        addliquidityForStakingPeg();

        mintShareToken();
       
        addliquidityForPegShare();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount, uint term)
        public
        override
        onlyOneBlock
        started
        updateStaking(msg.sender, amount, term)
    {
        require(amount > 0, 'GenesisVault: Cannot stake 0');
        super.stake(amount, term);
        emit Staked(msg.sender, amount);
    }

    // RESCUE Functions -- call after Genesis to migrate token owner/operator to Treasury
    function migrate(address target) public onlyOperator {
        require(!migrated, 'GenesisVault: migrated');

        // lfbtc
        Operator(peg).transferOperator(target);
        Operator(peg).transferOwnership(target);
        if (IERC20(peg).balanceOf(address(this)) > 0)
            IERC20(peg).transfer(target, IERC20(peg).balanceOf(address(this)));

        // lift
        Operator(share).transferOperator(target);
        Operator(share).transferOwnership(target);
        if (IERC20(share).balanceOf(address(this)) > 0)
            IERC20(share).transfer(target, IERC20(share).balanceOf(address(this)));

        // wbtc
        if (IERC20(stakingToken).balanceOf(address(this)) > 0)
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