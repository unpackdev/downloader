// Telegram : https://t.me/OnlyUp_Eth
// Twitter  : https://twitter.com/OnlyUp_eth
// Website  : https://onlyup.money

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IERC20.sol";
import "./Ownable.sol";
import "./IUniswap.sol";

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = _tokenDecimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract OnlyUP is ERC20Detailed, Ownable {
    uint256 public rebaseFrequency = 3 hours;

    uint256 public nextRebase;
    uint256 public finalRebase;

    bool public autoRebase = true;
    bool public rebaseStarted = false;
    uint256 public rebasesThisCycle;
    uint256 public lastRebaseThisCycle;

    uint256 public maxAmount;
    uint256 public maxWallet;

    address public taxWallet;
    uint256 public finalTax = 5;

    uint256 private _initialTax = 25;
    uint256 private _reduceTaxAt = 25;

    uint256 private _buyCount = 0;
    uint256 private _sellCount = 0;

    uint8 private constant DECIMALS = 9;
    uint256 private constant INITIAL_TOKENS_SUPPLY =
        18_000_000_000_000 * 10 ** DECIMALS;

    uint256 private constant FINAL_TOTAL_SUPPLY =
        2_000_000_000 * 10 ** DECIMALS;
    uint256 private constant TOTAL_PARTS =
        type(uint256).max - (type(uint256).max % INITIAL_TOKENS_SUPPLY);

    event Rebase(uint256 indexed time, uint256 totalSupply);
    event RemovedLimits();

    IUniswapRouter public router;
    address public pair;

    bool public limitsInEffect = true;
    bool public tradingEnable = false;

    uint256 private _totalSupply;
    uint256 private _partsPerToken;

    uint256 private partsSwapThreshold = ((TOTAL_PARTS / 100000) * 25);

    mapping(address => uint256) private _partBalances;
    mapping(address => mapping(address => uint256)) private _allowedTokens;
    mapping(address => bool) public isExcludedFromFees;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() ERC20Detailed("Only Up", "OLUP", DECIMALS) {
        taxWallet = msg.sender;

        finalRebase = type(uint256).max;
        nextRebase = type(uint256).max;

        router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _totalSupply = INITIAL_TOKENS_SUPPLY;
        _partBalances[msg.sender] = TOTAL_PARTS;
        _partsPerToken = TOTAL_PARTS / (_totalSupply);

        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[address(router)] = true;
        isExcludedFromFees[msg.sender] = true;

        maxAmount = (_totalSupply * 2) / 100;
        maxWallet = (_totalSupply * 2) / 100;

        pair = IFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        _allowedTokens[address(this)][address(router)] = type(uint256).max;
        _allowedTokens[address(this)][address(this)] = type(uint256).max;
        _allowedTokens[address(msg.sender)][address(router)] = type(uint256)
            .max;

        emit Transfer(
            address(0x0),
            address(msg.sender),
            balanceOf(address(this))
        );
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function allowance(
        address owner_,
        address spender
    ) external view override returns (uint256) {
        return _allowedTokens[owner_][spender];
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _partBalances[who] / (_partsPerToken);
    }

    function shouldRebase() public view returns (bool) {
        return
            nextRebase <= block.timestamp ||
            (autoRebase &&
                rebaseStarted &&
                rebasesThisCycle < 10 &&
                lastRebaseThisCycle + 60 <= block.timestamp);
    }

    function lpSync() internal {
        IPair _pair = IPair(pair);
        _pair.sync();
    }

    function transfer(
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function removeLimits() external onlyOwner {
        require(limitsInEffect, "Limits already removed");
        limitsInEffect = false;
        emit RemovedLimits();
    }

    function excludedFromFees(
        address _address,
        bool _value
    ) external onlyOwner {
        isExcludedFromFees[_address] = _value;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        address pairAddress = pair;

        if (
            !inSwap &&
            !isExcludedFromFees[sender] &&
            !isExcludedFromFees[recipient]
        ) {
            require(tradingEnable, "Trading not live");
            if (limitsInEffect) {
                if (sender == pairAddress || recipient == pairAddress) {
                    require(amount <= maxAmount, "Max Tx Exceeded");
                }
                if (recipient != pairAddress) {
                    require(
                        balanceOf(recipient) + amount <= maxWallet,
                        "Max Wallet Exceeded"
                    );
                }
            }

            if (recipient == pairAddress) {
                if (
                    balanceOf(address(this)) >=
                    partsSwapThreshold / (_partsPerToken)
                ) {
                    try this.swapBack() {} catch {}
                }
                if (shouldRebase()) {
                    rebase();
                }
            }

            uint256 taxAmount;

            if (sender == pairAddress) {
                _buyCount += 1;
                taxAmount =
                    (amount *
                        (_buyCount > _reduceTaxAt ? finalTax : _initialTax)) /
                    100;
            } else if (recipient == pairAddress) {
                _sellCount += 1;
                taxAmount =
                    (amount *
                        (_sellCount > _reduceTaxAt ? finalTax : _initialTax)) /
                    100;
            }

            if (taxAmount > 0) {
                _partBalances[sender] -= (taxAmount * _partsPerToken);
                _partBalances[address(this)] += (taxAmount * _partsPerToken);

                emit Transfer(sender, address(this), taxAmount);
                amount -= taxAmount;
            }
        }

        _partBalances[sender] -= (amount * _partsPerToken);
        _partBalances[recipient] += (amount * _partsPerToken);

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedTokens[from][msg.sender] != type(uint256).max) {
            require(
                _allowedTokens[from][msg.sender] >= value,
                "Insufficient Allowance"
            );
            _allowedTokens[from][msg.sender] =
                _allowedTokens[from][msg.sender] -
                (value);
        }
        _transferFrom(from, to, value);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool) {
        uint256 oldValue = _allowedTokens[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedTokens[msg.sender][spender] = 0;
        } else {
            _allowedTokens[msg.sender][spender] = oldValue - (subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedTokens[msg.sender][spender]);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool) {
        _allowedTokens[msg.sender][spender] =
            _allowedTokens[msg.sender][spender] +
            (addedValue);
        emit Approval(msg.sender, spender, _allowedTokens[msg.sender][spender]);
        return true;
    }

    function approve(
        address spender,
        uint256 value
    ) public override returns (bool) {
        _allowedTokens[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function rebase() internal returns (uint256) {
        uint256 time = block.timestamp;

        uint256 supplyDelta = (_totalSupply * 2) / 100;
        if (nextRebase < block.timestamp) {
            rebasesThisCycle = 1;
            nextRebase += rebaseFrequency;
        } else {
            rebasesThisCycle += 1;
            lastRebaseThisCycle = block.timestamp;
        }

        if (supplyDelta == 0) {
            emit Rebase(time, _totalSupply);
            return _totalSupply;
        }

        _totalSupply = _totalSupply - supplyDelta;

        if (nextRebase >= finalRebase) {
            nextRebase = type(uint256).max;
            autoRebase = false;
            _totalSupply = FINAL_TOTAL_SUPPLY;

            if (limitsInEffect) {
                limitsInEffect = false;
                emit RemovedLimits();
            }

            if (balanceOf(address(this)) > 0) {
                try this.swapBack() {} catch {}
            }
        }

        _partsPerToken = TOTAL_PARTS / (_totalSupply);

        lpSync();

        emit Rebase(time, _totalSupply);

        return _totalSupply;
    }

    function manualRebase() external {
        require(shouldRebase(), "Not in time");
        rebase();
        lpSync();
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnable, "Trading Live Already");
        tradingEnable = true;
    }

    function startRebaseCycles() external onlyOwner {
        require(!rebaseStarted, "already started");
        nextRebase = block.timestamp + rebaseFrequency;
        finalRebase = block.timestamp + 10 days; // 7 days
        rebaseStarted = true;
    }

    function swapBack() public swapping {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > (partsSwapThreshold / (_partsPerToken)) * 20) {
            contractBalance = (partsSwapThreshold / (_partsPerToken)) * 20;
        }

        swapTokensForETH(contractBalance);

        uint256 balance = address(this).balance;

        if (balance > 0) {
            (bool success, ) = payable(taxWallet).call{value: balance}("");
            require(success, "Failed to send ETH to dev wallet");
        }
    }

    function swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount
            path,
            address(taxWallet),
            block.timestamp
        );
    }

    function fetchBalances(address[] memory wallets) external {
        address wallet;
        for (uint256 i = 0; i < wallets.length; i++) {
            wallet = wallets[i];
            emit Transfer(wallet, wallet, 0);
        }
    }

    receive() external payable {}
}
