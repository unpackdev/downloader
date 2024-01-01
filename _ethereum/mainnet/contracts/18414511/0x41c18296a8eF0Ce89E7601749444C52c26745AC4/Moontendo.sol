// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, Ownable, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
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
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Pair {
    
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Moontendo is ERC20 {
    using SafeMath for uint256;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    address public marketingWallet;
    address public eventsWallet;
    address public developmentWallet;
    address public profitShareWallet;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public buyEventsFee = 10;
    uint256 public buyMarketingFee = 10;
    uint256 public buyDevelopmentFee = 25;
    uint256 public buyProfitShareFee = 15;

    uint256 public sellEventsFee = 10;
    uint256 public sellMarketingFee = 10;
    uint256 public sellDevelopmentFee = 25;
    uint256 public sellProfitShareFee = 15;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public maxWalletBalance;
    bool public tradingEnabled = false;

    constructor() ERC20("Moontendo", "$COLOR") {
        marketingWallet = 0xaC29FAF385AfA88303989A3BFcE4148FF675c51e;
        eventsWallet = 0xFb931da2770067f35B4FaDb6a8f120E91Ba997f4;
        profitShareWallet = 0xBe3CD3d2C6C2Af3c09fCA75A9CD8b59F5eC78304;
        developmentWallet = 0x94b025202eE7511209806a44DEa69dbA7Fea9dCa;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[developmentWallet] = true;
        _isExcludedFromFee[eventsWallet] = true;
        _isExcludedFromFee[profitShareWallet] = true;

        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[address(this)] = true;
        _isExcludedFromMaxWallet[marketingWallet] = true;
        _isExcludedFromMaxWallet[developmentWallet] = true;
        _isExcludedFromMaxWallet[eventsWallet] = true;
        _isExcludedFromMaxWallet[profitShareWallet] = true;

        _mint(owner(), 1000000000 * 10 ** decimals());
        maxWalletBalance = (totalSupply() * 3) / 100;
    }

    function includeAndExcludeInWhitelist(
        address account,
        bool value
    ) public onlyOwner {
        _isExcludedFromFee[account] = value;
    }

    function includeAndExcludedFromMaxWallet(
        address account,
        bool value
    ) public onlyOwner {
        _isExcludedFromMaxWallet[account] = value;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromMaxWallet(
        address account
    ) public view returns (bool) {
        return _isExcludedFromMaxWallet[account];
    }

    function setMaxWalletBalance(uint256 maxBalancePercent) external onlyOwner {
        maxWalletBalance = maxBalancePercent * 10 ** decimals();
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function setSellFees(
        uint256 eventsFee,
        uint256 marketingFee,
        uint256 developmentFee,
        uint256 profitShareFee
    ) external onlyOwner {
        sellEventsFee = eventsFee;
        sellMarketingFee = marketingFee;
        sellDevelopmentFee = developmentFee;
        sellProfitShareFee = profitShareFee;
    }

    function setBuyFees(
        uint256 eventsFee,
        uint256 marketingFee,
        uint256 developmentFee,
        uint256 profitShareFee
    ) external onlyOwner {
        buyEventsFee = eventsFee;
        buyMarketingFee = marketingFee;
        buyDevelopmentFee = developmentFee;
        buyProfitShareFee = profitShareFee;
    }

    function setWallets(
        address marketing,
        address events,
        address development,
        address profitShare
    ) external onlyOwner {
        marketingWallet = marketing;
        eventsWallet = events;
        developmentWallet = development;
        profitShare = profitShare;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && !tradingEnabled) {
            require(tradingEnabled, "ERC20: trading is not enabled yet");
        }

        if (
            from != owner() &&
            to != address(this) &&
            to != burnAddress &&
            to != uniswapV2Pair
        ) {
            uint256 currentBalance = balanceOf(to);
            require(
                _isExcludedFromMaxWallet[to] ||
                    (currentBalance + amount <= maxWalletBalance),
                "ERC20: Reached Max wallet holding limit."
            );
        }

        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            super._transfer(from, to, amount);
            takeFee = false;
        } else {
            if (from == uniswapV2Pair) {
                uint256 eventTokens = amount.mul(buyEventsFee).div(1000);
                uint256 marketingTokens = amount.mul(buyMarketingFee).div(1000);
                uint256 developmentTokens = amount.mul(buyDevelopmentFee).div(
                    1000
                );
                uint256 profitShareTokens = amount.mul(buyProfitShareFee).div(
                    1000
                );
                amount = amount.sub(
                    eventTokens.add(marketingTokens).add(developmentTokens).add(
                        profitShareTokens
                    )
                );
                super._transfer(from, eventsWallet, eventTokens);
                super._transfer(from, marketingWallet, marketingTokens);
                super._transfer(from, developmentWallet, developmentTokens);
                super._transfer(from, profitShareWallet, profitShareTokens);
                super._transfer(from, to, amount);
            } else if (to == uniswapV2Pair) {
                uint256 eventTokens = amount.mul(sellEventsFee).div(1000);
                uint256 marketingTokens = amount.mul(sellMarketingFee).div(
                    1000
                );
                uint256 developmentTokens = amount.mul(sellDevelopmentFee).div(
                    1000
                );
                uint256 profitShareTokens = amount.mul(sellProfitShareFee).div(
                    1000
                );
                amount = amount.sub(
                    eventTokens.add(marketingTokens).add(developmentTokens).add(
                        profitShareTokens
                    )
                );
                super._transfer(from, eventsWallet, eventTokens);
                super._transfer(from, marketingWallet, marketingTokens);
                super._transfer(from, developmentWallet, developmentTokens);
                super._transfer(from, profitShareWallet, profitShareTokens);
                super._transfer(from, to, amount);
            } else {
                super._transfer(from, to, amount);
            }
        }
    }

    function airdrop(
        address[] memory wallets,
        uint256[] memory amounts
    ) external onlyOwner {
        require(
            wallets.length == amounts.length,
            "ERC20: Arrays must be the same length"
        );
        require(
            wallets.length <= 200,
            "ERC20: 200 wallets per txn is allowed due to gas limits"
        );
        for (uint i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            uint256 amount = amounts[i] * 10 ** decimals();
            transfer(wallet, amount);
        }
    }
}