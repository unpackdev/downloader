// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Pausable.sol";

import "./SafeDecimalMath.sol";
import "./EthReward.sol";
import "./IPriceFeed.sol";
import "./IEthVault.sol";
import "./AddressBook.sol";
import "./AddressBookLib.sol";



contract InterestManager is VaultAccess, IInterestManager {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    enum ACT {
        MINT,
        BURN,
        OTHER
    }

    uint256 public mLastBlock;  
    uint256 public mAccInterestPerShare; // highPrecisionDecimals
    uint256 public mInterestPerBlock; // highPrecisionDecimals
    uint256 public constant BLOCKS_A_YEAR = 2102400;

    struct Interest {
        uint256 amount;
        uint256 startShare;
        uint256 totalInterest;
    }

    mapping(uint256 => Interest ) public mInterests;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "only admin");
        _;
    }

    constructor( uint256 interestPerBlock, uint256 startBlock ) public 
    {
        mLastBlock = startBlock;
        mAccInterestPerShare = 0;
        mInterestPerBlock = interestPerBlock;
        _setupRole(ADMIN_ROLE, _msgSender());
    }


    function setInterestRate( uint256 interestPerBlock ) public override onlyAdmin
    {
        _update( block.number );
        mInterestPerBlock = interestPerBlock;
        emit LogSetInterestRate( block.number, interestPerBlock );
    }


    function getInterestRate( ) external override view returns (uint256 interestPerBlock ){
        interestPerBlock = mInterestPerBlock;
    }

    function setAnnualizedRate( uint256 interestPerYear ) public override onlyAdmin
    {
        _update( block.number );
        // 60 * 24 * 365 * 4 // per 15 sec a block
        mInterestPerBlock = interestPerYear.div( BLOCKS_A_YEAR );
        emit LogSetInterestRate( block.number, mInterestPerBlock );
    } 


    function _update( uint256 curBlock ) internal {
        if (curBlock <= mLastBlock) {
            return;
        }
        uint256 multiplier = curBlock.sub( mLastBlock, "_update curBlock sub overflow" );
        uint256 interest = multiplier.mul(mInterestPerBlock);
        
        mAccInterestPerShare = mAccInterestPerShare.add( interest );
        mLastBlock = curBlock;
    }


    function _updateInterest( uint256 curBlock, uint key, uint256 amount, ACT act  ) internal {
        _update( curBlock );
        
        Interest storage interest =  mInterests[key];
        if( interest.startShare > 0 ){
            interest.totalInterest = interest.totalInterest.add( 
                interest.amount.multiplyDecimalRoundPrecise( mAccInterestPerShare.sub( interest.startShare,"interest share")) );
        }
        if( act == ACT.MINT ){
            interest.amount = interest.amount.add( amount );
        }
        else if( act == ACT.BURN ){
            interest.amount = interest.amount.sub( amount,"update interest amount" );
        }
        interest.startShare = mAccInterestPerShare;
    }


    function mint( uint256 curBlock, uint key, uint256 amount, address  addr ) external override onlyVault {
        _updateInterest( curBlock, key, amount, ACT.MINT );
        emit LogMint( curBlock, key, amount, addr );
    }

    function burn( uint256 curBlock, uint key, uint256 amount, address addr ) external override onlyVault {
        _updateInterest( curBlock, key, amount, ACT.BURN );
        emit LogBurn( curBlock, key, amount, addr );
    }

    function payInterest( uint256 curBlock, uint key, uint256 interest  ) external override onlyVault {
        _updateInterest( curBlock, key, 0, ACT.OTHER );
        Interest storage data =  mInterests[key];
        data.totalInterest = data.totalInterest.sub( interest," pay interest" );
        emit LogPayInterest( curBlock, key, interest );
    }

    function getInterest( uint256 curBlock, uint key ) external override view returns( uint256 interest ) {
        Interest memory data =  mInterests[key];
        uint256 multiplier = curBlock.sub( mLastBlock, "getInterest curBlock sub overflow" );
        uint accInterest = mAccInterestPerShare.add( multiplier.mul(mInterestPerBlock) );
        if( data.startShare > 0 ){
            interest = data.totalInterest.add( 
                data.amount.multiplyDecimalRoundPrecise( accInterest.sub( data.startShare,"interest share")) );
        }
    }

    event LogSetInterestRate(
        uint256 blockNb,
        uint256 rate
    );

    event LogMint(
        uint256 curBlock,
        uint256 key,
        uint256 amount,
        address addr
    );

    event LogBurn(
        uint256 curBlock,
        uint256 key,
        uint256 amount,
        address addr
    );

    event LogPayInterest(
        uint256 curBlock,
        uint256 key,
        uint256 amount
    );
}

