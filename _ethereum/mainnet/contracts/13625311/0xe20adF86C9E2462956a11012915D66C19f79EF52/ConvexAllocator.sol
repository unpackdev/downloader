// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IConvex.sol";
import "./IConvexRewards.sol";
import "./ICurveStethPool.sol";
import "./ITreasury.sol";
import "./IWeth.sol";

/**
 *  Contract deploys reserves from treasury into the Convex lending pool,
 *  earning interest and $CVX.
 */

contract ConvexAllocator is Ownable {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    /* ======== STRUCTS ======== */

    struct tokenData {
        address underlying;
        address curveToken;
        int128 index;
        uint deployed;
        uint limit;
        uint newLimit;
        uint limitChangeTimelockEnd;
    }

    /* ======== STATE VARIABLES ======== */

    IConvex public immutable booster; // Convex deposit contract
    IConvexRewards public immutable rewardPool; // Convex reward contract
    ITreasury public immutable treasury; // Squid Treasury
    ICurveStethPool public immutable curveStethPool; // Curve stEth pool
    IWeth public immutable weth; // Weth contract

    mapping( address => tokenData ) public tokenInfo; // info for deposited tokens
    mapping( address => uint ) public pidForReserve; // convex pid for token

    uint public totalValueDeployed; // total RFV deployed into lending pool

    uint public immutable timelockInBlocks; // timelock to raise deployment limit

    address[] rewardTokens;

    /* ======== CONSTRUCTOR ======== */

    constructor (
        address _treasury,
        address _booster,
        address _rewardPool,
        address _curveStethPool,
        address _weth,
        uint _timelockInBlocks
    ) {
        require( _treasury != address(0) );
        treasury = ITreasury( _treasury );

        require( _booster != address(0) );
        booster = IConvex( _booster );

        require( _rewardPool != address(0) );
        rewardPool = IConvexRewards( _rewardPool );

        require( _curveStethPool != address(0) );
        curveStethPool = ICurveStethPool( _curveStethPool );

        require( _weth != address(0) );
        weth = IWeth( _weth );

        timelockInBlocks = _timelockInBlocks;
    }

    /* ======== OPEN FUNCTIONS ======== */

    /**
     *  @notice claims accrued CVX rewards for all tracked crvTokens
     */
    function harvest() public {
        rewardPool.getReward();

        for( uint i = 0; i < rewardTokens.length; i++ ) {
            uint balance = IERC20( rewardTokens[i] ).balanceOf( address(this) );

            if ( balance > 0 ) {
                IERC20( rewardTokens[i] ).safeTransfer( address(treasury), balance );
            }
        }
    }

    /* ======== POLICY FUNCTIONS ======== */

    /**
     *  @notice withdraws asset from treasury, deposits asset into lending pool, then deposits crvToken into convex
     *  @param token address
     *  @param amount uint
     *  @param minAmount uint
     */
    function deposit( address token, uint amount, uint minAmount ) public onlyOwner() {
        require( !exceedsLimit( token, amount ) ); // ensure deposit is within bounds

        address curveToken = tokenInfo[ token ].curveToken;

        treasury.manage( token, amount ); // retrieve amount of asset from treasury

        // account for deposit
        uint value = treasury.valueOf( token, amount );
        accountingFor( token, amount, value, true );

        weth.withdraw(amount); // unwrap weth to eth
        uint[2] memory amounts = [amount, 0]; // ETH: amount, stETH: 0
        uint curveAmount = curveStethPool.add_liquidity{value: amount}(amounts, minAmount); // deposit into curve

        IERC20( curveToken ).approve( address(booster), curveAmount ); // approve to deposit to convex
        booster.deposit( pidForReserve[ token ], curveAmount, true ); // deposit into convex
    }

    /**
     *  @notice withdraws crvToken from convex, withdraws from lending pool, then deposits asset into treasury
     *  @param token address
     *  @param amount uint
     *  @param minAmount uint
     */
    function withdraw( address token, uint amount, uint minAmount ) public onlyOwner() {
        rewardPool.withdrawAndUnwrap( amount, false ); // withdraw to curve token

        address curveToken = tokenInfo[ token ].curveToken;

        IERC20(curveToken).approve(address(curveStethPool), amount); // approve the pool to spend curveToken
        curveStethPool.remove_liquidity_one_coin(amount, tokenInfo[ token ].index, minAmount); // withdraw from curve

        uint balance = address(this).balance;
        weth.deposit{value: balance}(); // wrap eth to weth

        // account for withdrawal
        uint value = treasury.valueOf( token, balance );
        accountingFor( token, balance, value, false );

        IERC20( token ).approve( address( treasury ), balance ); // approve to deposit asset into treasury
        treasury.deposit( balance, token, value ); // deposit using value as profit so no OHM is minted
    }

    /**
     *  @notice adds asset and corresponding crvToken to mapping
     *  @param token address
     *  @param curveToken address
     */
    function addToken( address token, address curveToken, int128 index, uint max, uint pid ) external onlyOwner() {
        require( token != address(0) );
        require( curveToken != address(0) );
        require( tokenInfo[ token ].deployed == 0 );

        tokenInfo[ token ] = tokenData({
            underlying: token,
            curveToken: curveToken,
            index: index,
            deployed: 0,
            limit: max,
            newLimit: 0,
            limitChangeTimelockEnd: 0
        });

        pidForReserve[ token ] = pid;
    }

    /**
     *  @notice add new reward token to be harvested
     *  @param token address
     */
    function addRewardToken( address token ) external onlyOwner() {
        rewardTokens.push( token );
    }

    /**
     *  @notice lowers max can be deployed for asset (no timelock)
     *  @param token address
     *  @param newMax uint
     */
    function lowerLimit( address token, uint newMax ) external onlyOwner() {
        require( newMax < tokenInfo[ token ].limit );
        require( newMax > tokenInfo[ token ].deployed ); // cannot set limit below what has been deployed already
        tokenInfo[ token ].limit = newMax;
    }

    /**
     *  @notice starts timelock to raise max allocation for asset
     *  @param token address
     *  @param newMax uint
     */
    function queueRaiseLimit( address token, uint newMax ) external onlyOwner() {
        tokenInfo[ token ].limitChangeTimelockEnd = block.number.add( timelockInBlocks );
        tokenInfo[ token ].newLimit = newMax;
    }

    /**
     *  @notice changes max allocation for asset when timelock elapsed
     *  @param token address
     */
    function raiseLimit( address token ) external onlyOwner() {
        require( block.number >= tokenInfo[ token ].limitChangeTimelockEnd, "Timelock not expired" );
        require( tokenInfo[ token ].limitChangeTimelockEnd != 0, "Timelock not started" );

        tokenInfo[ token ].limit = tokenInfo[ token ].newLimit;
        tokenInfo[ token ].newLimit = 0;
        tokenInfo[ token ].limitChangeTimelockEnd = 0;
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    /**
     *  @notice accounting of deposits/withdrawals of assets
     *  @param token address
     *  @param amount uint
     *  @param value uint
     *  @param add bool
     */
    function accountingFor( address token, uint amount, uint value, bool add ) internal {
        if( add ) {
            tokenInfo[ token ].deployed = tokenInfo[ token ].deployed.add( amount ); // track amount allocated into pool

            totalValueDeployed = totalValueDeployed.add( value ); // track total value allocated into pools

        } else {
            // track amount allocated into pool
            if ( amount < tokenInfo[ token ].deployed ) {
                tokenInfo[ token ].deployed = tokenInfo[ token ].deployed.sub( amount );
            } else {
                tokenInfo[ token ].deployed = 0;
            }

            // track total value allocated into pools
            if ( value < totalValueDeployed ) {
                totalValueDeployed = totalValueDeployed.sub( value );
            } else {
                totalValueDeployed = 0;
            }
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice query all pending rewards
     *  @return uint
     */
    function rewardsPending() public view returns ( uint ) {
        return rewardPool.earned( address(this) );
    }

    /**
     *  @notice checks to ensure deposit does not exceed max allocation for asset
     *  @param token address
     *  @param amount uint
     */
    function exceedsLimit( address token, uint amount ) public view returns ( bool ) {
        uint willBeDeployed = tokenInfo[ token ].deployed.add( amount );

        return ( willBeDeployed > tokenInfo[ token ].limit );
    }

    receive() external payable {}
}
