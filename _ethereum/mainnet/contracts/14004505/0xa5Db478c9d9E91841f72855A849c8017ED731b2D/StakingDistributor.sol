// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ITreasury.sol";
import "./SafeMathExtended.sol";

contract StakingDistributor is Ownable {
    
    using SafeERC20 for IERC20;
    using SafeMathExtended for uint256;
    using SafeMathExtended for uint32;
    
    IERC20 immutable KEEPER;
    ITreasury immutable treasury;
    
    uint32 public immutable epochLength;
    uint32 public nextEpochTime;
    
    mapping( uint => Adjust ) public adjustments;

    /* ====== STRUCTS ====== */
        
    struct Info {
        uint rate; // in ten-thousandths ( 5000 = 0.5% )
        address recipient;
    }
    Info[] public info;
    
    struct Adjust {
        bool add;
        uint rate;
        uint target;
    }

    constructor( address _treasury, address _KEEPER, uint32 _epochLength, uint32 _nextEpochTime ) {        
        require( _treasury != address(0) );
        treasury = ITreasury( _treasury );
        require( _KEEPER != address(0) );
        KEEPER = IERC20( _KEEPER );
        epochLength = _epochLength;
        nextEpochTime = _nextEpochTime;
    }

    /**
        @notice send epoch reward to staking contract
     */
    function distribute() external returns (bool) {
        if ( nextEpochTime <= uint32(block.timestamp) ) {
            nextEpochTime = nextEpochTime.add32( epochLength ); // set next epoch block
            // distribute rewards to each recipient
            for ( uint i = 0; i < info.length; i++ ) {
                if ( info[ i ].rate > 0 ) {
                    treasury.mintRewards( // mint and send from treasury
                        info[ i ].recipient, 
                        nextRewardAt( info[ i ].rate ) 
                    );
                    adjust( i ); // check for adjustment
                }
            }
            return true;
        }
        else {
            return false;
        }
    }

    /**
        @notice increment reward rate for collector
     */
    function adjust( uint _index ) internal {
        Adjust memory adjustment = adjustments[ _index ];
        if ( adjustment.rate != 0 ) {
            if ( adjustment.add ) { // if rate should increase
                info[ _index ].rate = info[ _index ].rate.add( adjustment.rate ); // raise rate
                if ( info[ _index ].rate >= adjustment.target ) { // if target met
                    adjustments[ _index ].rate = 0; // turn off adjustment
                }
            } else { // if rate should decrease
                info[ _index ].rate = info[ _index ].rate.sub( adjustment.rate ); // lower rate
                if ( info[ _index ].rate <= adjustment.target || info[ _index ].rate < adjustment.rate) { // if target met
                    adjustments[ _index ].rate = 0; // turn off adjustment
                }
            }
        }
    }

    /* ====== VIEW FUNCTIONS ====== */

    /**
        @notice view function for next reward at given rate
        @param _rate uint
        @return uint
     */
    function nextRewardAt( uint _rate ) public view returns ( uint ) {
        return KEEPER.totalSupply().mul( _rate ).div( 1000000 );
    }

    /**
        @notice view function for next reward for specified address
        @param _recipient address
        @return uint
     */
    function nextRewardFor( address _recipient ) public view returns ( uint ) {
        uint reward;
        for ( uint i = 0; i < info.length; i++ ) {
            if ( info[ i ].recipient == _recipient ) {
                reward = nextRewardAt( info[ i ].rate );
            }
        }
        return reward;
    }
    
    
    
    /* ====== POLICY FUNCTIONS ====== */

    /**
        @notice adds recipient for distributions
        @param _recipient address
        @param _rewardRate uint
     */
    function addRecipient( address _recipient, uint _rewardRate ) external onlyOwner() {
        require( _recipient != address(0) );
        info.push( Info({
            recipient: _recipient,
            rate: _rewardRate
        }));
    }

    /**
        @notice removes recipient for distributions
        @param _index uint
        @param _recipient address
     */
    function removeRecipient( uint _index, address _recipient ) external onlyOwner() {
        require( _recipient == info[ _index ].recipient );
        info[ _index ] = info[info.length-1];
        info.pop();
    }

    /**
        @notice set adjustment info for a collector's reward rate
        @param _index uint
        @param _add bool
        @param _rate uint
        @param _target uint
     */
    function setAdjustment( uint _index, bool _add, uint _rate, uint _target ) external onlyOwner() {
        require(_add || info[ _index ].rate >= _rate, "Negative adjustment rate cannot be more than current rate.");
        adjustments[ _index ] = Adjust({
            add: _add,
            rate: _rate,
            target: _target
        });
    }
}