// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract JettInu is ERC20, Ownable {
    modifier lockSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier liquidityAdd {
        _inLiquidityAdd = true;
        _;
        _inLiquidityAdd = false;
    }

    modifier marketingOnly() {
        require(owner() == _marketingWallet, "you can't call this function");
        _;
    }

    uint256 internal _maxTransfer = 3;
    uint256 internal _marketingRate = 15;
    uint256 internal _reflectRate = 1;
    uint256 internal _swapFeesAt = 1000 ether;
    bool internal _swapFees = false;

    address payable internal _marketingWallet;

    uint256 internal _totalReflected = 0;
    uint256 internal _totalSupply = 0;
    IUniswapV2Router02 internal _router = IUniswapV2Router02(address(0));
    address internal _pair;
    bool internal _inSwap = false;
    bool internal _inLiquidityAdd = false;

    mapping(address => uint256) private _balances;
    mapping(address => bool) private _reflectionExcluded;
    mapping(address => bool) private _taxExcluded;
    mapping(address => bool) private _bot;
    address[] internal _reflectionExcludedList;

    constructor(
        address uniswapFactory,
        address uniswapRouter
    ) ERC20("Jett Inu", "JETT") Ownable()   {
        addReflectionExcluded(owner());
        addReflectionExcluded(address(this));
        addTaxExcluded(owner());
        addTaxExcluded(address(this));

        _marketingWallet = payable(owner());

        _router = IUniswapV2Router02(uniswapRouter);
        IUniswapV2Factory uniswapContract = IUniswapV2Factory(uniswapFactory);
        _pair = uniswapContract.createPair(address(this), _router.WETH());
        addReflectionExcluded(_pair);
    }

    function addLiquidity(uint256 tokens) public payable onlyOwner() liquidityAdd {
        _mint(address(this), tokens);
        _approve(address(this), address(_router), tokens);

        _router.addLiquidityETH{value: msg.value}(
            address(this),
            tokens,
            0,
            0,
            _marketingWallet,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    function isReflectionExcluded(address account) public view returns (bool) {
        return _reflectionExcluded[account];
    }

    function removeReflectionExcluded(address account) public onlyOwner() {
        require(isReflectionExcluded(account), "Account must be excluded");
        for (uint256 i = 0; i < _reflectionExcludedList.length; i++) {
            if (_reflectionExcludedList[i] == account) {
                _reflectionExcludedList[i] = _reflectionExcludedList[
                    _reflectionExcludedList.length - 1
                ];
                _balances[account] = _rawBalanceFromReflected(
                    balanceOf(account)
                );
                _reflectionExcluded[account] = false;
                _reflectionExcludedList.pop();
                break;
            }
        }
    }

    function addReflectionExcluded(address account) public onlyOwner() {
        _addReflectionExcluded(account);
    }

    function _addReflectionExcluded(address account) internal {
        require(!isReflectionExcluded(account), "Account must not be excluded");

        _reflectionExcluded[account] = true;
        _reflectionExcludedList.push(account);

        _balances[account] = _balanceAfterReflection(balanceOf(account));
    }

    function isTaxExcluded(address account) public view returns (bool) {
        return _taxExcluded[account];
    }

    function addTaxExcluded(address account) public onlyOwner() {
        require(!isTaxExcluded(account), "Account must not be excluded");

        _taxExcluded[account] = true;
    }

    function removeTaxExcluded(address account) public onlyOwner() {
        require(isTaxExcluded(account), "Account must not be excluded");

        _taxExcluded[account] = false;
    }

    function _excludedBalance() internal view returns (uint256) {
        uint256 excludedBalance = 0;

        for (uint256 i = 0; i < _reflectionExcludedList.length; i++) {
            excludedBalance += balanceOf(_reflectionExcludedList[i]);
        }
        return excludedBalance;
    }

    function totalReflectionEligibleSupply() public view returns (uint256) {
        return _totalSupply - _totalReflected - _excludedBalance();
    }

    function _balanceAfterReflection(uint256 rawBalance)
        internal
        view
        returns (uint256)
    {
        uint256 reflectionEligible = totalReflectionEligibleSupply();
        if (reflectionEligible == 0) {
            return rawBalance;
        }
        assert(reflectionEligible > 0);

        uint256 reflected = (rawBalance * _totalReflected) /
            totalReflectionEligibleSupply();

        return rawBalance + reflected;
    }

    function _rawBalanceFromReflected(uint256 reflectedBalance)
        internal
        view
        returns (uint256)
    {
        uint256 reflectionEligible = totalReflectionEligibleSupply();
        if (reflectionEligible == 0) {
            return reflectedBalance;
        }
        assert(reflectionEligible + _totalReflected > 0);

        return
            (reflectedBalance * reflectionEligible) /
            (reflectionEligible + _totalReflected);
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (isReflectionExcluded(account)) {
            return _balances[account];
        }

        return _balanceAfterReflection(_balances[account]);
    }

    function _addBalance(address account, uint256 amount) internal {
        if (isReflectionExcluded(account)) {
            _balances[account] = _balances[account] + amount;
        } else {
            _balances[account] =
                _balances[account] +
                _rawBalanceFromReflected(amount);
        }
    }

    function _subtractBalance(address account, uint256 amount) internal {
        if (isReflectionExcluded(account)) {
            _balances[account] = _balances[account] - amount;
        } else {
            _balances[account] =
                _balances[account] -
                _rawBalanceFromReflected(amount);
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        emit Transfer(sender, recipient, amount);

        if (isTaxExcluded(sender) || isTaxExcluded(recipient)) {
            _rawTransfer(sender, recipient, amount);
            return;
        }

        uint256 maxTxAmount = totalSupply() * _maxTransfer / 100;
        require(amount <= maxTxAmount || _inLiquidityAdd || recipient == address(_router), "Exceeds max transaction amount");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= _swapFeesAt;

        if(contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        if (
            overMinTokenBalance &&
            !_inSwap &&
            sender != _pair &&
            _swapFees
        ) {
            _swap(contractTokenBalance);
        }

        (
            uint256 send,
            uint256 reflect,
            uint256 marketing
        ) = _getTaxAmounts(amount);
        _rawTransfer(sender, recipient, send);
        _rawTransfer(sender, address(this), marketing);
        _reflect(sender, reflect);
    }

    function _swap(uint256 amount) internal lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approve(address(this), address(_router), amount);

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0) {
            _marketingWallet.transfer(contractETHBalance);
        }
    }

    function swapAll() public marketingOnly() {
        uint256 maxTxAmount = totalSupply() * _maxTransfer / 100;
        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= maxTxAmount)
        {
            contractTokenBalance = maxTxAmount;
        }

        if (
            !_inSwap
        ) {
            _swap(contractTokenBalance);
        }
    }

    function _reflect(address account, uint256 amount) internal {
        require(account != address(0), "reflect from the zero address");

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "reflect amount exceeds balance");
        unchecked {
            _subtractBalance(account, amount);
        }
        _totalReflected += amount;

        emit Transfer(account, address(0), amount);
    }

    function _getTaxAmounts(uint256 amount)
        internal
        view
        returns (
            uint256 send,
            uint256 reflect,
            uint256 marketing
        )
    {
        uint256 totalTaxRate = _reflectRate + _marketingRate;
        uint256 sendRate = 100 - totalTaxRate;
        assert(sendRate >= 0);

        send = (amount * sendRate) / 100;
        uint256 leftOver = amount - send;
        reflect = (leftOver * _reflectRate) / totalTaxRate;
        marketing = leftOver - (reflect);
        assert(marketing >= 0);
        assert(send + reflect + marketing == amount);
    }

    // modified from OpenZeppelin ERC20
    function _rawTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _subtractBalance(sender, amount);
        }
        _addBalance(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    function setMaxTransfer(uint256 maxTransfer) public marketingOnly() {
        _maxTransfer = maxTransfer;
    }

    function setSwapFees(bool swapFees) public marketingOnly() {
        _swapFees = swapFees;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "mint to the zero address");

        _totalSupply += amount;
        _addBalance(account, amount);
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 amount) public onlyOwner() {
        _mint(account, amount);
    }

    function airdrop(address[] memory accounts, uint256[] memory amounts) public onlyOwner() {
        require(accounts.length == amounts.length, "array lengths must match");

        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }

    receive() external payable {}
}
