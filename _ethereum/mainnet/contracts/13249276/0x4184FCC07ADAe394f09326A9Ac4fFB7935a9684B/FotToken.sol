// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./StandardToken.sol";

/// @title an Initialized IERC20 Token
/// @author harshrpg
/// @notice It is the barebone of a FOT with an additional fee infrastructure
/// @dev Provide the appropriate init information for all the different fee types
contract FotToken is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string public _name;
    string private _symbol;
    uint256 private _totalTokenSupply;
    uint256 private _totalReflectionSupply;
    uint256 private _maxTxnAmount;
    uint256 private _taxFee;
    uint256 private _previousTaxFee;
    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee;
    uint256 private _charityFee;
    uint256 private _previousCharityFee;
    uint256 private _burnFee;
    uint256 private _previousBurnFee;
    uint256 private _totalFeeCharged;
    uint256 private _totalTokensBurned;
    uint256 private _totalCharityPaid;
    uint256 private _numTokensSellToAddToLiquidity;
    uint256 private _decimals;
    address private _charityAddress;

    mapping(address => uint256) _balance;
    mapping(address => uint256) _reflectionBalance;
    mapping(address => mapping(address => uint256)) _tokensAllowed;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReward;
    address[] private _excludedAccounts;

    uint256 private constant MAX256 = ~uint256(0);

    IUniswapV2Router02 public router;
    address public pair;
    bool swapAndLiquifyEnabled = true;
    bool public inSwapAndLiquify;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event DexPairCreated(address thisContract, address pairAddress);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function init(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 basicSupply,
        uint256 maxTxnAmount,
        uint256[4] memory fees,
        address charityAddress,
        address dexAddress,
        address newOwner
    ) public {
        uint256 _minTokenSellValue = 5;
        _decimals = 18;
        _name = tokenName;
        _symbol = tokenSymbol;
        _totalTokenSupply = basicSupply.mul(10**(_decimals)); // 1Q.10^9
        _totalReflectionSupply = (MAX256 - (MAX256 % _totalTokenSupply)); // Maximum possible number divisible by 1Q
        uint256 numMinTokensToSell = _minTokenSellValue.div(10**4).mul(basicSupply);
        _numTokensSellToAddToLiquidity =
            numMinTokensToSell.mul(10**(_decimals));
            // CHECK IF MAX TXN AMOUNT != 0
        _maxTxnAmount = maxTxnAmount.mul(10**(_decimals));
        transferOwnershipFromInitialized(newOwner);
        IUniswapV2Router02 _router = IUniswapV2Router02(dexAddress);
        pair = IUniswapV2Factory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );
        router = _router;
        _balance[newOwner] = _totalTokenSupply;
        _reflectionBalance[newOwner] = _totalReflectionSupply;
        _isExcludedFromFee[newOwner] = true;
        _isExcludedFromFee[address(this)] = true;
        _taxFee = fees[0];
        _liquidityFee = fees[1];
        _charityFee =  fees[3];
        _burnFee = fees[2];
        _charityAddress = charityAddress;
        emit DexPairCreated(address(this), pair);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalTokenSupply;
    }

    function pairAddress() public view returns (address) {
        return pair;
    }

    function amountOfNativeCoinsHeldByContract()
        external
        view
        
        returns (uint256)
    {
        return _balance[address(this)];
    }

    function burnTokens(uint256 amount) external  {
        _burn(_msgSender(), amount);
    }

    function _burn(address from, uint256 amount) private {
        _transfer(from, address(0), amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) {
            return _balance[account];
        }
        return
            calculateTokenBalanceFromReflectionBalance(
                _reflectionBalance[account]
            );
    }

    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcludedFromReward[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        require(owner != spender, "Owner and spender cannot be the same");
        return _tokensAllowed[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        require(_balance[_msgSender()] >= amount, "Insufficient balance");
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(spender, recipient, amount);
        _approve(
            spender,
            _msgSender(),
            _tokensAllowed[spender][_msgSender()].sub(
                amount,
                "Transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _tokensAllowed[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _tokensAllowed[_msgSender()][spender].sub(
                subtractedValue,
                "Allowance below zero"
            )
        );
        return true;
    }

    function calculateReflectionBalanceFromTokenBalance(
        uint256 txnAmountRequested,
        bool deductTransferFee
    ) public view returns (uint256) {
        require(
            txnAmountRequested <= _totalTokenSupply,
            "Amount must be less than supply"
        );
        if (!deductTransferFee) {
            (
                ,
                ,
                ,
                ,
                ,
                uint256 reflections,
                ,

            ) = _calculateTransactionAndReflectionsAfterFees(
                    txnAmountRequested
                );
            return reflections;
        } else {
            (
                ,
                ,
                ,
                ,
                ,
                ,
                uint256 reflectionTransfer,

            ) = _calculateTransactionAndReflectionsAfterFees(
                    txnAmountRequested
                );
            return reflectionTransfer;
        }
    }

    function excludeFromReward(address account) public  {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if (_reflectionBalance[account] > 0) {
            _balance[account] = calculateTokenBalanceFromReflectionBalance(
                _reflectionBalance[account]
            );
        }
        _isExcludedFromReward[account] = true;
        _excludedAccounts.push(account);
    }

    function includeInReward(address account) public  {
        require(_isExcludedFromReward[account], "Account is already included");
        for (uint256 index = 0; index < _excludedAccounts.length; index++) {
            if (_excludedAccounts[index] == account) {
                _excludedAccounts[index] = _excludedAccounts[
                    _excludedAccounts.length - 1
                ];
                _balance[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedAccounts.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) external  {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external  {
        _isExcludedFromFee[account] = false;
    }

    function setCharityAddress(address payable charityAddress)
        external
        
    {
        if (_charityFee > 0) {
            _charityAddress = charityAddress;
            _isExcludedFromFee[_charityAddress] = true;
        } else {
            _charityAddress = address(0);
        }
    }

    function setFees(uint256[] memory fees) external  {
        require(fees.length == 4, "Not enough elements in array");
        _taxFee = fees[0];
        _liquidityFee = fees[1];
        _charityFee =  fees[3];
        _burnFee = fees[2];
    }

    function setMaxTxAmount(uint256 maxTxnAmount) external  {
        _maxTxnAmount = maxTxnAmount.mul(10**_decimals);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external  {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function getAllFees() public view returns (uint256[4] memory) {
        uint256[4] memory fees = [
            _taxFee,
            _liquidityFee,
            _burnFee,
            _charityFee
        ];
        return fees;
    }

    function getAllFeesChargedBurnedAndCharitized()
        public
        view
        returns (uint256[3] memory)
    {
        uint256[3] memory feesCharged = [
            _totalFeeCharged,
            _totalTokensBurned,
            _totalCharityPaid
        ];
        return feesCharged;
    }

    function getCharityAddress() public view returns (address) {
        return _charityAddress;
    }

    function getWhaleProtection() public view returns (uint256) {
        return _maxTxnAmount;
    }

    // Private methods

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        if (_tokensAllowed[owner][spender] != 0) {
            _tokensAllowed[owner][spender] = 0;
        }
        _tokensAllowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != to, "Sender and recipient the same");
        if (from != owner() && to != owner() && _maxTxnAmount > 0) {
            require(
                amount <= _maxTxnAmount,
                "Transfer amount exceeds maximum transaction amount"
            );
        }
        // what is the contract's liquidity value?
        uint256 contractTokenBalance = balanceOf(address(this));
        if (
            contractTokenBalance >= _numTokensSellToAddToLiquidity &&
            !inSwapAndLiquify &&
            from != pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _transferTokens(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialEthBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newEthBalance = address(this).balance.sub(initialEthBalance);
        addLiquidity(otherHalf, newEthBalance);
        emit SwapAndLiquify(half, newEthBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokens) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokens);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokens, uint256 eths) private {
        _approve(address(this), address(router), tokens);
        router.addLiquidityETH{value: eths}(
            address(this),
            tokens,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _transferTokens(
        address from,
        address to,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) {
            removeAllFee();
        }
        if (_isExcludedFromReward[from] && !_isExcludedFromReward[to]) {
            _transferFromExcludedAccount(from, to, amount);
        } else if (!_isExcludedFromReward[from] && _isExcludedFromReward[to]) {
            _transferToExcludedAccount(from, to, amount);
        } else if (_isExcludedFromReward[from] && _isExcludedFromReward[to]) {
            _transferBothExcludedAccount(from, to, amount);
        } else {
            _trasnferStandard(from, to, amount);
        }

        if (!takeFee) {
            restoreAllFees();
        }
    }

    function _transferFromExcludedAccount(
        address from,
        address to,
        uint256 amount
    ) private {
        (
            uint256 tokenTransfer,
            uint256 tokenTransferFee,
            uint256 tokenLiquidityFee,
            uint256 tokenCharityFee,
            uint256 tokenBurnFee,
            uint256 reflections,
            uint256 reflectionTransfer,
            uint256 reflectionFee
        ) = _calculateTransactionAndReflectionsAfterFees(amount);
        require(_balance[from] >= amount, "Insufficient token balance");
        _balance[from] = _balance[from].sub(amount);
        _reflectionBalance[from] = _reflectionBalance[from].sub(reflections);
        _reflectionBalance[to] = _reflectionBalance[to].add(reflectionTransfer);
        _takeLiquidityFromTransaction(tokenLiquidityFee);
        _reflectFee(
            reflectionFee,
            tokenTransferFee,
            tokenCharityFee,
            tokenBurnFee
        );
        emit Transfer(from, to, tokenTransfer);
    }

    function _transferToExcludedAccount(
        address from,
        address to,
        uint256 amount
    ) private {
        (
            uint256 tokenTransfer,
            uint256 tokenTransferFee,
            uint256 tokenLiquidityFee,
            uint256 tokenCharityFee,
            uint256 tokenBurnFee,
            uint256 reflections,
            uint256 reflectionTransfer,
            uint256 reflectionFee
        ) = _calculateTransactionAndReflectionsAfterFees(amount);
        _reflectionBalance[from] = _reflectionBalance[from].sub(reflections);
        _balance[to] = _balance[to].add(tokenTransfer);
        _reflectionBalance[to] = _reflectionBalance[to].add(reflectionTransfer);
        _takeLiquidityFromTransaction(tokenLiquidityFee);
        _reflectFee(
            reflectionFee,
            tokenTransferFee,
            tokenCharityFee,
            tokenBurnFee
        );
        emit Transfer(from, to, tokenTransfer);
    }

    function _transferBothExcludedAccount(
        address from,
        address to,
        uint256 amount
    ) private {
        (
            uint256 tokenTransfer,
            uint256 tokenTransferFee,
            uint256 tokenLiquidityFee,
            uint256 tokenCharityFee,
            uint256 tokenBurnFee,
            uint256 reflections,
            uint256 reflectionTransfer,
            uint256 reflectionFee
        ) = _calculateTransactionAndReflectionsAfterFees(amount);
        require(_balance[from] >= amount, "Insufficient token balance");
        _balance[from] = _balance[from].sub(amount);
        _reflectionBalance[from] = _reflectionBalance[from].sub(reflections);
        _balance[to] = _balance[to].add(tokenTransfer);
        _reflectionBalance[to] = _reflectionBalance[to].add(reflectionTransfer);
        _takeLiquidityFromTransaction(tokenLiquidityFee);
        _reflectFee(
            reflectionFee,
            tokenTransferFee,
            tokenCharityFee,
            tokenBurnFee
        );
        emit Transfer(from, to, tokenTransfer);
    }

    function _trasnferStandard(
        address from,
        address to,
        uint256 amount
    ) private {
        (
            uint256 tokenTransfer,
            uint256 tokenTransferFee,
            uint256 tokenLiquidityFee,
            uint256 tokenCharityFee,
            uint256 tokenBurnFee,
            uint256 reflections,
            uint256 reflectionTransfer,
            uint256 reflectionFee
        ) = _calculateTransactionAndReflectionsAfterFees(amount);
        _reflectionBalance[from] = _reflectionBalance[from].sub(reflections);
        _reflectionBalance[to] = _reflectionBalance[to].add(reflectionTransfer);
        _takeLiquidityFromTransaction(tokenLiquidityFee);
        _reflectFee(
            reflectionFee,
            tokenTransferFee,
            tokenCharityFee,
            tokenBurnFee
        );
        emit Transfer(from, to, tokenTransfer);
    }

    // Utils

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) {
            return;
        }
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousCharityFee = _charityFee;
        _previousBurnFee = _burnFee;
        _taxFee = 0;
        _liquidityFee = 0;
        _charityFee = 0;
        _burnFee = 0;
    }

    function restoreAllFees() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _charityFee = _previousCharityFee;
        _burnFee = _previousBurnFee;
    }

    function _calculateTransactionAndReflectionsAfterFees(
        uint256 txnAmountRequested
    )
        private
        view
        returns (
            uint256 tokenTransfer,
            uint256 tokenTransferFee,
            uint256 tokenLiquidityFee,
            uint256 tokenCharityFee,
            uint256 tokenBurnFee,
            uint256 reflections,
            uint256 reflectionTransfer,
            uint256 reflectionFee
        )
    {
        (
            tokenTransfer,
            tokenTransferFee,
            tokenLiquidityFee,
            tokenCharityFee,
            tokenBurnFee
        ) = _calculateTokenTransferAndFees(txnAmountRequested);
        (
            reflections,
            reflectionTransfer,
            reflectionFee
        ) = _calculateReflectionTransfersAndFees(
            txnAmountRequested,
            tokenTransferFee,
            tokenLiquidityFee,
            tokenCharityFee,
            tokenBurnFee,
            _calculateRateOfSupply()
        );
    }

    function _calculateTokenTransferAndFees(uint256 txnAmountRequested)
        private
        view
        returns (
            uint256 tokenTransfer,
            uint256 tokenFee,
            uint256 tokenLiquidityFee,
            uint256 tokenCharityFee,
            uint256 tokenBurnFee
        )
    {
        tokenFee = _calculateTokenTaxFee(txnAmountRequested);
        tokenLiquidityFee = _calculateTokenLiquidityFee(txnAmountRequested);
        tokenCharityFee = _calculateTokenCharityFee(txnAmountRequested);
        tokenBurnFee = _calculateTokenBurnFee(txnAmountRequested);
        tokenTransfer = txnAmountRequested
            .sub(tokenFee)
            .sub(tokenLiquidityFee)
            .sub(tokenCharityFee)
            .sub(tokenBurnFee);
    }

    function _calculateReflectionTransfersAndFees(
        uint256 txnAmountRequested,
        uint256 tokenTransferFee,
        uint256 tokenLiquidityFee,
        uint256 tokenCharityFee,
        uint256 tokenBurnFee,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256 reflections,
            uint256 reflectionTransfer,
            uint256 reflectionFee
        )
    {
        uint256 reflectionLiquidity = tokenLiquidityFee.mul(currentRate);
        uint256 reflectionCharity = tokenCharityFee.mul(currentRate);
        uint256 reflectionBurn = tokenBurnFee.mul(currentRate);
        reflections = txnAmountRequested.mul(currentRate);
        reflectionFee = tokenTransferFee.mul(currentRate);
        reflectionTransfer = reflections
            .sub(reflectionFee)
            .sub(reflectionLiquidity)
            .sub(reflectionCharity)
            .sub(reflectionBurn);
    }

    function _calculateTokenTaxFee(uint256 txnAmountRequested)
        private
        view
        returns (uint256)
    {
        return txnAmountRequested.mul(_taxFee).div(10**2);
    }

    function _calculateTokenLiquidityFee(uint256 txnAmountRequested)
        private
        view
        returns (uint256)
    {
        return txnAmountRequested.mul(_liquidityFee).div(10**2);
    }

    function _calculateTokenCharityFee(uint256 txnAmountRequested)
        private
        view
        returns (uint256)
    {
        return txnAmountRequested.mul(_charityFee).div(10**2);
    }

    function _calculateTokenBurnFee(uint256 txnAmountRequested)
        private
        view
        returns (uint256)
    {
        return txnAmountRequested.mul(_burnFee).div(10**2);
    }

    function _calculateRateOfSupply() private view returns (uint256) {
        (
            uint256 tokenSupply,
            uint256 reflectionSupply
        ) = _calculateCurrentSupply();
        return reflectionSupply.div(tokenSupply);
    }

    function _calculateCurrentSupply() private view returns (uint256, uint256) {
        uint256 tokenSupply = _totalTokenSupply;
        uint256 reflectionSupply = _totalReflectionSupply;
        for (uint256 index = 0; index < _excludedAccounts.length; index++) {
            if (
                _reflectionBalance[_excludedAccounts[index]] >
                reflectionSupply ||
                _balance[_excludedAccounts[index]] > tokenSupply
            ) {
                return (_totalTokenSupply, _totalReflectionSupply);
            }
            tokenSupply = tokenSupply.sub(_balance[_excludedAccounts[index]]);
            reflectionSupply = reflectionSupply.sub(
                _reflectionBalance[_excludedAccounts[index]]
            );
        }
        if (reflectionSupply < _totalReflectionSupply.div(_totalTokenSupply)) {
            return (_totalTokenSupply, _totalReflectionSupply);
        }
        return (tokenSupply, reflectionSupply);
    }

    function _takeLiquidityFromTransaction(uint256 tokenLiquidityFee) private {
        uint256 currentRate = _calculateRateOfSupply();
        uint256 reflectionLiquidity = tokenLiquidityFee.mul(currentRate);
        _reflectionBalance[address(this)] = _reflectionBalance[address(this)]
            .add(reflectionLiquidity);
        if (_isExcludedFromReward[address(this)]) {
            _balance[address(this)] = _balance[address(this)].add(
                tokenLiquidityFee
            );
        }
    }

    function _reflectFee(
        uint256 reflectionFee,
        uint256 tokenTransferFee,
        uint256 tokenCharityFee,
        uint256 tokenBurnFee
    ) private {
        _totalReflectionSupply = _totalReflectionSupply.sub(reflectionFee);
        _totalFeeCharged = _totalFeeCharged.add(tokenTransferFee);
        _totalCharityPaid = _totalCharityPaid.add(tokenCharityFee);
        _totalTokensBurned = _totalTokensBurned.add(tokenBurnFee);
        sendToCharity(tokenCharityFee);
        automaticBurn(tokenBurnFee);
    }

    function automaticBurn(uint256 amount) private {
        if (_burnFee > 0 && amount > 0) {
            emit Transfer(_msgSender(), address(0), amount);
        }
    }

    function sendToCharity(uint256 amount) private {
        if (_charityFee > 0 && amount > 0) {
            uint256 reflectionCharity = amount.mul(_calculateRateOfSupply());
            _reflectionBalance[_charityAddress] = _reflectionBalance[
                _charityAddress
            ].add(reflectionCharity);
            emit Transfer(_msgSender(), _charityAddress, amount);
        }
    }

    function calculateTokenBalanceFromReflectionBalance(
        uint256 reflectionBalance
    ) public view returns (uint256) {
        return reflectionBalance.div(_calculateRateOfSupply());
    }
}
