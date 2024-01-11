// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Token.sol";
import "./Math.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract Admin.
*/

contract Admin is Ownable {
    using SafeERC20 for IERC20;
    uint256 public constant FACTOR_FEES_DECIMALS = 1e4; 
    uint256 public constant FACTOR_PRICE_DECIMALS = 1e6;
    uint256 public constant  SECONDES_PER_YEAR = 365 days; 
    uint256 public slippageTolerance = 200;
    uint256 public  amountScaleDecimals = 1; 
    uint256 public depositFeeRate = 50;  
    uint256 public depositFeeRateParity= 15; 
    uint256 public managementFeeRate = 200;
    uint256 public performanceFeeRate = 2000;
    uint256 public performanceFees = 0;
    uint256 public managementFees = 0;
    uint256 public managementFeesTime = 0;
    uint256 public tokenPrice = 1e6;
    uint256 public tokenPriceMean = 1e6;
    uint256 public minAmount= 100 * 1e18;
    uint256 public lockupPeriodUser = 0 days; 
    uint256 public timeWithdrawManager = 0;
    uint public netDepositInd= 0;
    uint256 public netAmountEvent =0;
    address public manager;
    address public treasury;
    address public investement;
    address private safeHouse;
    bool public isCancel= true;
    Token public token;
    IERC20 public stableToken;


    constructor( address _manager, address _treasury,  address _stableTokenAddress,
     address _tokenAddress) {
        require(
            _manager != address(0),
            "Formation.Fi: zero address"
        );

        require(
           _treasury != address(0),
            "Formation.Fi:  zero address"
            );

        require(
            _stableTokenAddress != address(0),
            "Formation.Fi:  zero address"
        );

        require(
           _tokenAddress != address(0),
            "Formation.Fi:  zero address"
        );

        manager = _manager;
        treasury = _treasury; 
        stableToken = IERC20(_stableTokenAddress);
        token = Token(_tokenAddress);
        uint8 _stableTokenDecimals = ERC20( _stableTokenAddress).decimals();
        if ( _stableTokenDecimals == 6) {
            amountScaleDecimals= 1e12;
        }
    }

    modifier onlyInvestement() {
        require(investement != address(0),
            "Formation.Fi:  zero address"
        );

        require(msg.sender == investement,
             "Formation.Fi:  not investement"
        );
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, 
        "Formation.Fi: not manager");
        _;
    }

     /**
     * @dev Setter functions to update the Portfolio Parameters.
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(
            _treasury != address(0),
            "Formation.Fi: zero address"
        );

        treasury = _treasury;
    }

    function setManager(address _manager) external onlyOwner {
        require(
            _manager != address(0),
            "Formation.Fi: zero address"
        );

        manager = _manager;
    }

    function setInvestement(address _investement) external onlyOwner {
        require(
            _investement!= address(0),
            "Formation.Fi: zero address"
        );

        investement = _investement;
    } 

    function setSafeHouse(address _safeHouse) external onlyOwner {
        require(
            _safeHouse!= address(0),
            "Formation.Fi: zero address"
        );

        safeHouse = _safeHouse;
    } 

    function setCancel(bool _cancel) external onlyManager {
        isCancel= _cancel;
    }
  
    function setLockupPeriodUser(uint256 _lockupPeriodUser) external onlyManager {
        lockupPeriodUser = _lockupPeriodUser;
    }
 
    function setDepositFeeRate(uint256 _rate) external onlyManager {
        depositFeeRate= _rate;
    }

    function setDepositFeeRateParity(uint256 _rate) external onlyManager {
        depositFeeRateParity= _rate;
    }

    function setManagementFeeRate(uint256 _rate) external onlyManager {
        managementFeeRate = _rate;
    }

    function setPerformanceFeeRate(uint256 _rate) external onlyManager {
        performanceFeeRate  = _rate;
    }
    function setMinAmount(uint256 _minAmount) external onlyManager {
        minAmount= _minAmount;
     }

    function updateTokenPrice(uint256 _price) external onlyManager {
        require(
             _price > 0,
            "Formation.Fi: zero price"
        );

        tokenPrice = _price;
    }

    function updateTokenPriceMean(uint256 _price) external onlyInvestement {
        require(
             _price > 0,
            "Formation.Fi: zero price"
        );
        tokenPriceMean  = _price;
    }

    function updateManagementFeeTime(uint256 _time) external onlyInvestement {
        managementFeesTime = _time;
    }
    

     /**
     * @dev Calculate performance Fees.
     */
    function calculatePerformanceFees() external onlyManager {
        require(performanceFees == 0, "Formation.Fi: fees on pending");

        uint256 _deltaPrice = 0;
        if (tokenPrice > tokenPriceMean) {
            _deltaPrice = tokenPrice - tokenPriceMean;
            tokenPriceMean = tokenPrice;
            performanceFees = (token.totalSupply() *
            _deltaPrice * performanceFeeRate) / (tokenPrice * FACTOR_FEES_DECIMALS); 
        }
    }

    
     /**
     * @dev Calculate management Fees.
     */
    function calculateManagementFees() external onlyManager {
        require(managementFees == 0, "Formation.Fi: fees on pending");
        if (managementFeesTime!= 0){
           uint256 _deltaTime;
           _deltaTime = block.timestamp -  managementFeesTime; 
           managementFees = (token.totalSupply() * managementFeeRate * _deltaTime ) 
           /(FACTOR_FEES_DECIMALS * SECONDES_PER_YEAR);
           managementFeesTime = block.timestamp; 
        }
    }
     
    /**
     * @dev Mint Fees.
     */
    function mintFees() external onlyManager {
        require ((performanceFees + managementFees) > 0, "Formation.Fi: zero fees");

        token.mint(treasury, performanceFees + managementFees);
        performanceFees = 0;
        managementFees = 0;
    }

    /**
     * @dev Calculate net deposit indicator
     * @param _depositAmountTotal the total requested deposit amount by users.
     * @param  _withdrawalAmountTotal the total requested withdrawal amount by users.
     * @param _maxDepositAmount the maximum accepted deposit amount by event.
     * @param _maxWithdrawalAmount the maximum accepted withdrawal amount by event.
     * @return net Deposit indicator: 1 if net deposit case, 0 otherwise (net withdrawal case).
     */
    function calculateNetDepositInd(uint256 _depositAmountTotal, 
        uint256 _withdrawalAmountTotal, uint256 _maxDepositAmount, 
        uint256 _maxWithdrawalAmount) external onlyInvestement returns( uint256) {
        _depositAmountTotal = Math.min(  _depositAmountTotal,
         _maxDepositAmount);
        _withdrawalAmountTotal =  (_withdrawalAmountTotal * tokenPrice) / FACTOR_PRICE_DECIMALS;
        _withdrawalAmountTotal= Math.min(_withdrawalAmountTotal,
        _maxWithdrawalAmount);
        uint256  _depositAmountTotalAfterFees = _depositAmountTotal - 
        ( _depositAmountTotal * depositFeeRate)/ FACTOR_FEES_DECIMALS;
        if  ( _depositAmountTotalAfterFees >= 
            ((_withdrawalAmountTotal * tokenPrice) / FACTOR_PRICE_DECIMALS)){
            netDepositInd = 1 ;
        }
        else {
            netDepositInd = 0;
        }
        return netDepositInd;
    }

    /**
     * @dev Calculate net amount 
     * @param _depositAmountTotal the total requested deposit amount by users.
     * @param _withdrawalAmountTotal the total requested withdrawal amount by users.
     * @param _maxDepositAmount the maximum accepted deposit amount by event.
     * @param _maxWithdrawalAmount the maximum accepted withdrawal amount by event.
     * @return net amount.
     */
    function calculateNetAmountEvent(uint256 _depositAmountTotal, 
        uint256 _withdrawalAmountTotal, uint256 _maxDepositAmount, 
        uint256 _maxWithdrawalAmount) external onlyInvestement returns(uint256) {
        _depositAmountTotal = Math.min(  _depositAmountTotal,
         _maxDepositAmount);
        _withdrawalAmountTotal =  (_withdrawalAmountTotal * tokenPrice) / FACTOR_PRICE_DECIMALS;
        _withdrawalAmountTotal= Math.min(_withdrawalAmountTotal,
        _maxWithdrawalAmount);
         uint256  _depositAmountTotalAfterFees = _depositAmountTotal - 
        ( _depositAmountTotal * depositFeeRate)/ FACTOR_FEES_DECIMALS;
        
        if (netDepositInd == 1) {
             netAmountEvent =  _depositAmountTotalAfterFees - _withdrawalAmountTotal;
        }
        else {
             netAmountEvent = _withdrawalAmountTotal - _depositAmountTotalAfterFees;
        
        }
        return netAmountEvent;
    }

    /**
     * @dev Protect against slippage due to assets sale.
     * @param _withdrawalAmount the value of sold assets in Stablecoin.
     * _withdrawalAmount has to be sent to the contract.
     * treasury has to approve the contract for both Stablecoin and token.
     * @return Missed amount to send to the contract due to slippage.
     */
    function protectAgainstSlippage(uint256 _withdrawalAmount) external onlyManager 
        returns (uint256) {
        require(_withdrawalAmount != 0, "Formation.Fi: zero amount");

        require(netDepositInd == 0, "Formation.Fi: no slippage");
       
       uint256 _amount = 0; 
       uint256 _deltaAmount =0;
       uint256 _slippage = 0;
       uint256  _tokenAmount = 0;
       uint256 _balanceTokenTreasury = token.balanceOf(treasury);
       uint256 _balanceStableTreasury = stableToken.balanceOf(treasury) * amountScaleDecimals;
      
        if (_withdrawalAmount< netAmountEvent){
            _amount = netAmountEvent - _withdrawalAmount;   
            _slippage = (_amount * FACTOR_FEES_DECIMALS ) / netAmountEvent;
            if (_slippage >= slippageTolerance) {
                return netAmountEvent;
            }
            else {
                 _deltaAmount = Math.min( _amount, _balanceStableTreasury);
                if ( _deltaAmount  > 0){
                    stableToken.safeTransferFrom(treasury, investement, _deltaAmount/amountScaleDecimals);
                    _tokenAmount = (_deltaAmount * FACTOR_PRICE_DECIMALS)/tokenPrice;
                    token.mint(treasury, _tokenAmount);
                    return _amount - _deltaAmount;
                }
                else {
                     return _amount; 
                }  
            }    
        
        }
        else  {
           _amount = _withdrawalAmount - netAmountEvent;   
          _tokenAmount = (_amount * FACTOR_PRICE_DECIMALS)/tokenPrice;
          _tokenAmount = Math.min(_tokenAmount, _balanceTokenTreasury);
          if (_tokenAmount >0) {
              _deltaAmount = (_tokenAmount * tokenPrice)/FACTOR_PRICE_DECIMALS;
              stableToken.safeTransfer(treasury, _deltaAmount/amountScaleDecimals);   
              token.burn( treasury, _tokenAmount);
            }
           if ((_amount - _deltaAmount) > 0) {
            
              stableToken.safeTransfer(safeHouse, (_amount - _deltaAmount)/amountScaleDecimals); 
            }
        }
        return 0;

    } 

     /**
     * @dev Send Stablecoin from the manager to the contract.
     * @param _amount  tha amount to send.
     */
    function sendStableTocontract(uint256 _amount) external 
     onlyManager {
      require( _amount > 0,  "Formation.Fi: zero amount");

      stableToken.safeTransferFrom(msg.sender, address(this),
       _amount/amountScaleDecimals);
    }

   
     /**
     * @dev Send Stablecoin from the contract to the contract Investement.
     */
    function sendStableFromcontract() external 
        onlyManager {
        require(investement != address(0),
            "Formation.Fi: zero address"
        );
         stableToken.safeTransfer(investement, stableToken.balanceOf(address(this)));
    }
  
}
