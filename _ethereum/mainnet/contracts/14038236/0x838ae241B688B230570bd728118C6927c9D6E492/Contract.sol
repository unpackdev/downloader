// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

/**
Inu Capital
Active Defi Farming through Collective Capital Management

we send our regards, respect and love to MCC, ReFi, ACYC, SBC, and all of
our other predecessors.

To those who fork us, we send our best wishes. May your code be error free.

Thus, we enter Elysium. May the Gates Open for Thee

https://inucapital.io
**/

contract InuCapital is Ownable, IERC20 {
    address UNISWAPROUTER = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string private _name = "Inu Capital";
    string private _symbol = "INC";

    uint256 public buyLiquidityFeeBPS = 500;
    uint256 public reflectionFeeBPS = 500;

    uint256 public treasuryFeeBPS = 1300;
    uint256 public dividendFeeBPS = 600;
    uint256 public devFeeBPS = 100;

    uint256 public swapTokensAtAmount = 100000 * (10**18);
    uint256 public lastSwapTime;
    bool swapAllToken = true;

    bool public swapEnabled = true;
    bool public taxEnabled = true;

    uint256 private _totalSupply;
    bool private swapping;

    // dev fund
    address devWallet = address(0xacBE3D24455995E04C49645479CAf8aA3341FeCc);
    // treasury and liquidity wallet
    address treasuryWallet = address(0xA8F656435f632bBEAAA439E7A0f6A7ff96FF11b2);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    event SendDividends(uint256 amount);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    DividendTracker public dividendTracker;
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;

    uint256 public maxTxBPS = 25;
    uint256 public maxWalletBPS = 100;

    bool isOpen = false;

    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    constructor() {
        dividendTracker = new DividendTracker(address(this));

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(UNISWAPROUTER);

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router), true);

        dividendTracker.excludeFromReflections(address(dividendTracker), true);
        dividendTracker.excludeFromReflections(address(this), true);
        dividendTracker.excludeFromReflections(owner(), true);
        dividendTracker.excludeFromReflections(address(_uniswapV2Router), true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(dividendTracker), true);

        excludeFromMaxTx(owner(), true);
        excludeFromMaxTx(address(this), true);
        excludeFromMaxTx(address(dividendTracker), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(dividendTracker), true);

        uint256 amount = 10000000000 * (10**18);
        _totalSupply += amount;
        _balances[owner()] += amount;
        emit Transfer(address(0), owner(), amount);
    }

    receive() external payable {}

    function name() public view returns (string memory) { return _name; }

    function symbol() public view returns (string memory) { return _symbol; }

    function decimals() public pure returns (uint8) { return 18; }

    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "Inu: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "Inu: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function openTrading() external onlyOwner {
        isOpen = true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(
            isOpen ||
                sender == owner() ||
                recipient == owner(),
            "Not Open"
        );

        require(sender != address(0), "Inu: transfer from the zero address");
        require(recipient != address(0), "Inu: transfer to the zero address");

        uint256 _maxTxAmount = (totalSupply() * maxTxBPS) / 10000;
        uint256 _maxWallet = (totalSupply() * maxWalletBPS) / 10000;
        require(
            amount <= _maxTxAmount || _isExcludedFromMaxTx[sender],
            "TX Limit Exceeded"
        );

        if (
            sender != owner() &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != uniswapV2Pair
        ) {
            uint256 currentBalance = balanceOf(recipient);
            require(
                _isExcludedFromMaxWallet[recipient] ||
                    (currentBalance + amount <= _maxWallet)
            );
        }

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "Inu: transfer amount exceeds balance"
        );

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            swapEnabled && // True
            canSwap && // true
            !swapping && // swapping=false !false true
            !automatedMarketMakerPairs[sender] && // no swap on remove liquidity step 1 or DEX buy
            sender != address(uniswapV2Router) && // no swap on remove liquidity step 2
            sender != owner() &&
            recipient != owner()
        ) {
            swapping = true;

            if (!swapAllToken) {
                contractTokenBalance = swapTokensAtAmount;
            }
            _executeSwap(contractTokenBalance);

            lastSwapTime = block.timestamp;
            swapping = false;
        }

        bool takeFee;

        if (
            sender == address(uniswapV2Pair) ||
            recipient == address(uniswapV2Pair)
        ) {
            takeFee = true;
        }

        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }

        if (swapping || !taxEnabled) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees;
            if (sender == address(uniswapV2Pair)) { // buy
              fees = (amount * (buyLiquidityFeeBPS + reflectionFeeBPS)) / 10000;
              uint256 liquidityFee = (amount * buyLiquidityFeeBPS) / 10000;
              uint256 dividendFee = (amount * reflectionFeeBPS) / 10000;
              _executeTransfer(sender, treasuryWallet, liquidityFee);
              _executeTransfer(sender, address(dividendTracker), dividendFee);
              dividendTracker.distributeReflections(dividendFee);
            } else {                                // sell
              fees = (amount * (treasuryFeeBPS + dividendFeeBPS + devFeeBPS)) / 10000;
              _executeTransfer(sender, address(this), fees);
            }
            amount -= fees;
        }

        _executeTransfer(sender, recipient, amount);

        dividendTracker.setBalance(payable(sender), balanceOf(sender));
        dividendTracker.setBalance(payable(recipient), balanceOf(recipient));
    }

    function sendDividends(
        address sender,
        uint256 amount
    ) public onlyOwner
    {
      _executeTransfer(sender, address(dividendTracker), amount);
      dividendTracker.distributeReflections(amount);
    }

    function _executeTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "Inu: transfer from the zero address");
        require(recipient != address(0), "Inu: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "Inu: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "Inu: approve from the zero address");
        require(spender != address(0), "Inu: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function swapTokensForNative(uint256 tokens) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokens);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0, // accept any amount of native
            path,
            address(this),
            block.timestamp
        );
    }

    function _executeSwap(uint256 tokens) private {
        if (tokens <= 0) {
            return;
        }
        swapTokensForNative(tokens);
        uint256 nativeAfterSwap = address(this).balance;

        uint256 tokensTreasury;
        if (address(treasuryWallet) != address(0)) {
          tokensTreasury = (nativeAfterSwap * (treasuryFeeBPS)) / (treasuryFeeBPS + dividendFeeBPS + devFeeBPS);
          if (tokensTreasury > 0) {
            payable(treasuryWallet).transfer(tokensTreasury);
          }
        }

        uint256 tokensDev;
        if (address(devWallet) != address(0)) {
          tokensDev = (nativeAfterSwap * devFeeBPS) / (treasuryFeeBPS + dividendFeeBPS + devFeeBPS);
          if (tokensDev > 0) {
            payable(devWallet).transfer(tokensDev);
          }
        }

        uint256 tokensDividend;
        if (dividendTracker.totalSupply() > 0) {
          tokensDividend = (nativeAfterSwap * dividendFeeBPS) / (treasuryFeeBPS + dividendFeeBPS + devFeeBPS);
          if (tokensDividend > 0) {
              (bool success, ) = address(dividendTracker).call{
                  value: tokensDividend
              }("");
              if (success) {
                  emit SendDividends(tokensDividend);
              }
          }
        }
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Inu: account is already set to requested state"
        );
        _isExcludedFromFees[account] = excluded;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function manualSendDividend(uint256 amount, address holder)
        external
        onlyOwner
    {
        dividendTracker.manualSendDividend(amount, holder);
    }

    function excludeFromDividends(address account, bool excluded)
        public
        onlyOwner
    {
        dividendTracker.excludeFromDividends(account, excluded);
    }

    function isExcludedFromDividends(address account)
        public
        view
        returns (bool)
    {
        return dividendTracker.isExcludedFromDividends(account);
    }

    function setWallet(
        address payable _treasuryWallet,
        address payable _devWallet
    ) external onlyOwner {
        treasuryWallet = _treasuryWallet;
        devWallet = _devWallet;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(pair != uniswapV2Pair, "Inu: DEX pair can not be removed");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function setFee(
        uint256 _reflectionFee,
        uint256 _buyLiquidityFee,
        uint256 _treasuryFee,
        uint256 _dividendFee,
        uint256 _devFee
    ) external onlyOwner {
        reflectionFeeBPS = _reflectionFee;
        buyLiquidityFeeBPS = _buyLiquidityFee;
        treasuryFeeBPS = _treasuryFee;
        dividendFeeBPS = _dividendFee;
        devFeeBPS = _devFee;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Inu: automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        if (value) {
            dividendTracker.excludeFromDividends(pair, true);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "Inu: the router is already set to the new address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function claimDividend() public {
        dividendTracker.processAccount(payable(_msgSender()));
    }

    function claimReflection() public {
        uint256 amount = dividendTracker.processAccountReflection(payable(_msgSender()));
        _executeTransfer(address(dividendTracker), address(_msgSender()), amount);
    }

    function claimAll() public {
        dividendTracker.processAccount(payable(_msgSender()));
        uint256 amount = dividendTracker.processAccountReflection(payable(_msgSender()));
        _executeTransfer(address(dividendTracker), address(_msgSender()), amount);
    }

    function getAccountDividendInfo(address account)
        public
        view
        returns (
          address,
          uint256,
          uint256,
          uint256,
          uint256
        )
    {
        return dividendTracker.getAccountDividendInfo(account);
    }

    function getAccountReflectionInfo(address account)
        public
        view
        returns (
          address,
          uint256,
          uint256,
          uint256,
          uint256
        )
    {
        return dividendTracker.getAccountReflectionInfo(account);
    }

    function getLastClaimTime(address account) public view returns (uint256) {
        return dividendTracker.getLastClaimTime(account);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function setTaxEnabled(bool _enabled) external onlyOwner {
        taxEnabled = _enabled;
    }

    function updateDividendSettings(
        bool _swapEnabled,
        uint256 _swapTokensAtAmount,
        bool _swapAllToken
    ) external onlyOwner {
        swapEnabled = _swapEnabled;
        swapTokensAtAmount = _swapTokensAtAmount;
        swapAllToken = _swapAllToken;
    }

    function setMax(uint256 _maxTxBPS, uint256 _maxWalletBPS) external onlyOwner {
        maxTxBPS = _maxTxBPS;
        maxWalletBPS = _maxWalletBPS;
    }

    function excludeFromMaxTx(address account, bool excluded) public onlyOwner {
        _isExcludedFromMaxTx[account] = excluded;
    }

    function isExcludedFromMaxTx(address account) public view returns (bool) {
        return _isExcludedFromMaxTx[account];
    }

    function excludeFromMaxWallet(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    function isExcludedFromMaxWallet(address account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromMaxWallet[account];
    }

    function rescueToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function rescueETH(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function rescueReflection(uint256 _amount) external onlyOwner {
        _executeTransfer(address(dividendTracker), msg.sender, _amount);
    }

    function investorAirdrop(address[] calldata recipients, uint256 amount) external onlyOwner {
      // thank you investors!
      for (uint256 _i = 0; _i < recipients.length; _i++) {
        transferFrom(msg.sender, recipients[_i], amount);
      }
    }
}

contract DividendTracker is Ownable, IERC20 {
    string private _name = "Inu_DividendTracker";
    string private _symbol = "Inu_DividendTracker";

    uint256 public lastProcessedIndex;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    uint256 private constant magnitude = 2**128;
    uint256 public immutable minTokenBalanceForDividends;
    uint256 private magnifiedDividendPerShare;
    uint256 public totalDividendsDistributed;
    uint256 public totalDividendsWithdrawn;
    uint256 private magnifiedReflectionPerShare;
    uint256 public totalReflectionsDistributed;
    uint256 public totalReflectionsWithdrawn;

    address public tokenAddress;

    struct AccountTracker {
      bool excludedFromDividends;
      bool excludedFromReflections;
      int256 magnifiedDividendCorrections;
      uint256 withdrawnDividends;
      int256 magnifiedReflectionCorrections;
      uint256 withdrawnReflections;
      uint256 lastClaimTimes;
    }

    mapping(address => AccountTracker) public accountTracker;

    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
    event ExcludeFromDividends(address indexed account, bool excluded);
    event ClaimDividend(address indexed account, uint256 amount);

    struct AccountInfo {
        address account;
        uint256 withdrawableDividends;
        uint256 totalDividends;
        uint256 lastClaimTime;
    }

    constructor(address _tokenAddress) {
        minTokenBalanceForDividends = 10000 * (10**18);
        tokenAddress = _tokenAddress;
    }

    receive() external payable {
        distributeDividends();
    }

    function distributeDividends() public payable {
        require(_totalSupply > 0);
        if (msg.value > 0) {
            magnifiedDividendPerShare =
                magnifiedDividendPerShare +
                ((msg.value * magnitude) / _totalSupply);
            emit DividendsDistributed(msg.sender, msg.value);
            totalDividendsDistributed += msg.value;
        }
    }

    function distributeReflections(uint256 amount) public payable {
      require(_totalSupply > 0);
      if (amount > 0) {
          magnifiedReflectionPerShare =
              magnifiedReflectionPerShare +
              ((amount * magnitude) / _totalSupply);
          emit DividendsDistributed(msg.sender, amount);
          totalReflectionsDistributed += amount;
      }
    }

    function setBalance(address payable account, uint256 newBalance)
        external
        onlyOwner
    {
        if (accountTracker[account].excludedFromDividends) {
            return;
        }
        if (newBalance >= minTokenBalanceForDividends) {
            _setBalance(account, newBalance);
        } else {
            _setBalance(account, 0);
        }
    }

    function excludeFromDividends(address account, bool excluded)
        external
        onlyOwner
    {
        require(
            accountTracker[account].excludedFromDividends != excluded,
            "Inu_DividendTracker: account already set to requested state"
        );
        accountTracker[account].excludedFromDividends = excluded;
        if (excluded) {
            _setBalance(account, 0);
        } else {
            uint256 newBalance = IERC20(tokenAddress).balanceOf(account);
            if (newBalance >= minTokenBalanceForDividends) {
                _setBalance(account, newBalance);
            } else {
                _setBalance(account, 0);
            }
        }
        emit ExcludeFromDividends(account, excluded);
    }

    function isExcludedFromDividends(address account)
        public
        view
        returns (bool)
    {
        return accountTracker[account].excludedFromDividends;
    }

    function excludeFromReflections(address account, bool excluded)
        external
        onlyOwner
    {
        require(
            accountTracker[account].excludedFromReflections != excluded,
            "Inu_DividendTracker: account already set to requested state"
        );
        accountTracker[account].excludedFromReflections = excluded;
        if (excluded) {
            _setBalance(account, 0);
        } else {
            uint256 newBalance = IERC20(tokenAddress).balanceOf(account);
            if (newBalance >= minTokenBalanceForDividends) {
                _setBalance(account, newBalance);
            } else {
                _setBalance(account, 0);
            }
        }
        emit ExcludeFromDividends(account, excluded);
    }

    function isExcludedFromReflections(address account)
        public
        view
        returns (bool)
    {
        return accountTracker[account].excludedFromReflections;
    }

    function manualSendDividend(uint256 amount, address holder)
        external
        onlyOwner
    {
        uint256 contractETHBalance = address(this).balance;
        payable(holder).transfer(amount > 0 ? amount : contractETHBalance);
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = _balances[account];
        if (newBalance > currentBalance) {
            uint256 addAmount = newBalance - currentBalance;
            _mint(account, addAmount);
        } else if (newBalance < currentBalance) {
            uint256 subAmount = currentBalance - newBalance;
            _burn(account, subAmount);
        }
    }

    function _mint(address account, uint256 amount) private {
        require(
            account != address(0),
            "Inu_DividendTracker: mint to the zero address"
        );
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        accountTracker[account].magnifiedDividendCorrections =
            accountTracker[account].magnifiedDividendCorrections -
            int256(magnifiedDividendPerShare * amount);
        accountTracker[account].magnifiedReflectionCorrections =
            accountTracker[account].magnifiedReflectionCorrections -
            int256(magnifiedReflectionPerShare * amount);
    }

    function _burn(address account, uint256 amount) private {
        require(
            account != address(0),
            "Inu_DividendTracker: burn from the zero address"
        );
        uint256 accountBalance = _balances[account];
        require(
            accountBalance >= amount,
            "Inu_DividendTracker: burn amount exceeds balance"
        );
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        accountTracker[account].magnifiedDividendCorrections =
            accountTracker[account].magnifiedDividendCorrections +
            int256(magnifiedDividendPerShare * amount);
        accountTracker[account].magnifiedReflectionCorrections =
            accountTracker[account].magnifiedReflectionCorrections -
            int256(magnifiedReflectionPerShare * amount);
    }

    function processAccount(address payable account)
        public
        onlyOwner
        returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);
        if (amount > 0) {
            accountTracker[account].lastClaimTimes = block.timestamp;
            emit ClaimDividend(account, amount);
            return true;
        }
        return false;
    }

    function processAccountReflection(address payable account)
        public
        onlyOwner
        returns (uint256)
    {
        uint256 amount = _withdrawReflectionOfUser(account);
        if (amount > 0) {
            accountTracker[account].lastClaimTimes = block.timestamp;
            emit ClaimDividend(account, amount);
            return amount;
        }
        return amount;
    }

    function _withdrawDividendOfUser(address payable account)
        private
        returns (uint256)
    {
        uint256 _withdrawableDividend = accumulativeDividendOf(account) - accountTracker[account].withdrawnDividends;
        if (_withdrawableDividend > 0) {
            accountTracker[account].withdrawnDividends += _withdrawableDividend;
            totalDividendsWithdrawn += _withdrawableDividend;
            emit DividendWithdrawn(account, _withdrawableDividend);
            (bool success, ) = account.call{
                value: _withdrawableDividend,
                gas: 3000
            }("");
            if (!success) {
                accountTracker[account].withdrawnDividends -= _withdrawableDividend;
                totalDividendsWithdrawn -= _withdrawableDividend;
                return 0;
            }
            return _withdrawableDividend;
        }
        return 0;
    }

    function accumulativeDividendOf(address account)
        public
        view
        returns (uint256)
    {
        int256 a = int256(magnifiedDividendPerShare * balanceOf(account));
        int256 b = accountTracker[account].magnifiedDividendCorrections; // this is an explicit int256 (signed)
        return uint256(a + b) / magnitude;
    }

    function getAccountDividendInfo(address account)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        AccountInfo memory info;
        info.account = account;
        info.withdrawableDividends = accumulativeDividendOf(account) - accountTracker[account].withdrawnDividends;
        info.totalDividends = accumulativeDividendOf(account);
        info.lastClaimTime = accountTracker[account].lastClaimTimes;
        return (
            info.account,
            info.withdrawableDividends,
            info.totalDividends,
            info.lastClaimTime,
            totalDividendsWithdrawn
        );
    }

    function _withdrawReflectionOfUser(address payable account)
        private
        returns (uint256)
    {
        uint256 amount = accumulativeReflectionOf(account) - accountTracker[account].withdrawnReflections;
        if (amount > 0) {
            accountTracker[account].withdrawnReflections += amount;
            totalReflectionsWithdrawn += amount;
            emit DividendWithdrawn(account, amount);
            return amount;
        }
        return 0;
    }

    function accumulativeReflectionOf(address account)
        public
        view
        returns (uint256)
    {
        int256 a = int256(magnifiedReflectionPerShare * balanceOf(account));
        int256 b = accountTracker[account].magnifiedReflectionCorrections; // this is an explicit int256 (signed)
        return uint256(a + b) / magnitude;
    }

    function getAccountReflectionInfo(address account)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        AccountInfo memory info;
        info.account = account;
        info.withdrawableDividends = accumulativeReflectionOf(account) - accountTracker[account].withdrawnReflections;
        info.totalDividends = accumulativeReflectionOf(account);
        info.lastClaimTime = accountTracker[account].lastClaimTimes;
        return (
            info.account,
            info.withdrawableDividends,
            info.totalDividends,
            info.lastClaimTime,
            totalReflectionsWithdrawn
        );
    }

    function getLastClaimTime(address account) public view returns (uint256) {
        return accountTracker[account].lastClaimTimes;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("Inu_DividendTracker: method not implemented");
    }

    function allowance(address, address)
        public
        pure
        override
        returns (uint256)
    {
        revert("Inu_DividendTracker: method not implemented");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("Inu_DividendTracker: method not implemented");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert("Inu_DividendTracker: method not implemented");
    }
}