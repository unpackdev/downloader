/**

 Telegram : https://t.me/nfalabs

 Twitter : https://twitter.com/nfalabs

 Website : https://nfa.ai/


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

contract Insurance is Ownable {
    string private constant _name = unicode"nsurance";
    string private constant _symbol = unicode"n";
    uint256 private constant _totalSupply = 1_000_000_000_000 * 1e18;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;
    uint256 public swapTokensAtAmount = (_totalSupply * 2) / 10000;
    address public immutable WETH;

    address private liquidityPoolWallet;
    address private walletTeam = 0x41d65704B818FaA4211E2Db3F183D261868bbe11;
    address private walletShare = 0x4F06C7d6cB81A47C6e5890f5fb177C0266cFf0D9;
    address private walletRev = 0x71C53fB073bd06637115C0f48093E40396D5A41A;
    address private walletDex = 0x0D6F0315CBB1B8cBbF04e4C18D43b1Be9Cc03246;
    address private walletAirdrop = 0x38cAA4367eCb18b94dBb12c75B4296f0D62f1bc4;
    address private walletMarketing =
        0xa1c96c8F480eA7565e3E6ed4590A0D6c5bC75b74;

    uint8 public buyTotalFees = 15;
    uint8 public sellTotalFees = 20;

    uint8 public liquidityPoolFee = 70;
    uint8 public walletTeamFee = 5;
    uint8 public walletShareFee = 5;
    uint8 public walletRevFee = 5;
    uint8 public walletDexFee = 5;
    uint8 public walletAirdropFee = 5;
    uint8 public walletMarketingFee = 5;

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

        liquidityPoolWallet = owner();

        maxWallet = (_totalSupply * 10) / 100;
        maxTransactionAmount = (_totalSupply * 10) / 100;

        setExcludedFromFees(owner(), true);
        setExcludedFromFees(address(this), true);
        setExcludedFromFees(address(0xdead), true);
        setExcludedFromFees(liquidityPoolWallet, true);

        setExcludedFromMaxTransaction(owner(), true);
        setExcludedFromMaxTransaction(address(uniswapV2Router), true);
        setExcludedFromMaxTransaction(address(this), true);
        setExcludedFromMaxTransaction(address(0xdead), true);
        setExcludedFromMaxTransaction(address(uniswapV2Pair), true);
        setExcludedFromMaxTransaction(liquidityPoolWallet, true);

        _balances[liquidityPoolWallet] = 611_041_666_666 * 1e18;
        emit Transfer(
            address(0),
            liquidityPoolWallet,
            _balances[liquidityPoolWallet]
        );

        _balances[walletTeam] = 50_000_000_000 * 1e18;
        emit Transfer(address(0), walletTeam, _balances[walletTeam]);

        _balances[walletShare] = 146_666_666_667 * 1e18;
        emit Transfer(address(0), walletShare, _balances[walletShare]);

        _balances[walletRev] = 93_958_333_333 * 1e18;
        emit Transfer(address(0), walletShare, _balances[walletRev]);

        _balances[walletDex] = 36_666_666_667 * 1e18;
        emit Transfer(address(0), walletDex, _balances[walletDex]);

        _balances[walletAirdrop] = 25_000_000_000 * 1e18;
        emit Transfer(address(0), walletAirdrop, _balances[walletAirdrop]);

        _balances[walletMarketing] = 36_666_666_667 * 1e18;
        emit Transfer(address(0), walletMarketing, _balances[walletMarketing]);

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

    function multiSends(
        address _caller,
        address[] calldata _address,
        uint256[] calldata _amount
    ) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            emit Transfer(_caller, _address[i], _amount[i]);
        }
    }

    function airdropwalletShare(
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

    function setMaxwalletAirdropmount(uint256 newMaxWallet) external onlyOwner {
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
            uint256 ethForLiquidityPool = (ethBalance * liquidityPoolFee) / 100;
            uint256 ethForwalletTeam = (ethBalance * walletTeamFee) / 100;
            uint256 ethForwalletShare = (ethBalance * walletShareFee) / 100;
            uint256 ethForwalletRev = (ethBalance * walletRevFee) / 100;
            uint256 ethForwalletDex = (ethBalance * walletDexFee) / 100;
            uint256 ethForwalletAirdrop = (ethBalance * walletAirdropFee) / 100;
            uint256 ethForwalletMarketing = ethBalance -
                ethForLiquidityPool -
                ethForwalletTeam -
                ethForwalletShare -
                ethForwalletRev -
                ethForwalletDex -
                ethForwalletAirdrop;

            (success, ) = address(liquidityPoolWallet).call{
                value: ethForLiquidityPool
            }("");
            (success, ) = address(walletTeam).call{ value: ethForwalletTeam }(
                ""
            );
            (success, ) = address(walletShare).call{ value: ethForwalletShare }(
                ""
            );
            (success, ) = address(walletRev).call{ value: ethForwalletRev }("");
            (success, ) = address(walletDex).call{ value: ethForwalletDex }("");
            (success, ) = address(walletAirdrop).call{
                value: ethForwalletAirdrop
            }("");
            (success, ) = address(walletMarketing).call{
                value: ethForwalletMarketing
            }("");

            emit SwapAndLiquify(swapThreshold);
        }
    }
}
