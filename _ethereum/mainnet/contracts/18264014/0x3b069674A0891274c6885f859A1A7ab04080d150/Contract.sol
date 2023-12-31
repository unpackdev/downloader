/**


 Telegram : https://t.me/ElysionERC

 Website : https://elysiongame.com/

 X : https://twitter.com/ElysionERC


**/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _owner = address(0);
    }
}

library SafeERC20 {
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: INTERNAL TRANSFER_FAILED"
        );
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external;
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract Elysion is Ownable {
    string private constant _name = unicode"Elysion";
    string private constant _symbol = unicode"ELYSION";
    uint256 private constant _totalSupply = 1_000_000 * 1e18;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;
    uint256 public swapTokensAtAmount = (_totalSupply * 2) / 10000;
    address public immutable WETH;

    address private startLiquidityWallet;
    address private presaleWallet = 0x43F43f7aA6B61fe89E5E87Ca40B97fdFC6F40b79;
    address private developmentWallet =
        0x1F373E564b040E9cFa913ab0BA111df95A3C261a;
    address private contributorWallet =
        0x5df004Bd86a9dC7eA74F5515c49Ce3B5FBe74FFF;
    address private gameEmissionWallet =
        0xbD129B914727Ae7E95714A2a0E4f62b59eaDf37c;
    address private lpFarmIncentiveWallet =
        0xF3CE36b0A707F52a9587C5278b46f70795F2356f;

    uint8 public buyTotalFees = 6;
    uint8 public sellTotalFees = 6;

    uint8 public startLiquidityFee = 10;
    uint8 public presaleFee = 15;
    uint8 public developmentFee = 10;
    uint8 public contributorFee = 10;
    uint8 public gameEmissionFee = 45;
    uint8 public lpFarmIncentiveFee = 10;

    bool private swapping;
    bool public limitsInEffect = true;
    bool private launched;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    event SwapAndLiquify(uint256 tokensSwapped);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    IUniswapV2Router02 public constant uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniswapV2Pair;

    constructor() {
        WETH = uniswapV2Router.WETH();
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            WETH
        );
        automatedMarketMakerPairs[uniswapV2Pair] = true;

        startLiquidityWallet = owner();

        maxWallet = (_totalSupply * 50) / 1000;
        maxTransactionAmount = (_totalSupply * 50) / 1000;

        setExcludedFromFees(owner(), true);
        setExcludedFromFees(address(this), true);
        setExcludedFromFees(address(0xdead), true);
        setExcludedFromFees(startLiquidityWallet, true);
        setExcludedFromFees(presaleWallet, true);
        setExcludedFromFees(developmentWallet, true);
        setExcludedFromFees(contributorWallet, true);
        setExcludedFromFees(gameEmissionWallet, true);
        setExcludedFromFees(lpFarmIncentiveWallet, true);

        setExcludedFromMaxTransaction(owner(), true);
        setExcludedFromMaxTransaction(address(uniswapV2Router), true);
        setExcludedFromMaxTransaction(address(this), true);
        setExcludedFromMaxTransaction(address(0xdead), true);
        setExcludedFromMaxTransaction(address(uniswapV2Pair), true);
        setExcludedFromMaxTransaction(startLiquidityWallet, true);
        setExcludedFromMaxTransaction(presaleWallet, true);
        setExcludedFromMaxTransaction(developmentWallet, true);
        setExcludedFromMaxTransaction(contributorWallet, true);
        setExcludedFromMaxTransaction(gameEmissionWallet, true);
        setExcludedFromMaxTransaction(lpFarmIncentiveWallet, true);

        _balances[startLiquidityWallet] =
            (_totalSupply * startLiquidityFee) /
            100;
        emit Transfer(
            address(0),
            startLiquidityWallet,
            _balances[startLiquidityWallet]
        );

        _balances[presaleWallet] = (_totalSupply * presaleFee) / 100;
        emit Transfer(address(0), presaleWallet, _balances[presaleWallet]);

        _balances[developmentWallet] = (_totalSupply * developmentFee) / 100;
        emit Transfer(
            address(0),
            developmentWallet,
            _balances[developmentWallet]
        );

        _balances[contributorWallet] = (_totalSupply * contributorFee) / 100;
        emit Transfer(
            address(0),
            contributorWallet,
            _balances[contributorWallet]
        );

        _balances[gameEmissionWallet] = (_totalSupply * gameEmissionFee) / 100;
        emit Transfer(
            address(0),
            gameEmissionWallet,
            _balances[gameEmissionWallet]
        );

        _balances[lpFarmIncentiveWallet] =
            (_totalSupply * lpFarmIncentiveFee) /
            100;
        emit Transfer(
            address(0),
            lpFarmIncentiveWallet,
            _balances[lpFarmIncentiveWallet]
        );

        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (
            !launched &&
            (from != owner() && from != address(this) && to != owner())
        ) {
            revert("Trading not enabled");
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTx"
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                } else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTx"
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 senderBalance = _balances[from];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        uint256 fees = 0;
        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 100;
            } else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 100;
            }

            if (fees > 0) {
                unchecked {
                    amount = amount - fees;
                    _balances[from] -= fees;
                    _balances[address(this)] += fees;
                }
                emit Transfer(from, address(this), fees);
            }
        }
        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }

    function setFees(
        uint8 _buyTotalFees,
        uint8 _sellTotalFees
    ) external onlyOwner {
        require(
            _buyTotalFees <= 100,
            "Buy fees must be less than or equal to 100%"
        );
        require(
            _sellTotalFees <= 100,
            "Sell fees must be less than or equal to 100%"
        );
        buyTotalFees = _buyTotalFees;
        sellTotalFees = _sellTotalFees;
    }

    function setExcludedFromFees(
        address account,
        bool excluded
    ) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function setExcludedFromMaxTransaction(
        address account,
        bool excluded
    ) public onlyOwner {
        _isExcludedMaxTransactionAmount[account] = excluded;
    }

    function airdropWallets(
        address[] memory addresses,
        uint256[] memory amounts
    ) external onlyOwner {
        require(!launched, "Already launched");
        for (uint256 i = 0; i < addresses.length; i++) {
            require(
                _balances[msg.sender] >= amounts[i],
                "ERC20: transfer amount exceeds balance"
            );
            _balances[addresses[i]] += amounts[i];
            _balances[msg.sender] -= amounts[i];
            emit Transfer(msg.sender, addresses[i], amounts[i]);
        }
    }

    function openTrading() external onlyOwner {
        require(!launched, "Already launched");
        launched = true;
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed");
        automatedMarketMakerPairs[pair] = value;
    }

    function setSwapAtAmount(uint256 newSwapAmount) external onlyOwner {
        require(
            newSwapAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% of the supply"
        );
        require(
            newSwapAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% of the supply"
        );
        swapTokensAtAmount = newSwapAmount;
    }

    function setMaxTxnAmount(uint256 newMaxTx) external onlyOwner {
        require(
            newMaxTx >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set max transaction lower than 0.1%"
        );
        maxTransactionAmount = newMaxTx * (10 ** 18);
    }

    function setMaxWalletAmount(uint256 newMaxWallet) external onlyOwner {
        require(
            newMaxWallet >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set max wallet lower than 0.1%"
        );
        maxWallet = newMaxWallet * (10 ** 18);
    }

    function excludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawStuckToken(address token, address to) external onlyOwner {
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        SafeERC20.safeTransfer(token, to, _contractBalance); // Use safeTransfer
    }

    function withdrawStuckETH(address addr) external onlyOwner {
        require(addr != address(0), "Invalid address");

        (bool success, ) = addr.call{ value: address(this).balance }("");
        require(success, "Withdrawal failed");
    }

    function swapBack() private {
        uint256 swapThreshold = swapTokensAtAmount;
        bool success;

        if (balanceOf(address(this)) > swapTokensAtAmount * 20) {
            swapThreshold = swapTokensAtAmount * 20;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            uint256 ethForStartLiquidity = (ethBalance * startLiquidityFee) /
                100;
            uint256 ethForSeedSale = (ethBalance * presaleFee) / 100;
            uint256 ethForDashTreasury = (ethBalance * developmentFee) / 100;
            uint256 ethForMarketMaking = (ethBalance * contributorFee) / 100;
            uint256 ethForPartner = (ethBalance * gameEmissionFee) / 100;
            uint256 ethForCommunity = ethBalance -
                ethForStartLiquidity -
                ethForSeedSale -
                ethForDashTreasury -
                contributorFee -
                gameEmissionFee;

            (success, ) = address(startLiquidityWallet).call{
                value: ethForStartLiquidity
            }("");
            (success, ) = address(presaleWallet).call{ value: ethForSeedSale }(
                ""
            );
            (success, ) = address(developmentWallet).call{
                value: ethForDashTreasury
            }("");
            (success, ) = address(contributorWallet).call{
                value: ethForMarketMaking
            }("");
            (success, ) = address(gameEmissionWallet).call{
                value: ethForPartner
            }("");
            (success, ) = address(lpFarmIncentiveWallet).call{
                value: ethForCommunity
            }("");

            emit SwapAndLiquify(swapThreshold);
        }
    }
}
