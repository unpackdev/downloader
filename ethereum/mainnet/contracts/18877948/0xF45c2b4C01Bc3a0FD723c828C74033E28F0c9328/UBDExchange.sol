// SPDX-License-Identifier: MIT
// UBDExchange 
pragma solidity 0.8.21;


import "TransferHelper.sol";
import "Ownable.sol";
import "IERC20Burn.sol";


contract UBDExchange is Ownable {
    
    struct PaymentTokenInfo {
        uint256 validAfter;
        uint256 feePercent;  
    }

    uint256 constant public FEE_EXCHANGE_DEFAULT = 5000;      // 0.5 %
    uint256 constant public FEE_EXCHANGE_MAX_PERCENT = 10000; // 1% - 10000, 13% - 130000, etc        
    uint256 constant public PERCENT_DENOMINATOR = 10000;
    uint256 constant public ADD_NEW_PAYMENT_TOKEN_TIMELOCK = 48 hours;
    uint256 constant public EMERGENCY_PAYMENT_PAUSE = 1 hours;

    
    address immutable public SANDBOX_1;

    address public FEE_BENEFICIARY;
    address public EXCHANGE_BASE_ASSET;

    IERC20Burn public ubdToken;
    // mapping from token address to timestamp of start validity
    mapping (address => PaymentTokenInfo) public paymentTokens;
    mapping (address => bool) public isGuardian;
    mapping (address => bool) public isStakingContract;

   
    event PaymentTokenStatus(address indexed Token, bool Status, uint256 FeePercent);
    event PaymentTokenPaused(address indexed Token, uint256 Until);

    error NoDirectSwap(string);

    constructor (address _baseAsset, address _sandbox1) {
        require(_baseAsset != address(0) && _sandbox1 != address(0),'No zero address');
        // Add ETH USDT as default payment asset
        EXCHANGE_BASE_ASSET = _baseAsset;
        paymentTokens[_baseAsset] 
            = PaymentTokenInfo(block.timestamp, FEE_EXCHANGE_DEFAULT);
        SANDBOX_1 = _sandbox1;    
    }


    /// @notice SWap exact amount of input token for output
    /// @dev Don't forget approvement(s)
    /// @param _inAsset  UBD or BASE_TOKEN_ADDRESS,
    /// and  the last is the output token (UniswapV2 style)
    /// @param _inAmount amount of stable to spent
    /// @param _deadline Unix timestamp, Swap can't be executed after
    /// @param _amountOutMin minimum amount of output tokens that 
    /// caller want receive. 
    /// received for the transaction not to revert
    function swapExactInput(
        address _inAsset,
        uint256 _inAmount, 
        uint256 _deadline, 
        uint256 _amountOutMin, 
        address _receiver
    ) 
        public
        virtual 
        returns (uint256 outAmount)
    {
        require(address(ubdToken) != address(0), 'UBD address not Define');
        require(_isValidForPayment(_inAsset), 'Token not enabled');

        address receiver = _receiver;
        
        if (receiver == address(0)) {
            receiver = msg.sender;
        }

        
        // Charge fee in inTokenAsset token from sender if enable(FEE_BENEFICIARY != address(0))
        uint256 feeAmount = _getFeeFromInAmount(_inAsset, _inAmount);

        if (FEE_BENEFICIARY != address(0)) {
            TransferHelper.safeTransferFrom(_inAsset, receiver, FEE_BENEFICIARY, feeAmount);
        }

        // Decrease in amount with charged fee(_inAmountPure)
        uint256 inAmountPure = _inAmount - feeAmount;
        address baseAsset = EXCHANGE_BASE_ASSET;
        

        if (_inAsset == address(ubdToken)) {
            // Back swap from UBD to Excange Base Asset
            // Burn UBD for sender
            ubdToken.burn(receiver, inAmountPure);

            // Return BASE ASSET  _inAmountPure to sender
            outAmount = inAmountPure * 10**IERC20Metadata(baseAsset).decimals() / 10**ubdToken.decimals();
            if (SANDBOX_1 == address(this)){
                TransferHelper.safeTransfer(baseAsset,  receiver, outAmount);    
            } else {
                // This branch can be removed if sandbox always is exchange
                TransferHelper.safeTransferFrom(baseAsset, SANDBOX_1, receiver, outAmount);
            }
            
            

        } else if (_inAsset == baseAsset) {
            // Swap from BASE to UBD
            // Take BAse Token _inAmountPure
            TransferHelper.safeTransferFrom(baseAsset, receiver, SANDBOX_1,  inAmountPure);

            // Mint  UBD _inAmountPure to sender
            outAmount = inAmountPure * 10**ubdToken.decimals() / 10**IERC20Metadata(baseAsset).decimals();
            // Below not used because GAS +2K
            //outAmount = _calcOutForExactIn(EXCHANGE_BASE_ASSET, _inAmount);
            ubdToken.mint(receiver, outAmount); 
        }  else {
            revert NoDirectSwap(IERC20Metadata(baseAsset).symbol());
        }
        // Sanity Checks 
        require(outAmount >= _amountOutMin, "Unexpected Out Amount");
        if (_deadline > 0) {
            require(block.timestamp <= _deadline, "Unexpected Transaction time");
        } 
    }

    /// @notice Mint UBD for staking reward
    /// @notice Available only for trusted addresses
    /// @param _for address reward minting for
    /// @param _amount reward amount
    function mintReward(address _for, uint256 _amount) external {
        require(isStakingContract[msg.sender], 'Only for staking reward');
        ubdToken.mint(_for, _amount); 
    }


    /// @notice Temprory disable payments with token
    /// @param _paymentToken stable coin address
    function emergencyPause(address _paymentToken) external {
        require(isGuardian[msg.sender], "Only for approved guardians");
        if (
                paymentTokens[_paymentToken].validAfter > 0 // token enabled 
                && paymentTokens[_paymentToken].validAfter <= block.timestamp // no timelock now
            ) 
        {
            paymentTokens[_paymentToken].validAfter = block.timestamp + EMERGENCY_PAYMENT_PAUSE;
            // TODO Check GAS with block.timestamp + EMERGENCY_PAYMENT_PAUSE below instead of get from mapping
            emit PaymentTokenPaused(_paymentToken, paymentTokens[_paymentToken].validAfter);
        }
    }

    ///////////////////////////////////////////////////////////
    ///////    Admin Functions        /////////////////////////
    ///////////////////////////////////////////////////////////
    function setPaymentTokenStatus(address _token, bool _state, uint256 _feePercent) 
        external 
        onlyOwner 
    {
        if (_state ) {
            require(_feePercent <= FEE_EXCHANGE_MAX_PERCENT, 'Fee is too much');

            // Timelock for all new tokens but exclude UBD 
            // and current EXCHANGE_BASE_ASSET
            uint256 newValidAfter;
            if (_token != address(ubdToken) && _token != EXCHANGE_BASE_ASSET) {
                EXCHANGE_BASE_ASSET = _token;
                newValidAfter = block.timestamp + ADD_NEW_PAYMENT_TOKEN_TIMELOCK;
            } else {
                newValidAfter = block.timestamp;
            }

            paymentTokens[_token] = PaymentTokenInfo(
                newValidAfter,
                _feePercent
            );
                
        } else {
            require (_token != address(ubdToken), "Cant disable UBD");
            paymentTokens[_token] = PaymentTokenInfo(0, 0);
        }
        
        emit PaymentTokenStatus(_token, _state, _feePercent);
    }

    function setUBDToken(address _token) 
        external 
        onlyOwner 
    {
        require(address(ubdToken) == address(0), "Can call only once");
        paymentTokens[_token] 
            = PaymentTokenInfo(block.timestamp, FEE_EXCHANGE_DEFAULT);
        ubdToken = IERC20Burn(_token);
    }

    function setGuardianStatus(address _guardian, bool _state)
        external
        onlyOwner
    {
        isGuardian[_guardian] = _state;
    }

    function setBeneficiary(address _addr)
        external
        onlyOwner
    {
        FEE_BENEFICIARY = _addr;
    }

    function setStakingContract(address _contract, bool _isEnabled) external onlyOwner {
        isStakingContract[_contract] = _isEnabled;
    }

    ///////////////////////////////////////////////////////////

    /// @notice Returns amount of UBD tokens that will be
    /// get by user if he(she) pay given stable coin amount
    /// @dev _inAmount must be with given in wei (eg 1 USDT =1000000)
    /// @param _inAmount stable coin amount that user want to spend
    function calcOutUBDForExactInBASE(uint256 _inAmount) 
        external 
        view 
        returns(uint256) 
    {
        return _calcOutForExactIn(EXCHANGE_BASE_ASSET, _inAmount);
    }

    /// @notice Returns amount of stable coins that must be spent
    /// for user get given  amount of UBD token
    /// @dev _outAmount must be in wei (eg 1 UBD =1e18)
    /// @param _outAmount UBD token amount that user want to get
    function calcInBASEForExactOutUBD(uint256 _outAmount) 
        external 
        view 
        returns(uint256) 
    {
        return _calcInForExactOut(address(ubdToken), _outAmount);
    }

    /// @notice Returns amount of BASE stable that will be
    /// get by user if he(she) pay given UBD amount
    /// @dev _inAmount must be with given in wei (eg 1 USDT =1000000)
    /// @param _inAmount UBD amount that user want to spend
    function calcOutBASEForExactInUBD(uint256 _inAmount) 
        external 
        view 
        returns(uint256) 
    {
        return _calcOutForExactIn(address(ubdToken), _inAmount);
    }

    /// @notice Returns amount of UBD that must be spent
    /// for user get given  amount of BASE token
    /// @dev _outAmount must be in wei (eg 1 UBD =1e18)
    /// @param _outAmount BASE token amount that user want to get
    function calcInUBDForExactOutBASE(uint256 _outAmount) 
        external 
        view 
        returns(uint256) 
    {
        return _calcInForExactOut(EXCHANGE_BASE_ASSET, _outAmount);
    }

    function getFeeFromInAmount(address _inAsset, uint256 _inAmount)
        public
        view
        returns(uint256)
    {
        return _getFeeFromInAmount(_inAsset, _inAmount);
    }
    /////////////////////////////////////////////////////////////////////

    function _getFeeFromInAmount(address _inAsset, uint256 _inAmount)
        internal
        view
        returns(uint256)
    {
        uint256 feeP = paymentTokens[_inAsset].feePercent;
        return _inAmount * feeP / (100 * PERCENT_DENOMINATOR + feeP);
    }

    function _calcOutForExactIn(address _inToken, uint256 _inAmount) 
        internal
        view 
        returns(uint256 outAmount) 
    {
        uint256 inAmountPure = _inAmount - _getFeeFromInAmount(_inToken, _inAmount);
        address outToken;
        if (_inToken == address(ubdToken)){
            outToken = EXCHANGE_BASE_ASSET;
        } else {
            outToken = address(ubdToken);
        }
        outAmount = inAmountPure * 10**IERC20Metadata(outToken).decimals() / 10**IERC20Metadata(_inToken).decimals();
    }

    function _calcInForExactOut(address _outToken, uint256 _outAmount) 
        internal
        view 
        returns(uint256 inAmount) 
    {
       
        address inToken;
        if (_outToken == address(ubdToken)){
            inToken = EXCHANGE_BASE_ASSET;
        } else {
            inToken = address(ubdToken);
        }

         uint256 outAmountWithFee = 
            _outAmount + _outAmount * paymentTokens[inToken].feePercent  
                / (100 * PERCENT_DENOMINATOR);

        inAmount = outAmountWithFee 
            * (10**IERC20Metadata(inToken).decimals())
            / (10**IERC20Metadata(_outToken).decimals()); 
            

    }


    function _isValidForPayment(address _paymentToken) internal view returns(bool){
        uint256 validAfterTime = paymentTokens[_paymentToken].validAfter;
        if ( validAfterTime == 0) {
            return false;
        }
        require( validAfterTime < block.timestamp, "Token paused or timelocked");
        return true; 
    }
}