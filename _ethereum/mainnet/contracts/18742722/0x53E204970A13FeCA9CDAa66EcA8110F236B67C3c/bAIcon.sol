// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import "./AccessControl.sol";
import "./EnE.sol";
import "./IERC20.sol";
import "./IdexRouter.sol";
import "./IdexFactory.sol";

contract bAIcon is IERC20, AccessControl, EnE {
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping(address => bool) private excludedFromWalletLimits;
    mapping(address => bool) private excludedFromTransactionLimits;
    mapping(address => bool) public excludedFromFees;
    mapping(address=>bool) public isPair;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    //strings
    string private constant _name = 'bAIcon';
    string private constant _symbol = 'bAIcon';

    //uints
    uint private constant InitialSupply= 916_000_000 * 10**_decimals;

    //Tax by divisor of MAXTAXDENOMINATOR
    uint public buyTax = 175;
    uint public sellTax = 175;
    uint public transferTax = 175;

    //taxPct must equal TAX_DENOMINATOR
    uint constant taxPct=10000;
    uint constant TAX_DENOMINATOR=10000;
    uint constant MAXBUYTAXDENOMINATOR=1000;
    uint constant MAXTRANSFERTAXDENOMINATOR=1000;
    uint constant MAXSELLTAXDENOMINATOR=1000;
    //swapTreshold dynamic by LP pair balance
    uint public swapTreshold=6;
    uint private LaunchBlock;
    uint8 private constant _decimals = 18;
    uint256 public maxTransactionAmount;
    uint256 public maxWalletBalance;

    IdexRouter private  _dexRouter;

    //addresses
    address private dexRouter;
    address private _dexPairAddress;
    address constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address private taxWallet;
    address[] private path;

    //bools
    bool public tokenrcvr;
    bool private _isSwappingContractModifier;
    bool public manualSwap;

    //modifiers
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "Not a manager");
        _;
    }

    constructor () {
        _setupRole(MANAGER_ROLE, msg.sender);  // Setting up the manager role
        
        taxWallet = msg.sender;
        dexRouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        _balances[address(this)] = InitialSupply;

        path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        // Setting exclusions
        SetExclusions(
            [msg.sender, dexRouter, address(this)],
            [msg.sender, deadWallet, address(this)],
            [msg.sender, deadWallet, address(this)]
        );
    }

    /**
    * @notice Set tax to receive tokens vs ETH
    * @dev This function is for set tax to receive tokens vs ETH.
    * @param yesNo The status of tax to receive tokens vs ETH.
     */
    function TokenTaxRCVRBool (
        bool yesNo
    ) external onlyManager {
        tokenrcvr = yesNo;
    }

    /** 
    * @notice Set Exclusions
    * @dev This function is for set exclusions.
    * @param feeExclusions The array of address to be excluded from fees.
    * @param walletLimitExclusions The array of address to be excluded from wallet limits.
    * @param transactionLimitExclusions The array of address to be excluded from transaction limits.
     */
    function SetExclusions(
        address[3] memory feeExclusions, 
        address[3] memory walletLimitExclusions, 
        address[3] memory transactionLimitExclusions
    ) internal {
        for (uint256 i = 0; i < feeExclusions.length; ++i) {
            excludedFromFees[feeExclusions[i]] = true;
        }
        for (uint256 i = 0; i < walletLimitExclusions.length; ++i) {
            excludedFromWalletLimits[walletLimitExclusions[i]] = true;
        }
        for (uint256 i = 0; i < transactionLimitExclusions.length; ++i) {
            excludedFromTransactionLimits[transactionLimitExclusions[i]] = true;
        }
    }

    /**
    * @notice Internal function to transfer tokens from one address to another.
     */
    function _transfer(
        address sender, 
        address recipient, 
        uint amount
    ) internal {
        if(sender == address(0)) revert ZeroAddress();
        if(recipient == address(0)) revert ZeroAddress();

        if(excludedFromFees[sender] || excludedFromFees[recipient])
            _feelessTransfer(sender, recipient, amount);
        else {
            require(LaunchBlock>0,"trading not yet enabled");
            _taxedTransfer(sender,recipient,amount);
        }
    }

    /**
    * @notice Transfer amount of tokens with fees.
    * @param sender The address of user to send tokens.
    * @param recipient The address of user to be recieved tokens.
    * @param amount The token amount to transfer.
    */
    function _taxedTransfer(
        address sender, 
        address recipient, 
        uint amount
    ) internal {
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        bool excludedFromWalletLimitsAccount = excludedFromWalletLimits[sender] || excludedFromWalletLimits[recipient];
        bool excludedFromTXNLimitsAccount = excludedFromTransactionLimits[sender] || excludedFromTransactionLimits[recipient];
        if (
            isPair[sender] &&
            !excludedFromWalletLimitsAccount
        ) {
            if(!excludedFromTXNLimitsAccount){
                require(
                amount <= maxTransactionAmount,
                "Transfer amount exceeds the maxTxAmount."
                );
            }
            uint256 contractBalanceRecepient = balanceOf(recipient);
            require(
                contractBalanceRecepient + amount <= maxWalletBalance,
                "Exceeds maximum wallet token amount."
            );
        } else if (
            isPair[recipient] &&
            !excludedFromTXNLimitsAccount
        ) {
            require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }

        bool isBuy=isPair[sender];
        bool isSell=isPair[recipient];
        uint tax;

        if(isSell) {  // in case that sender is dex token pair.
            uint SellTaxDuration=10;
            if(block.number<LaunchBlock+SellTaxDuration){
                tax=_getStartTax();
            } else tax=sellTax;
        }
        else if(isBuy) {    // in case that recieve is dex token pair.
            uint BuyTaxDuration=10;
            if(block.number<LaunchBlock+BuyTaxDuration){
                tax=_getStartTax();
            } else tax=buyTax;
        } else { 
            uint256 contractBalanceRecepient = balanceOf(recipient);
            if(!excludedFromWalletLimitsAccount){
            require(
                contractBalanceRecepient + amount <= maxWalletBalance,
                "Exceeds maximum wallet token amount."
                );
            }
            uint TransferTaxDuration=10;
            if(block.number<LaunchBlock+TransferTaxDuration){
                tax=_getStartTax();
            } else tax=transferTax;
        }

        if((sender!=_dexPairAddress)&&(!manualSwap)&&(!_isSwappingContractModifier))
        _swapContractToken(false);
        uint contractToken=_calculateFee(amount, tax, taxPct);
        uint taxedAmount=amount-contractToken;

        _balances[sender]-=amount;
        _balances[address(this)] += contractToken;
        _balances[recipient]+=taxedAmount;
        
        emit Transfer(sender,recipient,taxedAmount);
    }

    /**
    * @notice Provides start tax to transfer function.
    * @return The tax to calculate fee with.
    */
    function _getStartTax(
    ) internal pure returns (uint){
        uint startTax=3333;
        return startTax;
    }

    /**
    * @notice Calculates fee based of set amounts
    * @param amount The amount to calculate fee on
    * @param tax The tax to calculate fee with
    * @param taxPercent The tax percent to calculate fee with
    */
    function _calculateFee(
        uint amount, 
        uint tax, 
        uint taxPercent
    ) internal pure returns (uint) {
        return (amount*tax*taxPercent) / (TAX_DENOMINATOR*TAX_DENOMINATOR);
    }

    /**
    * @notice Transfer amount of tokens without fees.
    * @dev In feelessTransfer, there isn't limit as well.
    * @param sender The address of user to send tokens.
    * @param recipient The address of user to be recieveid tokens.
    * @param amount The token amount to transfer.
    */
    function _feelessTransfer(
        address sender, 
        address recipient, 
        uint amount
    ) internal {
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _balances[sender]-=amount;
        _balances[recipient]+=amount;
        emit Transfer(sender,recipient,amount);
    }

    /**
    * @notice Swap tokens for eth.
    * @dev This function is for swap tokens for eth.
    * @param newSwapTresholdImpact Set the swap % of LP pair holdings.
     */
    function setSwapTreshold(
        uint newSwapTresholdImpact
    ) external onlyManager{
        require(newSwapTresholdImpact<=15);//Max Impact= 1.5%
        swapTreshold=newSwapTresholdImpact;
        emit SwapThresholdChange(newSwapTresholdImpact);
    }

    /**
    * @notice Set the current taxes. tax must equal TAX_DENOMINATOR. 
    * @notice buy must be less than MAXBUYTAXDENOMINATOR.
    * @notice sell must be less than MAXSELLTAXDENOMINATOR.
    * @notice transfer_ must be less than MAXTRANSFERTAXDENOMINATOR.
    * @dev This function is for set the current taxes.
    * @param buy The buy tax.
    * @param sell The sell tax.
    * @param transfer_ The transfer tax.
     */
    function SetTaxes(
        uint buy, 
        uint sell, 
        uint transfer_
    ) external onlyManager {
        require(
            buy<=MAXBUYTAXDENOMINATOR &&
            sell<=MAXSELLTAXDENOMINATOR &&
            transfer_<=MAXTRANSFERTAXDENOMINATOR,
            "Tax exceeds maxTax"
        );

        buyTax=buy;
        sellTax=sell;
        transferTax=transfer_;
        emit OnSetTaxes(buy, sell, transfer_);
    }

    /**
     * @dev Swaps contract tokens based on various parameters.
     * @param ignoreLimits Whether to ignore the token swap limits.
     */
    function _swapContractToken(
        bool ignoreLimits
    ) internal lockTheSwap {
        uint contractBalance = _balances[address(this)];
        uint totalTax = taxPct;
        uint tokensToSwap = (_balances[_dexPairAddress] * swapTreshold) / 1000;

        if (totalTax == 0) return;

        if (ignoreLimits) {
            tokensToSwap = _balances[address(this)];
        } else if (contractBalance < tokensToSwap) {
            return;
        }

        if (tokensToSwap != 0) {
            if (tokenrcvr) {
                _balances[taxWallet] += tokensToSwap;
                emit Transfer(address(this), taxWallet, tokensToSwap);
            } else {
                _swapTokenForETH(tokensToSwap);
            }
        }
    }

    /**
    * @notice Swap tokens for eth.
    * @dev This function is for swap tokens for eth.
    * @param amount The token amount to swap.
    */
    function _swapTokenForETH(
        uint amount
    ) private {
        _approve(address(this), address(_dexRouter), amount);

        try _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            taxWallet,
            block.timestamp
        ){}
        catch{}
    }

    /**
    * @notice Add initial liquidity to dex.
    * @dev This function is for add liquidity to dex.
     */
    function _addInitLiquidity(
    ) private {
        uint tokenAmount = balanceOf(address(this));
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            tokenAmount,
            0,
            0,
            taxWallet,
            block.timestamp
        );
    }

    /**
    * @notice Get Burned tokens.
    * @dev This function is for get burned tokens.
    */
    function getBurnedTokens(
    ) public view returns(uint) {
        return _balances[address(0xdead)];
    }

    /**
    * @notice Get circulating supply.
    * @dev This function is for get circulating supply.
     */
    function getCirculatingSupply(
    ) public view returns(uint) {
        return InitialSupply-_balances[address(0xdead)];
    }

    /**
    * @notice Set the current Pair.
    * @dev This function is for set the current Pair.
    * @param Pair The pair address.
    * @param Add The status of add or remove.
     */
    function SetPair(
        address Pair, 
        bool Add
    ) internal {
        if(Pair == address(0)) revert ZeroAddress();
        if(Pair == address(_dexPairAddress)) revert PairAddress();    
        require(Pair!=_dexPairAddress,"can't readd pair");
        require(Pair != address(0),"Address should not be 0");
        isPair[Pair]=Add;
        emit NewPairSet(Pair,Add);
    }

    /**
    * @notice Add a pair.
    * @dev This function is for add a pair.
    * @param Pair The pair address.
     */
    function AddPair(
        address Pair
    ) external onlyManager {
        SetPair(Pair,true);
    }

    /**
    * @notice Add a pair.
    * @dev This function is for add a pair.
    * @param Pair The pair address.
     */
    function RemovePair(
        address Pair
    ) external onlyManager {
        SetPair(Pair,false);
    }

    /**
    * @notice Set Manual Swap Mode
    * @dev This function is for set manual swap mode.
    * @param manual The status of manual swap mode.
     */
    function SwitchManualSwap(
        bool manual
    ) external onlyManager {
        manualSwap=manual;
        emit ManualSwapChange(manual);
    }

    /**
    * @notice Swap contract tokens.
    * @dev This function is for swap contract tokens.
    * @param all The status of swap all tokens in contract.
     */
    function SwapContractToken(
        bool all
    ) external onlyManager {
        _swapContractToken(all);
        emit OwnerSwap();
    }

    /**
    * @notice Set a new router address
    * @dev This function is for set a new router address.
    * @param _newdex The new router address.
     */
    function SetNewRouter(
        address _newdex
    ) external onlyManager {
        if(_newdex == address(0)) revert ZeroAddress();
        if(_newdex == address(_dexRouter)) revert SameAddress();
        dexRouter = _newdex;
        emit NewRouterSet(_newdex);
    }

    /**
    * @notice Set new tax receiver wallets.
    * @dev This function is for set new tax receiver wallets.
    * @param NewTaxWallet The new tax wallet address.
     */
    function SetFeeWallets(
        address NewTaxWallet
    ) external onlyManager {
        if (NewTaxWallet == address(0)) revert ZeroAddress();
        taxWallet = NewTaxWallet;
        emit NewFeeWalletSet(
            NewTaxWallet
        );
    }

    /**
    * @notice Set Wallet Limits
    * @dev This function is for set wallet limits.
    * @param walPct The max wallet balance percent.
    * @param txnPct The max transaction amount percent.
     */
    function SetLimits(
        uint256 walPct, 
        uint256 txnPct
    ) external onlyManager {
        require(walPct >= 100, "min 1%");
        require(walPct <= 10000, "max 100%");
        maxWalletBalance = InitialSupply * walPct / 10000;
        emit MaxWalletBalanceUpdated(walPct);

        require(txnPct >= 100, "min 1%");
        require(txnPct <= 10000, "max 100%");
        maxTransactionAmount = InitialSupply * txnPct / 10000;
        emit MaxTransactionAmountUpdated(txnPct);
    }

    /**
    * @notice Set to exclude an address from fees.
    * @dev This function is for set to exclude an address from fees.
    * @param account The address of user to be excluded from fees.
    * @param exclude The status of exclude.
    */
    function ExcludeAccountFromFees(
        address account, 
        bool exclude
    ) external onlyManager {
        if(account == address(0)) revert ZeroAddress();
        if(account == address(this)) revert ContractAddress();
        excludedFromFees[account]=exclude;
        emit ExcludeAccount(account,exclude);
    }

    /**
    * @notice Set to exclude an address from transaction limits.
    * @dev This function is for set to exclude an address from transaction limits.
    * @param account The address of user to be excluded from transaction limits.
    * @param exclude The status of exclude.
    */
    function ExcludedAccountFromTxnLimits(
        address account, 
        bool exclude
    ) external onlyManager {
        if(account == address(0)) revert ZeroAddress();
        excludedFromTransactionLimits[account]=exclude;
        emit ExcludeFromTransactionLimits(account,exclude);
    }

    /** 
    * @notice Set to exclude an address from wallet limits.
    * @dev This function is for set to exclude an address from wallet limits.
    * @param account The address of user to be excluded from wallet limits.
    * @param exclude The status of exclude.
    */
    function ExcludeAccountFromWltLimits(
        address account, 
        bool exclude
    ) external onlyManager {
        if(account == address(0)) revert ZeroAddress();
        excludedFromWalletLimits[account]=exclude;
        emit ExcludeFromWalletLimits(account,exclude);
    }

    /**
    * @notice Used to start trading.
    * @dev This function is for used to start trading.
    */
    function SetupEnableTrading(
    ) external onlyManager{
        require(LaunchBlock==0,"AlreadyLaunched");

        _dexRouter = IdexRouter(dexRouter);
        _dexPairAddress = IdexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        isPair[_dexPairAddress]=true;

        _addInitLiquidity();

        LaunchBlock=block.number;

        maxWalletBalance = InitialSupply * 100 / 10000; // 0.12%
        maxTransactionAmount = InitialSupply * 100 / 10000; // 0.12%
        emit OnEnableTrading();
    }

    receive() external payable {}
    function name() external pure override returns (string memory) {return _name;}
    function symbol() external pure override returns (string memory) {return _symbol;}
    function decimals() external pure override returns (uint8) {return _decimals;}
    function totalSupply() external pure override returns (uint) {return InitialSupply;}
    function balanceOf(address account) public view override returns (uint) {return _balances[account];}
    function isExcludedFromWalletLimits(address account) public view returns(bool) {return excludedFromWalletLimits[account];}
    function isExcludedFromTransferLimits(address account) public view returns(bool) {return excludedFromTransactionLimits[account];}
    
    function transfer(
        address recipient, 
        uint amount
    ) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(
        address _owner, 
        address spender
    ) external view override returns (uint) {
        return _allowances[_owner][spender];
    }
    function approve(
        address spender, 
        uint amount
    ) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(
        address _owner, 
        address spender, 
        uint amount
    ) private {
        if(_owner == address(0)) revert ZeroAddress();
        if(spender == address(0)) revert ZeroAddress();
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    function transferFrom(
        address sender, 
        address recipient, 
        uint amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    function increaseAllowance(
        address spender, 
        uint addedValue
    ) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(
        address spender, 
        uint subtractedValue
    ) external returns (bool) {
        uint currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    /**
    * @notice Used to remove excess ETH from contract
    * @dev This function is for used to remove excess ETH from contract.
    * @param amountPercentage The amount percentage to recover.
     */
    function emergencyETHrecovery(
        uint256 amountPercentage
    ) external onlyManager {
        uint256 amountETH = address(this).balance;
        (bool sent,)=msg.sender.call{value:amountETH * amountPercentage / 100}("");
            sent=true;
        emit RecoverETH();
    }
    
    /**
    * @notice Used to remove excess Tokens from contract
    * @dev This function is for used to remove excess Tokens from contract.
    * @param tokenAddress The token address to recover.
    * @param amountPercentage The amount percentage to recover.
     */
    function emergencyTokenrecovery(
        address tokenAddress, 
        uint256 amountPercentage
    ) external onlyManager {
        if(tokenAddress == address(0)) revert ZeroAddress();
        if(tokenAddress == address(_dexPairAddress)) {
            revert PairAddress();
        }
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenAmount = token.balanceOf(address(this));
        token.transfer(msg.sender, tokenAmount * amountPercentage / 100);

        emit RecoverTokens(tokenAmount);
    }

}
