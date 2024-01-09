// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ITreasury.sol";


contract Staking is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    event Stake( address indexed recipient, uint indexed amount, uint indexed timestamp );
    event Unstake( address indexed recipient, uint indexed amount, uint indexed timestamp );

    uint public constant keeperDecimals = 9;
    IERC20 public immutable KEEPER;
    address public immutable treasury;
    uint public rate;   // 6 decimals. 10000 = 0.01 = 1%
    uint public INDEX;  // keeperDecimals decimals
    uint public keeperRewards;

    struct Rebase {
        uint rebaseRate; // 6 decimals
        uint totalStaked;
        uint index;
        uint timeOccured;
    }

    struct Epoch {
        uint number;
        uint rebaseInterval;
        uint nextRebase;
    }
    Epoch public epoch;

    Rebase[] public rebases; // past rebase data    

    mapping(address => uint) public stakers;


    constructor( address _KEEPER, address _treasury, uint _rate, uint _INDEX, uint _rebaseInterval ) {
        require( _KEEPER != address(0) );
        KEEPER = IERC20(_KEEPER);
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _rate != 0 );
        rate = _rate;
        require( _INDEX != 0 );
        INDEX = _INDEX;
        require( _rebaseInterval != 0 );

        epoch = Epoch({
            number: 1,
            rebaseInterval: _rebaseInterval,
            nextRebase: block.timestamp.add(_rebaseInterval)
        });
    }


    function setRate( uint _rate ) external onlyOwner() {
        require( _rate >= rate.div(2) && _rate <= rate.mul(3).div(2), "Rate change cannot be too sharp." );
        rate = _rate;
    }


    function stake( uint _amount, address _recipient, bool _wrap ) external {
        KEEPER.safeTransferFrom( msg.sender, address(this), _amount );
        uint _gonsAmount = getGonsAmount( _amount );
        stakers[ _recipient ] = stakers[ _recipient ].add( _gonsAmount );
        emit Stake( _recipient, _amount, block.timestamp );
        rebase();
    }


    function unstake( uint _amount ) external {
        rebase();
        require( _amount <= stakerAmount(msg.sender), "Cannot unstake more than possible." );
        if ( _amount > KEEPER.balanceOf( address(this) ) ) {
            ITreasury(treasury).unstakeMint( _amount.sub(KEEPER.balanceOf( address(this) ) ) );
        }
        uint gonsAmount = getGonsAmount( _amount );
        // Handle math precision error
        if ( gonsAmount > stakers[msg.sender] ) {
            gonsAmount = stakers[msg.sender];
        }
        stakers[msg.sender] = stakers[ msg.sender ].sub(gonsAmount);
        KEEPER.safeTransfer( msg.sender, _amount );
        emit Unstake( msg.sender, _amount, block.timestamp );
    }


    function rebase() public {
        if (epoch.nextRebase <= block.timestamp) {
            uint rebasingRate = rebaseRate();
            INDEX = INDEX.add( INDEX.mul( rebasingRate ).div(1e6) );
            epoch.nextRebase = epoch.nextRebase.add(epoch.rebaseInterval);
            epoch.number++;
            keeperRewards = 0;
            rebases.push( Rebase({
                rebaseRate: rebasingRate,
                totalStaked: KEEPER.balanceOf( address(this) ),
                index: INDEX,
                timeOccured: block.timestamp
            }) );
        }
    }


    function stakerAmount( address _recipient ) public view returns (uint) {
        return getKeeperAmount(stakers[ _recipient ]);
    }


    function rebaseRate() public view returns (uint) {
        uint keeperBalance = KEEPER.balanceOf( address(this) );
        if (keeperBalance == 0) {
            return rate;
        } else {
            return rate.add( keeperRewards.mul(1e6).div( KEEPER.balanceOf( address(this) ) ) );
        }
    }


    function addRebaseReward( uint _amount ) external {
        KEEPER.safeTransferFrom( msg.sender, address(this), _amount );
        keeperRewards = keeperRewards.add( _amount );
    }


    function getGonsAmount( uint _amount ) internal view returns (uint) {
        return _amount.mul(10 ** keeperDecimals).div(INDEX);
    }


    function getKeeperAmount( uint _gons ) internal view returns (uint) {
        return _gons.mul(INDEX).div(10 ** keeperDecimals);
    }

}