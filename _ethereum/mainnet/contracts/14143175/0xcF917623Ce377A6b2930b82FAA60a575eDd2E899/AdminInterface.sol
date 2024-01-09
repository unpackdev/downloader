// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./Math.sol";
import "./AlphaToken.sol";

/**
 * @title AdminInterface
 * @dev Implementation of AdminInterface
 */

contract AdminInterface is Pausable {
    using SafeERC20 for IERC20;

    // Decimal factors
    uint256 public COEFF_SCALE_DECIMALS_F = 1e4; // for fees
    uint256 public COEFF_SCALE_DECIMALS_P = 1e6; // for price
    uint256 public AMOUNT_SCALE_DECIMALS = 1; // for stable token

    // Fees rate
    uint256 public DEPOSIT_FEE_RATE = 50; // 
    uint256 public MANAGEMENT_FEE_RATE = 200;
    uint256 public PERFORMANCE_FEE_RATE = 2000;
    
    // Fees parameters
    uint256 public SECONDES_PER_YEAR = 86400 * 365;  
    uint256 public PERFORMANCE_FEES = 0;
    uint256 public MANAGEMENT_FEES = 0;
    uint256 public MANAGEMENT_FEE_TIME = 0;

    // ALPHA price
    uint256 public ALPHA_PRICE = 1000000;
    uint256 public ALPHA_PRICE_WAVG = 1000000;

     // User deposit parameters
    uint256 public MIN_AMOUNT = 1000 * 1e18;
    bool public CAN_CANCEL = true;
    
    // Withdrawal parameters
    uint256 public LOCKUP_PERIOD_MANAGER = 2 hours; 
    uint256 public LOCKUP_PERIOD_USER = 0 days; 
    uint256 public TIME_WITHDRAW_MANAGER = 0;
   
    // Portfolio management parameters
    uint public netDepositInd= 0;
    uint256 public netAmountEvent =0;
    uint256 public SLIPPAGE_TOLERANCE = 200;
    address public manager;
    address public treasury;
    address public alphaStrategy;

    //Contracts
    AlphaToken public alphaToken;
    IERC20 public stableToken;
    constructor( address _manager, address _treasury, address _stableTokenAddress,
     address _alphaToken) {
        require(
            _manager != address(0),
            "Formation.Fi: manager address is the zero address"
        );
        require(
           _treasury != address(0),
            "Formation.Fi:  treasury address is the zero address"
            );
        require(
            _stableTokenAddress != address(0),
            "Formation.Fi: Stable token address is the zero address"
        );
        require(
           _alphaToken != address(0),
            "Formation.Fi: ALPHA token address is the zero address"
        );
        manager = _manager;
        treasury = _treasury; 
        stableToken = IERC20(_stableTokenAddress);
        alphaToken = AlphaToken(_alphaToken);
        uint8 _stableTokenDecimals = ERC20( _stableTokenAddress).decimals();
        if ( _stableTokenDecimals == 6) {
            AMOUNT_SCALE_DECIMALS= 1e12;
        }
    }

    // Modifiers
      modifier onlyAlphaStrategy() {
        require(alphaStrategy != address(0),
            "Formation.Fi: alphaStrategy is the zero address"
        );
        require(msg.sender == alphaStrategy,
             "Formation.Fi: Caller is not the alphaStrategy"
        );
        _;
    }

     modifier onlyManager() {
        require(msg.sender == manager, 
        "Formation.Fi: Caller is not the manager");
        _;
    }
    modifier canCancel() {
        require(CAN_CANCEL == true, "Formation Fi: Cancel feature is not available");
        _;
    }

    // Setter functions
    function setTreasury(address _treasury) external onlyOwner {
        require(
            _treasury != address(0),
            "Formation.Fi: manager address is the zero address"
        );
        treasury = _treasury;
    }

    function setManager(address _manager) external onlyOwner {
        require(
            _manager != address(0),
            "Formation.Fi: manager address is the zero address"
        );
        manager = _manager;
    }

    function setAlphaStrategy(address _alphaStrategy) public onlyOwner {
         require(
            _alphaStrategy!= address(0),
            "Formation.Fi: alphaStrategy is the zero address"
        );
         alphaStrategy = _alphaStrategy;
    } 


    function setStableToken(address _stableTokenAddress) public onlyOwner {
        require(
             _stableTokenAddress!= address(0),
            "Formation.Fi: stable token address is the zero address"
        );
        stableToken = IERC20(_stableTokenAddress);
        uint8 _stableTokenDecimals = ERC20(_stableTokenAddress).decimals();
        if (_stableTokenDecimals == 6) {
           AMOUNT_SCALE_DECIMALS= 1e12;
        }
        else {
           AMOUNT_SCALE_DECIMALS = 1;   
        }
    } 
     function setCancel(bool _cancel) external onlyManager {
        CAN_CANCEL = _cancel;
    }
     function setLockupPeriodManager(uint256 _lockupPeriodManager) external onlyManager {
        LOCKUP_PERIOD_MANAGER = _lockupPeriodManager;
    }

    function setLockupPeriodUser(uint256 _lockupPeriodUser) external onlyManager {
        LOCKUP_PERIOD_USER = _lockupPeriodUser;
    }
 
    function setDepositFeeRate(uint256 _rate) external onlyManager {
        DEPOSIT_FEE_RATE = _rate;
    }

    function setManagementFeeRate(uint256 _rate) external onlyManager {
        MANAGEMENT_FEE_RATE = _rate;
    }

    function setPerformanceFeeRate(uint256 _rate) external onlyManager {
        PERFORMANCE_FEE_RATE  = _rate;
    }
    function setMinAmount(uint256 _minAmount) external onlyManager {
        MIN_AMOUNT = _minAmount;
     }

    function setCoeffScaleDecimalsFees (uint256 _scale) external onlyManager {
        require(
             _scale > 0,
            "Formation.Fi: decimal fees factor is 0"
        );

       COEFF_SCALE_DECIMALS_F  = _scale;
     }

    function setCoeffScaleDecimalsPrice (uint256 _scale) external onlyManager {
        require(
             _scale > 0,
            "Formation.Fi: decimal price factor is 0"
        );
       COEFF_SCALE_DECIMALS_P  = _scale;
     }

    function updateAlphaPrice(uint256 _price) external onlyManager{
        require(
             _price > 0,
            "Formation.Fi: ALPHA price is 0"
        );
        ALPHA_PRICE = _price;
    }

    function updateAlphaPriceWAVG(uint256 _price_WAVG) external onlyAlphaStrategy {
        require(
             _price_WAVG > 0,
            "Formation.Fi: ALPHA price WAVG is 0"
        );
        ALPHA_PRICE_WAVG  = _price_WAVG;
    }
    function updateManagementFeeTime(uint256 _time) external onlyAlphaStrategy {
        MANAGEMENT_FEE_TIME = _time;
    }
  
    // Calculate fees 
    function calculatePerformanceFees() external onlyManager {
        require(PERFORMANCE_FEES == 0, "Formation.Fi: performance fees pending minting");
        uint256 _deltaPrice = 0;
        if (ALPHA_PRICE > ALPHA_PRICE_WAVG) {
            _deltaPrice = ALPHA_PRICE - ALPHA_PRICE_WAVG;
            ALPHA_PRICE_WAVG = ALPHA_PRICE;
            PERFORMANCE_FEES = (alphaToken.totalSupply() *
            _deltaPrice * PERFORMANCE_FEE_RATE) / (ALPHA_PRICE * COEFF_SCALE_DECIMALS_F); 
        }
    }
    function calculateManagementFees() external onlyManager {
        require(MANAGEMENT_FEES == 0, "Formation.Fi: management fees pending minting");
        if (MANAGEMENT_FEE_TIME!= 0){
           uint256 _deltaTime;
           _deltaTime = block.timestamp -  MANAGEMENT_FEE_TIME; 
           MANAGEMENT_FEES = (alphaToken.totalSupply() * MANAGEMENT_FEE_RATE * _deltaTime ) 
           /(COEFF_SCALE_DECIMALS_F * SECONDES_PER_YEAR);
           MANAGEMENT_FEE_TIME = block.timestamp; 
        }
    }
     
    // Mint fees
    function mintFees() external onlyManager {
        if ((PERFORMANCE_FEES + MANAGEMENT_FEES) > 0){
           alphaToken.mint(treasury, PERFORMANCE_FEES + MANAGEMENT_FEES);
           PERFORMANCE_FEES = 0;
           MANAGEMENT_FEES = 0;
        }
    }

    // Calculate protfolio deposit indicator 
    function calculateNetDepositInd(uint256 _depositAmountTotal, uint256 _withdrawAmountTotal)
     public onlyAlphaStrategy returns( uint) {
        if ( _depositAmountTotal >= 
        ((_withdrawAmountTotal * ALPHA_PRICE) / COEFF_SCALE_DECIMALS_P)){
            netDepositInd = 1 ;
        }
        else {
            netDepositInd = 0;
        }
        return netDepositInd;
    }

    // Calculate protfolio Amount
    function calculateNetAmountEvent(uint256 _depositAmountTotal, uint256 _withdrawAmountTotal,
        uint256 _MAX_AMOUNT_DEPOSIT, uint256 _MAX_AMOUNT_WITHDRAW) 
        public onlyAlphaStrategy returns(uint256) {
        uint256 _netDeposit;
        if (netDepositInd == 1) {
             _netDeposit = _depositAmountTotal - 
             (_withdrawAmountTotal * ALPHA_PRICE) / COEFF_SCALE_DECIMALS_P;
             netAmountEvent = Math.min( _netDeposit, _MAX_AMOUNT_DEPOSIT);
        }
        else {
            _netDeposit= ((_withdrawAmountTotal * ALPHA_PRICE) / COEFF_SCALE_DECIMALS_P) -
            _depositAmountTotal;
            netAmountEvent = Math.min(_netDeposit, _MAX_AMOUNT_WITHDRAW);
        }
        return netAmountEvent;
    }

    // Protect against Slippage
    function protectAgainstSlippage(uint256 _withdrawAmount) public onlyManager 
         whenNotPaused   returns (uint256) {
        require(netDepositInd == 0, "Formation.Fi: it is not a slippage case");
        require(_withdrawAmount != 0, "Formation.Fi: amount is zero");
       uint256 _amount = 0; 
       uint256 _deltaAmount =0;
       uint256 _slippage = 0;
       uint256  _alphaAmount = 0;
       uint256 _balanceAlphaTreasury = alphaToken.balanceOf(treasury);
       uint256 _balanceStableTreasury = stableToken.balanceOf(treasury) * AMOUNT_SCALE_DECIMALS;
      
        if (_withdrawAmount< netAmountEvent){
          _amount = netAmountEvent - _withdrawAmount;   
          _slippage = _amount  / netAmountEvent;
            if ((_slippage * COEFF_SCALE_DECIMALS_F) >= SLIPPAGE_TOLERANCE) {
             return netAmountEvent;
            }
            else {
              _deltaAmount = Math.min( _amount, _balanceStableTreasury);
                if ( _deltaAmount  > 0){
                   stableToken.safeTransferFrom(treasury, alphaStrategy, _deltaAmount/AMOUNT_SCALE_DECIMALS);
                   _alphaAmount = (_deltaAmount * COEFF_SCALE_DECIMALS_P)/ALPHA_PRICE;
                   alphaToken.mint(treasury, _alphaAmount);
                   return _amount - _deltaAmount;
               }
               else {
                   return _amount; 
               }  
            }    
        
        }
        else  {
          _amount = _withdrawAmount - netAmountEvent;   
          _alphaAmount = (_amount * COEFF_SCALE_DECIMALS_P)/ALPHA_PRICE;
          _alphaAmount = Math.min(_alphaAmount, _balanceAlphaTreasury);
          if (_alphaAmount >0) {
             _deltaAmount = (_alphaAmount * ALPHA_PRICE)/COEFF_SCALE_DECIMALS_P;
             stableToken.safeTransfer(treasury, _deltaAmount/AMOUNT_SCALE_DECIMALS);   
             alphaToken.burn( treasury, _alphaAmount);
            }
           if ((_amount - _deltaAmount)>0) {
              stableToken.safeTransfer(manager, (_amount - _deltaAmount)/AMOUNT_SCALE_DECIMALS); 
            }
        }
        return 0;

    } 

    // send Stable Tokens to the contract
    function sendStableTocontract(uint256 _amount) external 
      whenNotPaused onlyManager {
      require( _amount > 0,  "Formation.Fi: amount is zero");
      stableToken.safeTransferFrom(msg.sender, address(this), _amount/AMOUNT_SCALE_DECIMALS);
      }

     // send Stable Tokens from the contract AlphaStrategy
    function sendStableFromcontract() external 
        whenNotPaused onlyManager {
        require(alphaStrategy != address(0),
            "Formation.Fi: alphaStrategy is the zero address"
        );
         stableToken.safeTransfer(alphaStrategy, stableToken.balanceOf(address(this)));
      }
  


}
