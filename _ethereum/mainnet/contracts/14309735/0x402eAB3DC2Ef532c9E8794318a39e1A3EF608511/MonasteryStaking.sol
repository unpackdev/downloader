// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";


interface IZEN {
    function rebase( uint256 monkProfit_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function gonsForBalance( uint amount ) external view returns ( uint );

    function balanceForGons( uint gons ) external view returns ( uint );

    function index() external view returns ( uint );

    function boost(address who) external;

    function unboost(address who) external;
}

interface IWarmup {
    function retrieve( address staker_, uint amount_ ) external;
}

interface IDistributor {
    function distribute() external returns ( bool );
}

contract MonasteryStaking is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable MONK;
    address public immutable ZEN;
    address public NFT;

    struct Epoch {
        uint length; // in seconds
        uint number;
        uint endTime; // unix epoch time in seconds
        uint distribute;
    }
    Epoch public epoch;

    address public distributor;

    address public locker;
    uint public totalBonus;

    address public warmupContract;
    uint public warmupPeriod;

    constructor (
        address _MONK,
        address _ZEN,
        uint _epochLength,
        uint _firstEpochNumber,
        uint _firstEpochTime
    ) {
        require( _MONK != address(0) );
        MONK = _MONK;
        require( _ZEN != address(0) );
        ZEN = _ZEN;

        epoch = Epoch({
            length: _epochLength,
            number: _firstEpochNumber,
            endTime: _firstEpochTime,
            distribute: 0
        });
    }

    struct Claim {
        uint deposit;
        uint gons;
        uint expiry;
        bool lock; // prevents malicious delays
    }
    mapping( address => Claim ) public warmupInfo;
    mapping( address => uint256 ) public NFTOf;

    function setNFT(address _NFT) public onlyOwner() {
        require(_NFT != address(0));
        NFT = _NFT;
    }

    function stake( uint _amount, address _recipient ) external returns ( bool ) {
        rebase();

        IERC20( MONK ).safeTransferFrom( msg.sender, address(this), _amount );

        Claim memory info = warmupInfo[ _recipient ];
        require( !info.lock, "Deposits for account are locked" );

        warmupInfo[ _recipient ] = Claim ({
            deposit: info.deposit.add( _amount ),
            gons: info.gons.add( IZEN( ZEN ).gonsForBalance( _amount ) ),
            expiry: epoch.number.add( warmupPeriod ),
            lock: false
        });

        IERC20( ZEN ).safeTransfer( warmupContract, _amount );
        return true;
    }

    function boost( uint256 tokenId ) external returns ( bool ) {
        rebase();

        IERC721(NFT).transferFrom(msg.sender, address(this), tokenId);
        NFTOf[msg.sender] = tokenId;
        IZEN( ZEN ).boost(msg.sender);

        return true;
    }

    function unboost() external returns ( bool ) {
        rebase();

        IZEN( ZEN ).unboost(msg.sender);
        uint256 tokenId = NFTOf[msg.sender];
        NFTOf[msg.sender] = 0;
        IERC721(NFT).transferFrom(address(this), msg.sender, tokenId);

        return true;
    }

    /**
        @notice retrieve ZEN from warmup
        @param _recipient address
     */
    function claim ( address _recipient ) public {
        Claim memory info = warmupInfo[ _recipient ];
        if ( epoch.number >= info.expiry && info.expiry != 0 ) {
            delete warmupInfo[ _recipient ];
            IWarmup( warmupContract ).retrieve( _recipient, IZEN( ZEN ).balanceForGons( info.gons ) );
        }
    }

    /**
        @notice forfeit ZEN in warmup and retrieve MONK
     */
    function forfeit() external {
        Claim memory info = warmupInfo[ msg.sender ];
        delete warmupInfo[ msg.sender ];

        IWarmup( warmupContract ).retrieve( address(this), IZEN( ZEN ).balanceForGons( info.gons ) );
        IERC20( MONK ).safeTransfer( msg.sender, info.deposit );
    }

    /**
        @notice prevent new deposits to address (protection from malicious activity)
     */
    function toggleDepositLock() external {
        warmupInfo[ msg.sender ].lock = !warmupInfo[ msg.sender ].lock;
    }

    /**
        @notice redeem ZEN for MONK
        @param _amount uint
        @param _trigger bool
     */
    function unstake( uint _amount, bool _trigger ) external {
        if ( _trigger ) {
            rebase();
        }
        IERC20( ZEN ).safeTransferFrom( msg.sender, address(this), _amount );
        IERC20( MONK ).safeTransfer( msg.sender, _amount );
    }

    /**
        @notice returns the ZEN index, which tracks rebase growth
        @return uint
     */
    function index() public view returns ( uint ) {
        return IZEN( ZEN ).index();
    }

    /**
        @notice trigger rebase if epoch over
     */
    function rebase() public {
        if( epoch.endTime <= block.timestamp ) {
            IZEN( ZEN ).rebase( epoch.distribute, epoch.number );

            epoch.endTime = epoch.endTime.add( epoch.length );
            epoch.number++;

            if ( distributor != address(0) ) {
                IDistributor( distributor ).distribute();
            }

            uint balance = contractBalance();
            uint staked = IZEN( ZEN ).circulatingSupply();

            if( balance <= staked ) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance.sub( staked );
            }
        }
    }

    /**
        @notice returns contract MONK holdings, including bonuses provided
        @return uint
     */
    function contractBalance() public view returns ( uint ) {
        return IERC20( MONK ).balanceOf( address(this) ).add( totalBonus );
    }

    /**
        @notice provide bonus to locked staking contract
        @param _amount uint
     */
    function giveLockBonus( uint _amount ) external {
        require( msg.sender == locker );
        totalBonus = totalBonus.add( _amount );
        IERC20( ZEN ).safeTransfer( locker, _amount );
    }

    /**
        @notice reclaim bonus from locked staking contract
        @param _amount uint
     */
    function returnLockBonus( uint _amount ) external {
        require( msg.sender == locker );
        totalBonus = totalBonus.sub( _amount );
        IERC20( ZEN ).safeTransferFrom( locker, address(this), _amount );
    }

    enum CONTRACTS { DISTRIBUTOR, WARMUP, LOCKER }

    /**
        @notice sets the contract address for LP staking
        @param _contract address
     */
    function setContract( CONTRACTS _contract, address _address ) external onlyOwner() {
        if( _contract == CONTRACTS.DISTRIBUTOR ) { // 0
            distributor = _address;
        } else if ( _contract == CONTRACTS.WARMUP ) { // 1
            require( warmupContract == address( 0 ), "Warmup cannot be set more than once" );
            warmupContract = _address;
        } else if ( _contract == CONTRACTS.LOCKER ) { // 2
            require( locker == address(0), "Locker cannot be set more than once" );
            locker = _address;
        }
    }

    /**
     * @notice set warmup period for new stakers
     * @param _warmupPeriod uint
     */
    function setWarmup( uint _warmupPeriod ) external onlyOwner() {
        warmupPeriod = _warmupPeriod;
    }
}
