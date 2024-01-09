// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./Math.sol";
import "./AdminInterface.sol";
import "./AlphaToken.sol";
import "./DepositNFT.sol";
import "./WithdrawalNFT.sol";

/**
 * @title AlphaStrategy 
 * @dev Implementation of AlphaStrategy 
 */

contract AlphaStrategy is Pausable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // Decimal factors
    uint256 public AMOUNT_SCALE_DECIMALS = 1; // for stable token 
    uint256 public COEFF_SCALE_DECIMALS_F;  // for fees
    uint256 public COEFF_SCALE_DECIMALS_P; // for ALPHA price
    
    // Maximum allowed deposit/withdraw amount
    uint256 public MAX_AMOUNT_DEPOSIT = 1000000 * 1e18;
    uint256 public MAX_AMOUNT_WITHDRAW = 1000000 * 1e18;

    // Deposit fee rate 
    uint256 public  DEPOSIT_FEE_RATE;

    // Alpha prices
    uint256 public ALPHA_PRICE;
    uint256 public ALPHA_PRICE_WAVG;
 
    // Event variables
    uint public netDepositInd;
    uint256 public netAmountEvent;
    uint256 public maxDepositAmount;
    uint256 public maxWithdrawAmount;
    uint256 public withdrawAmountTotal;
    uint256 public withdrawAmountTotalOld;
    uint256 public depositAmountTotal;
    uint256 public TIME_WITHDRAW_MANAGER = 0;
     
    // ALPHA token data 
    uint256 public totalSupply;
   
   // NFT data 
    uint256 tokenIdDeposit;
    uint256 tokenIdWithdraw;

   // Other variables for Alpha strategy  
    bool public CAN_CANCEL = false; 
    address public treasury;
    mapping(address => uint256) public acceptedWithdrawPerAddress;
    
    //Contracts
    AdminInterface public admin;
    IERC20 public stableToken;
    AlphaToken public alphaToken;
    DepositNFT public depositNFT;
    WithdrawalNFT public withdrawalNFT;
    constructor(address _admin, address _stableTokenAddress, address _alphaToken,
        address _depositNFTAdress, address _withdrawalNFTAdress) {
        require(
            _admin != address(0),
            "Formation.Fi: admin address is the zero address"
        );
        require(
            _stableTokenAddress != address(0),
            "Formation.Fi: Stable token address is the zero address"
        );
        require(
           _alphaToken != address(0),
            "Formation.Fi: ALPHA token address is the zero address"
        );
        require(
           _depositNFTAdress != address(0),
            "Formation.Fi: withdrawal NFT address is the zero address"
        );
        require(
            _withdrawalNFTAdress != address(0),
            "Formation.Fi: withdrawal NFT address is the zero address"
        );
        
        admin = AdminInterface(_admin);
        stableToken = IERC20(_stableTokenAddress);
        alphaToken = AlphaToken(_alphaToken);
        depositNFT = DepositNFT(_depositNFTAdress);
        withdrawalNFT = WithdrawalNFT(_withdrawalNFTAdress);
        uint8 _stableTokenDecimals = ERC20(_stableTokenAddress).decimals();
        if (_stableTokenDecimals == 6) {
           AMOUNT_SCALE_DECIMALS = 1e12;
        }
    }

    
    // Modifiers
    
    modifier onlyManager() {
        address _manager = admin.manager();
        require(msg.sender == _manager, "Formation.Fi: Caller is not the manager");
        _;
    }

    modifier canCancel() {
        bool  _CAN_CANCEL = admin.CAN_CANCEL();
        require( _CAN_CANCEL == true, "Formation.Fi: Cancel feature is not available");
        _;
    }

    // Getter functions.
    
    function getTVL() public view returns (uint256) {
        return (admin.ALPHA_PRICE() * alphaToken.totalSupply()) 
        / admin.COEFF_SCALE_DECIMALS_P();
    }

    // Setter functions
    function set_MAX_AMOUNT_DEPOSIT(uint256 _MAX_AMOUNT_DEPOSIT) external 
         onlyManager {
         MAX_AMOUNT_DEPOSIT = _MAX_AMOUNT_DEPOSIT;

    }
    function set_MAX_AMOUNT_WITHDRAW(uint256 _MAX_AMOUNT_WITHDRAW) external 
      onlyManager{
         MAX_AMOUNT_WITHDRAW = _MAX_AMOUNT_WITHDRAW;      
    }
    function updateAdminData() internal {
      COEFF_SCALE_DECIMALS_F = admin.COEFF_SCALE_DECIMALS_F();
      COEFF_SCALE_DECIMALS_P= admin.COEFF_SCALE_DECIMALS_P(); 
      DEPOSIT_FEE_RATE = admin.DEPOSIT_FEE_RATE();
      ALPHA_PRICE = admin.ALPHA_PRICE();
      ALPHA_PRICE_WAVG = admin.ALPHA_PRICE_WAVG();
      totalSupply = alphaToken.totalSupply();
      treasury = admin.treasury();
    }
    
    // Calculate rebalancing Event parameters 
    function calculateNetDepositInd() public onlyManager {
        updateAdminData();
        netDepositInd = admin.calculateNetDepositInd(depositAmountTotal, withdrawAmountTotal);
    }
    function calculateNetAmountEvent() public onlyManager {
        netAmountEvent = admin.calculateNetAmountEvent(depositAmountTotal,  withdrawAmountTotal,
        MAX_AMOUNT_DEPOSIT,  MAX_AMOUNT_WITHDRAW);
    }
    function calculateMaxDepositAmount( ) external 
        whenNotPaused onlyManager {
        if (netDepositInd == 1) {
            maxDepositAmount = (netAmountEvent + ((withdrawAmountTotal * 
            ALPHA_PRICE) / COEFF_SCALE_DECIMALS_P));
        }
        else {
            maxDepositAmount = Math.min(depositAmountTotal, MAX_AMOUNT_DEPOSIT);
        }
    }
    
    function calculateMaxWithdrawAmount( ) external 
        whenNotPaused onlyManager
        {
        withdrawAmountTotalOld = withdrawAmountTotal;
        maxWithdrawAmount = ((netAmountEvent + depositAmountTotal) 
          * COEFF_SCALE_DECIMALS_P);
    }

    function calculateAcceptedWithdrawRequests(address[] memory _users) 
        internal {
        require (_users.length > 0, "Formation.Fi: no users provided");
        uint256 _amountLP;
        for (uint256 i = 0; i < _users.length; i++) {
            require(
            _users[i]!= address(0),
            "Formation.Fi: user address is the zero address"
            );
           ( , _amountLP, )= withdrawalNFT.pendingWithdrawPerAddress(_users[i]);
            if (withdrawalNFT.balanceOf(msg.sender) == 0) {
                continue;
            }
        _amountLP = Math.min((maxWithdrawAmount * _amountLP)/( ALPHA_PRICE * withdrawAmountTotalOld), _amountLP); 
        acceptedWithdrawPerAddress[_users[i]] = _amountLP;
        }   
    }

    // Validate users deposit requests 
    function finalizeDeposits( address[] memory _users) external 
        whenNotPaused onlyManager {
        uint256 _amountStable;
        uint256 _amountStableTotal = 0;
        uint256 _depositAlpha;
        uint256 _depositAlphaTotal = 0;
        uint256 _feeStable;
        uint256 _feeStableTotal = 0;
        uint256 _tokenIdDeposit;
        require (_users.length > 0, "Formation.Fi: no users provided ");
        
        for (uint256 i = 0; i < _users.length  ; i++) {
            address _user =_users[i];
            (  , _amountStable, )= depositNFT.pendingDepositPerAddress(_user);
           
            if (depositNFT.balanceOf(_user) == 0) {
                continue;
              }
            if (maxDepositAmount <= _amountStableTotal) {
                break;
             }
             _tokenIdDeposit = depositNFT.getTokenId(_user);
             _amountStable = Math.min(maxDepositAmount  - _amountStableTotal ,  _amountStable);
             _feeStable =  (_amountStable * DEPOSIT_FEE_RATE ) /
              COEFF_SCALE_DECIMALS_F;
             depositAmountTotal =  depositAmountTotal - _amountStable;
             _feeStableTotal = _feeStableTotal + _feeStable;
             _depositAlpha = (( _amountStable - _feeStable) *
             COEFF_SCALE_DECIMALS_P) / ALPHA_PRICE;
             _depositAlphaTotal = _depositAlphaTotal + _depositAlpha;
             _amountStableTotal = _amountStableTotal + _amountStable;
             alphaToken.mint(_user, _depositAlpha);
             depositNFT.updateDepositData( _user,  _tokenIdDeposit, _amountStable, false);
             alphaToken.addAmountDeposit(_user,  _depositAlpha );
             alphaToken.addTimeDeposit(_user, block.timestamp);
        }
        maxDepositAmount = maxDepositAmount - _amountStableTotal;
        if (_depositAlphaTotal >0){
            ALPHA_PRICE_WAVG  = (( totalSupply * ALPHA_PRICE_WAVG) + ( _depositAlphaTotal * ALPHA_PRICE)) /
            ( totalSupply + _depositAlphaTotal);
            }
            admin.updateAlphaPriceWAVG( ALPHA_PRICE_WAVG);

        if (admin.MANAGEMENT_FEE_TIME() == 0){
            admin.updateManagementFeeTime(block.timestamp);   
        }
        if ( _feeStableTotal >0){
           stableToken.safeTransfer( treasury, _feeStableTotal/AMOUNT_SCALE_DECIMALS);
        }
    }

    // Validate users withdrawal requests 
    function finalizeWithdrawals(address[] memory _users) external
        whenNotPaused onlyManager {
        uint256 tokensToBurn = 0;
        uint256 _amountLP;
        uint256 _amountStable;
        uint256 _tokenIdWithdraw;
        calculateAcceptedWithdrawRequests(_users);
        for (uint256 i = 0; i < _users.length; i++) {
            address _user =_users[i];
            ( , _amountLP, )= withdrawalNFT.pendingWithdrawPerAddress(_user);
         
            if (withdrawalNFT.balanceOf(_user) == 0) {
                continue;
            }
            _amountLP = acceptedWithdrawPerAddress[_user];
            withdrawAmountTotal = withdrawAmountTotal - _amountLP ;
            _amountStable = (_amountLP *  ALPHA_PRICE) / 
            ( COEFF_SCALE_DECIMALS_P * AMOUNT_SCALE_DECIMALS);
            stableToken.safeTransfer(_user, _amountStable);
            _tokenIdWithdraw = withdrawalNFT.getTokenId(_user);
            withdrawalNFT.updateWithdrawData( _user,  _tokenIdWithdraw, _amountLP, false);
            tokensToBurn = tokensToBurn + _amountLP;
            alphaToken.updateDepositDataExternal(_user, _amountLP);
            delete acceptedWithdrawPerAddress[_user]; 
        }
        if ((tokensToBurn) > 0){
           alphaToken.burn(address(this), tokensToBurn);
        }
        if (withdrawAmountTotal == 0){
            withdrawAmountTotalOld = 0;
        }
    }


    // Make deposit stable token request 
    function depositRequest(uint256 _amount) external whenNotPaused {
        require(_amount >= admin.MIN_AMOUNT(), 
        "Formation.Fi: amount is lower than the minimum deposit amount");
        if (depositNFT.balanceOf(msg.sender)==0){
            tokenIdDeposit = tokenIdDeposit +1;
            depositNFT.mint(msg.sender, tokenIdDeposit, _amount);
        }
        else {
            uint256 _tokenIdDeposit = depositNFT.getTokenId(msg.sender);
            depositNFT.updateDepositData (msg.sender,  _tokenIdDeposit, _amount, true);
        }
        depositAmountTotal = depositAmountTotal + _amount; 
        stableToken.safeTransferFrom(msg.sender, address(this), _amount/AMOUNT_SCALE_DECIMALS);
    }

    // Cancel deposit stable token request 
    function cancelDepositRequest(uint256 _amount) external whenNotPaused canCancel {
        uint256 _tokenIdDeposit = depositNFT.getTokenId(msg.sender);
        require( _tokenIdDeposit > 0, 
        "Formation.Fi: deposit request doesn't exist"); 
        depositNFT.updateDepositData(msg.sender,  _tokenIdDeposit, _amount, false);
        depositAmountTotal = depositAmountTotal - _amount; 
        stableToken.safeTransfer(msg.sender, _amount/AMOUNT_SCALE_DECIMALS);
        
    }
    
    // Make withdrawal ALPHA token request 
    function withdrawRequest(uint256 _amount) external whenNotPaused {
        require ( _amount > 0, "Formation Fi: amount is zero");
        require(withdrawalNFT.balanceOf(msg.sender) == 0, "Formation.Fi: withdraw request on pending");
        require (alphaToken.ChecklWithdrawalRequest(msg.sender, _amount, admin.LOCKUP_PERIOD_USER()),
         "Formation.Fi: user Position locked");
        tokenIdWithdraw = tokenIdWithdraw +1;
        withdrawalNFT.mint(msg.sender, tokenIdWithdraw, _amount);
        withdrawAmountTotal = withdrawAmountTotal + _amount;
        alphaToken.transferFrom(msg.sender, address(this), _amount);
         
    }

    // Cancel withdraw ALPHA token request 
    function cancelWithdrawalRequest( uint256 _amount) external whenNotPaused {
        require ( _amount > 0, "Formation Fi: amount is zero");
        uint256 _tokenIdWithdraw = withdrawalNFT.getTokenId(msg.sender);
        require( _tokenIdWithdraw > 0, 
        "Formation.Fi: withdraw request doesn't exist"); 
        withdrawalNFT.updateWithdrawData(msg.sender, _tokenIdWithdraw, _amount, false);
        alphaToken.transfer(msg.sender, _amount);
    }
    
    // Withdraw stable tokens from the contract 
    function availableBalanceWithdrawal(uint256 _amount) external 
        whenNotPaused onlyManager {
        require((block.timestamp - TIME_WITHDRAW_MANAGER) >= admin.LOCKUP_PERIOD_MANAGER(), 
         "Formation.Fi: Manager Position locked");
        uint256 _amountScaled = _amount/AMOUNT_SCALE_DECIMALS;
        require(
            stableToken.balanceOf(address(this)) >= _amountScaled,
            "Formation.Fi: requested amount exceeds contract balance"
        );
        TIME_WITHDRAW_MANAGER = block.timestamp;
        stableToken.safeTransfer(admin.manager(), _amountScaled);
    }
    
    // Send stable tokens to the contract
    function sendStableTocontract(uint256 _amount) external 
      whenNotPaused onlyManager {
      require( _amount > 0,  "Formation.Fi: amount is zero");
      stableToken.safeTransferFrom(msg.sender, address(this), _amount/AMOUNT_SCALE_DECIMALS);
    } 
    
}
