// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Pausable.sol";

import "./SafeDecimalMath.sol";
import "./Chick.sol";
import "./VaultToken.sol";
import "./GovernToken.sol";
import "./IPriceFeed.sol";
import "./IEthVault.sol";
import "./AddressBook.sol";
import "./AddressBookLib.sol";

contract VaultAccess is AccessControl {
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

    constructor()  public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyVault() {
        require(hasRole(VAULT_ROLE, _msgSender()), "only vault");
        _;
    }
}


contract RewardManagerForVault  {
    using SafeMath for uint256;
    using SafeDecimalMath for uint;


    uint256 public mRewardPerBlock;

    struct RewardData{
        uint mShareInfo;
        uint mShareAmount;
        uint mReward;
    }

    // mapping (uint => uint) public mShareInfo;
    // mapping (uint => uint) public mShareAmount;
    mapping (uint => RewardData ) public mDatas;

    uint256 public mAmount;           
    uint256 public mLastRewardBlock;  
    uint256 public mAccRewardPerShare;

    uint256 public mStartBlock;
    uint256 public mRemainReward;
    uint256 public mAccReward;


    constructor( uint256 rewardPerBlock, uint256 startBlock ) public {
        mRewardPerBlock = rewardPerBlock;
        mStartBlock = startBlock;
        mLastRewardBlock = mStartBlock;
    }


    function calcReward( uint256 curBlock, uint key ) public view returns (uint256 reward ) {
        uint256 accRewardPerShare = mAccRewardPerShare;
        if (curBlock > mLastRewardBlock && mAmount != 0) {
            uint256 multiplier = curBlock.sub( mLastRewardBlock, "cr curBlock sub overflow" );
            uint256 curReward = multiplier.mul(mRewardPerBlock);
            accRewardPerShare = mAccRewardPerShare.add(curReward.divideDecimalRoundPrecise(mAmount));
        }
        RewardData memory data = mDatas[ key ];
        uint shareStart = data.mShareInfo;
        reward = data.mShareAmount.multiplyDecimalRoundPrecise( accRewardPerShare.sub(shareStart,"reward share")).add( data.mReward);
    }


    function totalRemainReward() public view returns( uint256 ){
        return mRemainReward;
    } 

    function totalDepositAmount( ) public view returns( uint256 ){
        return mAmount;
    }

    function getShareStart(uint key) public view returns(uint ) {
        RewardData memory data = mDatas[ key ];
        return data.mShareInfo;
    }


    function getDepositAmount(uint key) public view returns(uint ) {
        RewardData memory data = mDatas[ key ];
        return data.mShareAmount;
    }

    //event LogDebug( uint256 u1, uint256 u2, uint256 u3, uint256 u4 );
    function _update( uint256 curBlock ) internal {
        if (curBlock <= mLastRewardBlock) {
            return;
        }
        if (mAmount == 0) {
            mLastRewardBlock = curBlock;
            return;
        }
        uint256 multiplier = curBlock.sub( mLastRewardBlock, "_update curBlock sub overflow" );
        uint256 curReward = multiplier.mul(mRewardPerBlock);
        mRemainReward = mRemainReward.add( curReward );
        mAccReward = mAccReward.add( curReward );

        mAccRewardPerShare = mAccRewardPerShare.add(curReward.divideDecimalRoundPrecise(mAmount));
        mLastRewardBlock = curBlock;
        //emit LogDebug( multiplier, curReward, mAmount, curReward.divideDecimalRoundPrecise(mAmount) );        
    }

    function _deposit( uint256 curBlock, uint key, uint256 amount) internal {
        _update( curBlock );
        RewardData storage data = mDatas[ key ];
        uint reward = 0;
        if( data.mShareAmount > 0 ){
            // reward
            uint shareStart = data.mShareInfo;
            uint shareAmount = data.mShareAmount;
            reward = shareAmount.multiplyDecimalRoundPrecise( mAccRewardPerShare.sub(shareStart,"reward share"));
            data.mShareAmount = shareAmount.add( amount );
        }
        else{
            data.mShareAmount = amount;
        }
        data.mShareInfo = mAccRewardPerShare;

        if(amount > 0) {
            mAmount = mAmount.add(amount);
        }
        data.mReward = data.mReward.add( reward );
    }

    function _withdraw( uint256 curBlock, uint key, uint256 amount) internal {
        RewardData storage data = mDatas[ key ];
        require( data.mShareAmount >= amount, "_withdraw amount error" );
        _update( curBlock );
        uint reward = 0;
        if( data.mShareAmount > 0 ){
            // reward
            uint shareStart = data.mShareInfo;
            reward = data.mShareAmount.multiplyDecimalRoundPrecise( mAccRewardPerShare.sub(shareStart,"reward share"));
            data.mShareAmount = data.mShareAmount.sub( amount, "sub share amount");
        }
        data.mShareInfo = mAccRewardPerShare;
        data.mReward = data.mReward.add( reward );
 
        if(amount > 0) {
            mAmount = mAmount.sub(amount, "_withdraw mAmount sub overflow");
        }
    }

    function _claim( uint256 curBlock, uint key ) internal returns( uint reward ) {
        RewardData storage data = mDatas[ key ];
        _update( curBlock );
        if( data.mShareAmount > 0 ){
            // reward
            uint shareStart = data.mShareInfo;
            reward = data.mShareAmount.multiplyDecimalRoundPrecise( mAccRewardPerShare.sub(shareStart,"reward share"));
        }
        data.mShareInfo = mAccRewardPerShare;
        reward = reward.add( data.mReward);
        data.mReward = 0;
        mRemainReward = mRemainReward.sub( reward, "_claim remain reward");
    }

}




contract GTokenRewardManager is VaultAccess, RewardManagerForVault, IGTokenRewardManager {

    AddressBook mAddressBook;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "only admin");
        _;
    }

    constructor( AddressBook addressBook, uint256 rewardPerBlock, uint256 startBlock ) public 
        RewardManagerForVault( rewardPerBlock, startBlock ) {
        mAddressBook = addressBook;
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    function setRewardPerBlock( uint256 rewardPerBlock ) public override onlyAdmin {
        _update( block.number );
        mRewardPerBlock = rewardPerBlock;
        emit LogSetRewardPerBlock( block.number, rewardPerBlock );
    }

    function getRewardPerBlock( ) external override view returns (uint256 rewardPerBlock ){
        rewardPerBlock = mRewardPerBlock;
    }


    function mint( uint256 curBlock, uint key, uint256 amount, address addr ) external override onlyVault {
        _deposit( curBlock, key, amount );
        // if( reward > 0 ){
        //     GovernToken govToken = AddressBookLib.governToken(mAddressBook);
        //     govToken.mint( addr, reward );
        // }
        emit LogMint( curBlock, key, amount, addr, mAccRewardPerShare, mRewardPerBlock );
    }

    function burn( uint256 curBlock, uint key, uint256 amount, address addr ) external override onlyVault {
        _withdraw( curBlock, key, amount );
        // GovernToken govToken = AddressBookLib.governToken(mAddressBook);
        // govToken.mint( addr, reward );
        emit LogBurn( curBlock, key, amount, addr, mAccRewardPerShare, mRewardPerBlock );
    }

    function claim( uint key,  address addr ) external override onlyVault{
        uint reward = _claim( block.number, key );
        if( reward > 0 ){
            GovernToken govToken = AddressBookLib.governToken(mAddressBook);
            govToken.mint( addr, reward );
        }
        emit LogClaim( block.number, key, addr, reward );
    } 

    function getReward( uint256 curBlock, uint key ) external override view returns (uint256 reward ){
        return calcReward( curBlock, key );
    }


    event LogMint(
        uint256 curBlock,
        uint256 key,
        uint256 amount,
        address addr,
        uint256 accRewardPerShare,
        uint256 rewardPerBlock
    );

    event LogBurn(
        uint256 curBlock,
        uint256 key,
        uint256 amount,
        address addr,
        uint256 accRewardPerShare,
        uint256 rewardPerBlock
    );

    event LogClaim(
        uint256 curBlock,
        uint256 key,
        address addr,
        uint256 reward
    );

    event LogSetRewardPerBlock(
        uint256 blockNb,
        uint256 rewardPerBlock
    );

}
