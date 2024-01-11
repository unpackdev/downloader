// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Pausable.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./Admin.sol";
import "./Token.sol";
import "./DepositConfirmation.sol";
import "./WithdrawalConfirmation.sol";
import "./SafeHouse.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract Investement.
*/

contract Investement is Pausable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    uint256 public constant COEFF_SCALE_DECIMALS_F = 1e4;
    uint256 public constant COEFF_SCALE_DECIMALS_P = 1e6; 
    uint256 public amountScaleDecimals = 1;
    uint256 public maxDepositAmount = 1000000 * 1e18;
    uint256 public maxWithdrawalAmount = 1000000 * 1e18;
     uint256 public maxDeposit = 0;
    uint256 public maxWithdrawal = 0;
    uint256 public depositFeeRate;
    uint256 public depositFeeRateParity;
    uint256 public tokenPrice;
    uint256 public tokenPriceMean;
    uint256 public netDepositInd;
    uint256 public netAmountEvent;
    uint256 public withdrawalAmountTotal;
    uint256 public withdrawalAmountTotalOld;
    uint256 public depositAmountTotal;
    uint256 public validatedDepositParityStableAmount = 0;
    uint256 public validatedWithdrawalParityStableAmount = 0;
    uint256 public validatedDepositParityTokenAmount = 0;
    uint256 public validatedWithdrawalParityTokenAmount = 0;
    uint256 public tokenTotalSupply;
    uint256 public tokenIdDeposit;
    uint256 public tokenIdWithdraw;
    address private treasury;
    address private safeHouse;
    address public parity;
    mapping(address => uint256) public acceptedWithdrawalPerAddress;
    Admin public admin;
    IERC20 public stableToken;
    Token public token;
    DepositConfirmation public deposit;
    WithdrawalConfirmation public withdrawal;
    event DepositRequest(address indexed _address, uint256 _amount);
    event CancelDepositRequest(address indexed _address, uint256 _amount);
    event WithdrawalRequest(address indexed _address, uint256 _amount);
    event CancelWithdrawalRequest(address indexed _address, uint256 _amount);
    event ValidateDeposit(address indexed _address, uint256 _finalizedAmount, uint256 _mintedAmount);
    event ValidateWithdrawal(address indexed _address, uint256 _finalizedAmount, uint256 _SentAmount);
   
    constructor(address _admin, address _safeHouse, address _stableTokenAddress, 
        address _token,  address _depositConfirmationAddress, 
        address __withdrawalConfirmationAddress) {
        require(
            _admin != address(0),
            "Formation.Fi: zero address"
        );
        require(
            _safeHouse != address(0),
            "Formation.Fi:  zero address"
        );
        require(
            _stableTokenAddress != address(0),
            "Formation.Fi:  zero address"
        );
        require(
           _token != address(0),
            "Formation.Fi:  zero address"
        );
        require(
           _depositConfirmationAddress != address(0),
            "Formation.Fi:  zero address"
        );
        require(
            __withdrawalConfirmationAddress != address(0),
            "Formation.Fi:  zero address"
        );
        
        admin = Admin(_admin);
        safeHouse = _safeHouse;
        stableToken = IERC20(_stableTokenAddress);
        token = Token(_token);
        deposit = DepositConfirmation(_depositConfirmationAddress);
        withdrawal = WithdrawalConfirmation(__withdrawalConfirmationAddress);
        uint8 _stableTokenDecimals = ERC20(_stableTokenAddress).decimals();
        if (_stableTokenDecimals == 6) {
           amountScaleDecimals = 1e12;
        }
    }
  
    modifier onlyManager() {
        address _manager = admin.manager();
        require(msg.sender == _manager, "Formation.Fi: no manager");
        _;
    }

    modifier cancel() {
        bool  _isCancel = admin.isCancel();
        require( _isCancel == true, "Formation.Fi: no cancel");
        _;
    }

     /**
     * @dev Setter functions to update the Portfolio Parameters.
     */
    function setMaxDepositAmount(uint256 _maxDepositAmount) external 
        onlyManager {
        maxDepositAmount = _maxDepositAmount;

    }
    function setMaxWithdrawalAmount(uint256 _maxWithdrawalAmount) external 
        onlyManager{
         maxWithdrawalAmount = _maxWithdrawalAmount;      
    }

    function setParity(address _parity) external onlyOwner{
        require(
            _parity != address(0),
            "Formation.Fi: zero address"
        );

        parity = _parity;      
    }

    function setSafeHouse(address _safeHouse) external onlyOwner{
          require(
            _safeHouse != address(0),
            "Formation.Fi: zero address"
        );  
        safeHouse = _safeHouse;
    }
     /**
     * @dev Calculate net deposit indicator
     */
    function calculateNetDepositInd( ) public onlyManager {
        updateAdminData();
        netDepositInd = admin.calculateNetDepositInd(depositAmountTotal, withdrawalAmountTotal,
        maxDepositAmount,  maxWithdrawalAmount);
    }

     /**
     * @dev Calculate net amount 
     */
    function calculateNetAmountEvent( ) public onlyManager {
        netAmountEvent = admin.calculateNetAmountEvent(depositAmountTotal,  withdrawalAmountTotal,
        maxDepositAmount,  maxWithdrawalAmount);
    }

     /**
     * @dev Calculate the maximum deposit amount to be validated 
     * by the manager for the users.
     */
    function calculateMaxDepositAmount( ) public onlyManager {
             maxDeposit = Math.min(depositAmountTotal, maxDepositAmount);
        }
    
     /**
     * @dev Calculate the maximum withdrawal amount to be validated 
     * by the manager for the users.
     */
    function calculateMaxWithdrawAmount( ) public onlyManager {
        withdrawalAmountTotalOld = withdrawalAmountTotal;
        maxWithdrawal = (Math.min(withdrawalAmountTotal, maxWithdrawalAmount)
          * COEFF_SCALE_DECIMALS_P);
    }

     /**
     * @dev Calculate the event parameters by the manager. 
     */
    function calculateEventParameters( ) external onlyManager {
        calculateNetDepositInd( );
        calculateNetAmountEvent( );
        calculateMaxDepositAmount( );
        calculateMaxWithdrawAmount( );
    }

     /**
     * @dev  Validate the deposit requests of users by the manager.
     * @param _users the addresses of users.
     */
    function validateDeposits( address[] memory _users) external 
        whenNotPaused onlyManager {
        uint256 _amountStable;
        uint256 _amountStableTotal = 0;
        uint256 _depositToken;
        uint256 _depositTokenTotal = 0;
        uint256 _feeStable;
        uint256 _feeStableTotal = 0;
        uint256 _tokenIdDeposit;
        require (_users.length > 0, "Formation.Fi: no user");
        for (uint256 i = 0; i < _users.length  ; i++) {
             address _user =_users[i];
            (  , _amountStable, )= deposit.pendingDepositPerAddress(_user);
           
            if (deposit.balanceOf(_user) == 0) {
                continue;
              }
            if (maxDeposit <= _amountStableTotal) {
                break;
             }
             _tokenIdDeposit = deposit.getTokenId(_user);
             _amountStable = Math.min(maxDeposit  - _amountStableTotal ,  _amountStable);
             depositAmountTotal =  depositAmountTotal - _amountStable;
             if (_user == parity) {
             _feeStable =  (_amountStable * depositFeeRateParity) /
              COEFF_SCALE_DECIMALS_F;
             }
             else {
            _feeStable =  (_amountStable * depositFeeRate) /
              COEFF_SCALE_DECIMALS_F;

             }
             _feeStableTotal = _feeStableTotal + _feeStable;
             _depositToken = (( _amountStable - _feeStable) *
             COEFF_SCALE_DECIMALS_P) / tokenPrice;
             if (_user == parity) {
                validatedDepositParityStableAmount  = _amountStable;
                validatedDepositParityTokenAmount  = _depositToken;
             }
             _depositTokenTotal = _depositTokenTotal + _depositToken;
             _amountStableTotal = _amountStableTotal + _amountStable;

             token.mint(_user, _depositToken);
             deposit.updateDepositData( _user,  _tokenIdDeposit, _amountStable, false);
             token.addDeposit(_user,  _depositToken, block.timestamp);
             emit ValidateDeposit( _user, _amountStable, _depositToken);
        }
        maxDeposit = maxDeposit - _amountStableTotal;
        if (_depositTokenTotal > 0){
            tokenPriceMean  = (( tokenTotalSupply * tokenPriceMean) + 
            ( _depositTokenTotal * tokenPrice)) /
            ( tokenTotalSupply + _depositTokenTotal);
            admin.updateTokenPriceMean( tokenPriceMean);
        }
        
        if (admin.managementFeesTime() == 0){
            admin.updateManagementFeeTime(block.timestamp);   
        }
        if ( _feeStableTotal > 0){
           stableToken.safeTransfer( treasury, _feeStableTotal/amountScaleDecimals);
        }
    }

    /**
     * @dev  Validate the withdrawal requests of users by the manager.
     * @param _users the addresses of users.
     */
    function validateWithdrawals(address[] memory _users) external
        whenNotPaused onlyManager {
        uint256 tokensToBurn = 0;
        uint256 _amountLP;
        uint256 _amountStable;
        uint256 _tokenIdWithdraw;
        calculateAcceptedWithdrawalAmount(_users);
        for (uint256 i = 0; i < _users.length; i++) {
            address _user =_users[i];
            ( , _amountLP, )= withdrawal.pendingWithdrawPerAddress(_user);
         
            if (withdrawal.balanceOf(_user) == 0) {
                continue;
            }
            _amountLP = acceptedWithdrawalPerAddress[_user];

            withdrawalAmountTotal = withdrawalAmountTotal - _amountLP ;
            _amountStable = (_amountLP *  tokenPrice) / 
            ( COEFF_SCALE_DECIMALS_P * amountScaleDecimals);

            if (_user == parity) {
               validatedWithdrawalParityStableAmount  =  _amountStable;
               validatedWithdrawalParityTokenAmount = _amountLP;
            }
            stableToken.safeTransfer(_user, _amountStable);
            _tokenIdWithdraw = withdrawal.getTokenId(_user);
            withdrawal.updateWithdrawalData( _user,  _tokenIdWithdraw, _amountLP, false);
            tokensToBurn = tokensToBurn + _amountLP;
            token.updateTokenData(_user, _amountLP);
            delete acceptedWithdrawalPerAddress[_user]; 
            emit ValidateWithdrawal(_user,  _amountLP, _amountStable);
        }
        if ((tokensToBurn) > 0){
           token.burn(address(this), tokensToBurn);
        }
        if (withdrawalAmountTotal == 0){
            withdrawalAmountTotalOld = 0;
        }
    }

    /**
     * @dev  Make a deposit request.
     * @param _user the addresses of the user.
     * @param _amount the deposit amount in Stablecoin.
     */
    function depositRequest(address _user, uint256 _amount) external whenNotPaused {
        require(_amount >= admin.minAmount(), 
        "Formation.Fi: min Amount");
        if (deposit.balanceOf( _user)==0){
            tokenIdDeposit = tokenIdDeposit +1;
            deposit.mint( _user, tokenIdDeposit, _amount);
        }
        else {
            uint256 _tokenIdDeposit = deposit.getTokenId(_user);
            deposit.updateDepositData (_user,  _tokenIdDeposit, _amount, true);
        }
        depositAmountTotal = depositAmountTotal + _amount; 
        stableToken.safeTransferFrom(msg.sender, address(this), _amount/amountScaleDecimals);
        emit DepositRequest(_user, _amount);
    }

    /**
     * @dev  Cancel the deposit request.
     * @param _amount the deposit amount to cancel in Stablecoin.
     */
    function cancelDepositRequest(uint256 _amount) external whenNotPaused cancel {
        uint256 _tokenIdDeposit = deposit.getTokenId(msg.sender);
        require( _tokenIdDeposit > 0, 
        "Formation.Fi: no deposit request"); 
        deposit.updateDepositData(msg.sender,  _tokenIdDeposit, _amount, false);
        depositAmountTotal = depositAmountTotal - _amount; 
        stableToken.safeTransfer(msg.sender, _amount/amountScaleDecimals);
        emit CancelDepositRequest(msg.sender, _amount);      
    }
    
     /**
     * @dev  Make a withdrawal request.
     * @param _amount the withdrawal amount in Token.
     */
    function withdrawRequest(uint256 _amount) external whenNotPaused {
        require ( _amount > 0, "Formation Fi: zero amount");
        require(withdrawal.balanceOf(msg.sender) == 0, "Formation.Fi: request on pending");
        if (msg.sender != parity) {
        require (token.checklWithdrawalRequest(msg.sender, _amount, admin.lockupPeriodUser()),
         "Formation.Fi: locked position");
        }
        tokenIdWithdraw = tokenIdWithdraw +1;
        withdrawal.mint(msg.sender, tokenIdWithdraw, _amount);
        withdrawalAmountTotal = withdrawalAmountTotal + _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        emit WithdrawalRequest(msg.sender, _amount);
         
    }

     /**
     * @dev Cancel the withdrawal request.
     * @param _amount the withdrawal amount in Token.
     */
    function cancelWithdrawalRequest( uint256 _amount) external whenNotPaused {
        require ( _amount > 0, "Formation Fi: zero amount");
        uint256 _tokenIdWithdraw = withdrawal.getTokenId(msg.sender);
        require( _tokenIdWithdraw > 0, 
        "Formation.Fi: no request"); 
        withdrawal.updateWithdrawalData(msg.sender, _tokenIdWithdraw, _amount, false);
        withdrawalAmountTotal = withdrawalAmountTotal - _amount;
        token.transfer(msg.sender, _amount);
        emit CancelWithdrawalRequest(msg.sender, _amount);
    }
    
    /**
     * @dev Send Stablecoins to the SafeHouse by the manager.
     * @param _amount the amount to send.
     */
    function sendToSafeHouse(uint256 _amount) external 
        whenNotPaused onlyManager {
        require( _amount > 0,  "Formation.Fi: zero amount");
        uint256 _scaledAmount = _amount/amountScaleDecimals;
        require(
            stableToken.balanceOf(address(this)) >= _scaledAmount,
            "Formation.Fi: exceeds balance"
        );
        stableToken.safeTransfer(safeHouse, _scaledAmount);
    }
    
     /**
     * @dev update data from Admin contract.
     */
    function updateAdminData() internal { 
        depositFeeRate = admin.depositFeeRate();
        depositFeeRateParity = admin.depositFeeRateParity();
        tokenPrice = admin.tokenPrice();
        tokenPriceMean = admin.tokenPriceMean();
        tokenTotalSupply = token.totalSupply();
        treasury = admin.treasury();
    }
    
    /**
     * @dev Calculate the accepted withdrawal amounts for users.
     * @param _users the addresses of users.
     */
    function calculateAcceptedWithdrawalAmount(address[] memory _users) 
        internal {
        require (_users.length > 0, "Formation.Fi: no user");
        uint256 _amountLP;
        address _user;
        for (uint256 i = 0; i < _users.length; i++) {
            _user = _users[i];
            require( _user!= address(0), "Formation.Fi: zero address");
            ( , _amountLP, )= withdrawal.pendingWithdrawPerAddress(_user);
            if (withdrawal.balanceOf(_user) == 0) {
                continue;
            }
           _amountLP = Math.min((maxWithdrawal * _amountLP)/
           (tokenPrice * withdrawalAmountTotalOld), _amountLP); 
           acceptedWithdrawalPerAddress[_user] = _amountLP;
        }   
    }
    
}
