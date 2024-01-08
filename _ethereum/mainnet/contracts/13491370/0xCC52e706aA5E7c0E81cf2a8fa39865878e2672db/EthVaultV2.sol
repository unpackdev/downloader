// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";


import "./SafeDecimalMath.sol";
import "./Chick.sol";
import "./VaultToken.sol";
import "./GovernToken.sol";
import "./EthReward.sol";
import "./EthInterest.sol";
import "./IPriceFeed.sol";
import "./IEthVault.sol";
import "./AddressBook.sol";
import "./AddressBookLib.sol";



contract EthVaultV2 is  Pausable, AccessControl, ReentrancyGuard {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    using Address for address;

    struct Vault {
        uint256 ethAmount;
        uint256 chickAmount;
        uint256 time;
    }

    mapping(uint256 => Vault ) public mVaults;

    uint256 private mLiquidationRatio;
    uint256 private mCollateralRatio;

    AddressBook mAddressBook;
    GTokenRewardManager mRewardMgr;
    InterestManager mInterestMgr;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "only admin");
        _;
    }

    bytes32 public constant LIQUIDATE_ROLE = keccak256("LIQUIDATE_ROLE");

    modifier onlyLiquidator() {
        require(hasRole(LIQUIDATE_ROLE, _msgSender()), "only liquidator");
        _;
    }

    constructor( AddressBook addressBook, uint256 liquidationRatio, uint256 collateralRatio ) public {
        mAddressBook = addressBook;
        mLiquidationRatio = liquidationRatio;
        mCollateralRatio = collateralRatio;
        //_setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(LIQUIDATE_ROLE, _msgSender());
    }



    function liquidationRatio() external view returns(uint256){
       return mLiquidationRatio;
    }

    function collateralRatio() external view returns(uint256){
       return mCollateralRatio;
    }


    event LogSetLiquidationRatio( uint256 v );
    function setLiquidationRatio( uint256 v ) external onlyAdmin {
       mLiquidationRatio = v;
       emit LogSetLiquidationRatio( v );
    }

    event LogSetCollateralRatio( uint256 v );
    function setCollateralRatio( uint256 v ) external onlyAdmin{
       mCollateralRatio = v;
       emit LogSetCollateralRatio( v );
    }


    function vaultInfo(uint256 vaultId ) external view
        returns (
            address addr,
            uint256 ethAmount,
            uint256 chickAmount,
            uint256 interest,
            uint256 reward,
            uint256 time
        )
    {
        VaultToken vToken = AddressBookLib.vaultToken(mAddressBook);

        addr = vToken.ownerOf( vaultId );

        Vault memory v = mVaults[ vaultId ];
        
        ethAmount = v.ethAmount;
        chickAmount = v.chickAmount;
        IInterestManager interestMgr = AddressBookLib.interestMgr( mAddressBook);
        interest = interestMgr.getInterest( block.number, vaultId );
        time = v.time;

        IGTokenRewardManager rewarder = AddressBookLib.gTokenRewardMgr( mAddressBook);
        reward = rewarder.getReward( block.number, vaultId );
    }


    function newVault( ) external whenNotPaused nonReentrant {
        VaultToken vToken = AddressBookLib.vaultToken(mAddressBook);

        uint256 id = vToken.mintFromRole(msg.sender);
        mVaults[id] = Vault( 0, 0, now);

        emit LogNewVault(id, msg.sender, now );
    }

    function depositEth( uint256 vaultId ) external payable whenNotPaused nonReentrant {
        VaultToken vToken = AddressBookLib.vaultToken(mAddressBook);
        address owner = vToken.ownerOf(vaultId);
        // owner != msg.send is acceptable
        //require( owner == msg.sender );

        Vault storage v = mVaults[ vaultId ];

        v.ethAmount = v.ethAmount.add( msg.value );
        emit LogDepositEth( vaultId, owner, msg.sender, msg.value, v.ethAmount);
    }


    function withdrawEth( uint256 vaultId, uint256 amount ) external whenNotPaused nonReentrant {
        IPriceFeed priceFeed = AddressBookLib.ethPriceFeed(mAddressBook);
        //require(!priceFeed.checkPriceError(), "price error");

        VaultToken vToken = AddressBookLib.vaultToken(mAddressBook);
        address payable owner = payable(vToken.ownerOf(vaultId));
        require( owner == msg.sender );


        Vault storage v = mVaults[ vaultId ];
        require(v.ethAmount > 0, "vault is empty");
        require( v.ethAmount >= amount, "eth amount error" );

        int256 price = 0;
        (, price, , , ) = priceFeed.latestRoundData();
        require(price >= 0, "price should >= 0");
        uint256 uPrice = uint256(price);

        uint256 newAmount = v.ethAmount.sub( amount );
        uint256 newValue = newAmount.multiplyDecimal(uPrice);
        uint256 valueRequired = v.chickAmount.multiplyDecimal(mCollateralRatio);
        require( newValue >= valueRequired );
        v.ethAmount = newAmount;

        owner.transfer(amount);

        emit LogWithdrawEth( vaultId, owner, amount, newAmount);
    }




    function mint( uint256 vaultId, uint256 amount ) external  whenNotPaused nonReentrant {
        IPriceFeed priceFeed = AddressBookLib.ethPriceFeed(mAddressBook);
        require(!priceFeed.checkPriceError(), "price error");

        address receiver = msg.sender;
        VaultToken vToken = AddressBookLib.vaultToken(mAddressBook);
        address owner = vToken.ownerOf(vaultId);
        require( owner == msg.sender );

        Vault storage v = mVaults[ vaultId ];

        int256 price = 0;
        (, price, , , ) = priceFeed.latestRoundData();
        require(price >= 0, "price should >= 0");

        uint256 newChickAmount = v.chickAmount.add( amount );
        require( v.ethAmount.multiplyDecimal(uint256(price)) >= newChickAmount.multiplyDecimal(mCollateralRatio) );

        v.chickAmount = newChickAmount;

        Chick chick = AddressBookLib.chick(mAddressBook);
        chick.mint(receiver, amount);

        IInterestManager interest = AddressBookLib.interestMgr( mAddressBook);
        interest.mint( block.number, vaultId, amount, owner );

        IGTokenRewardManager rewarder = AddressBookLib.gTokenRewardMgr( mAddressBook);
        rewarder.mint( block.number, vaultId, amount, owner );

        emit LogMintChick( vaultId, owner, amount, newChickAmount, v.ethAmount);
    }


    function burn( uint256 vaultId, uint256 amount ) external whenNotPaused nonReentrant {
        VaultToken vToken = AddressBookLib.vaultToken(mAddressBook);
        address owner = vToken.ownerOf(vaultId);
        require( owner == msg.sender );

        Vault storage v = mVaults[ vaultId ];

        // pay interest
        Chick chick = AddressBookLib.chick(mAddressBook);
        IInterestManager interestMgr = AddressBookLib.interestMgr( mAddressBook);
        uint interest = interestMgr.getInterest( block.number, vaultId );
        uint total  = v.chickAmount.add(  interest );
        require( total >= amount );
        
        if( interest > amount ){
            interest = amount;
        }
        interestMgr.payInterest( block.number, vaultId, interest );

        // burn 
        chick.burnFromRole( msg.sender, amount );

        // save interest on vault
        chick.mint( address(this), interest);

        // pay capital 
        amount = amount.sub( interest,"burn, pay interest");
        v.chickAmount = v.chickAmount.sub( amount );

        // record reward ,interest
        interestMgr.burn( block.number, vaultId, amount, owner );

        IGTokenRewardManager rewarder = AddressBookLib.gTokenRewardMgr( mAddressBook);
        rewarder.burn( block.number, vaultId, amount, owner );

        emit LogBurnChick(vaultId, owner, amount, v.chickAmount, v.ethAmount,interest );
    }

    function claim( uint256 vaultId  ) external nonReentrant {
        VaultToken vToken = AddressBookLib.vaultToken(mAddressBook);
        address owner = vToken.ownerOf(vaultId);
        require( owner == msg.sender );

        //Vault memory v = mVaults[ vaultId ];

        IGTokenRewardManager rewarder = AddressBookLib.gTokenRewardMgr( mAddressBook);
        rewarder.claim( vaultId, owner );
    } 


    function liquidate( uint256 vaultId ) external nonReentrant onlyLiquidator {
        Vault storage v = mVaults[ vaultId ];

        VaultToken vToken = AddressBookLib.vaultToken(mAddressBook);
        address owner = vToken.ownerOf(vaultId);

        IInterestManager interestMgr = AddressBookLib.interestMgr( mAddressBook);
        uint interest = interestMgr.getInterest( block.number, vaultId );

        // check price
        IPriceFeed priceFeed = AddressBookLib.ethPriceFeed(mAddressBook);
        //require(!priceFeed.checkPriceError(), "price error");

        int256 price = 0;
        (, price, , , ) = priceFeed.latestRoundData();
        require(price >= 0, "price should >= 0");

        require( v.ethAmount.multiplyDecimal(uint256(price)) <= v.chickAmount.add( interest ).multiplyDecimal(mLiquidationRatio),"liquidation ratio" );

        // clear interest
        interestMgr.burn( block.number, vaultId, v.chickAmount, owner );
        interestMgr.payInterest( block.number ,vaultId, interest );

        // clear reward
        IGTokenRewardManager rewarder = AddressBookLib.gTokenRewardMgr( mAddressBook);
        uint reward = rewarder.getReward( block.number, vaultId );
        rewarder.burn( block.number, vaultId, v.chickAmount, owner );

        // clear data
        uint ethAmount = v.ethAmount;
        uint chickAmount = v.chickAmount;
        v.chickAmount = 0;
        v.ethAmount = 0;

        // clear eth
        ILiquidationManager liquidator = AddressBookLib.liquidationMgr( mAddressBook);
        liquidator.liquidate{ value: ethAmount }( vaultId,  owner, ethAmount, chickAmount, interest, reward );
    }

    function withdrawInterest( address addr, uint256 amount ) external nonReentrant onlyAdmin {
        Chick chick = AddressBookLib.chick(mAddressBook);
        chick.transfer( addr, amount );
    } 




    event LogNewVault(
        uint256 id,
        address addr,
        uint256 time
    );

    event LogDepositEth(
        uint256 id,
        address addr,
        address sender,
        uint256 depositEth,
        uint256 totalEth
    );

    event LogWithdrawEth(
        uint256 id,
        address addr,
        uint256 widthdrawEth,
        uint256 totalEth
    );

    event LogMintChick(
        uint256 id,
        address addr,
        uint256 mintAmount,
        uint256 totalChick,
        uint256 totalEth
    );

    event LogBurnChick(
        uint256 id,
        address addr,
        uint256 burnAmount,
        uint256 totalChick,
        uint256 totalEth,
        uint256 interest
    );

    receive() payable external {}
}
