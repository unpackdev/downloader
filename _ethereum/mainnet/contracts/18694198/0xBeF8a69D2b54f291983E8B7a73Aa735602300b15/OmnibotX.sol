/**
Website:    https://www.omnibotx.io/
TG:         https://t.me/omnibotxsecurity
X:          https://twitter.com/OmniBotX
Whitepaper: https://whitepaper.omnibotx.io/info/
TG Bot:     https://t.me/omnibotx_bot

░█████╗░███╗░░░███╗███╗░░██╗██╗██████╗░░█████╗░████████╗██╗░░██╗
██╔══██╗████╗░████║████╗░██║██║██╔══██╗██╔══██╗╚══██╔══╝╚██╗██╔╝
██║░░██║██╔████╔██║██╔██╗██║██║██████╦╝██║░░██║░░░██║░░░░╚███╔╝░
██║░░██║██║╚██╔╝██║██║╚████║██║██╔══██╗██║░░██║░░░██║░░░░██╔██╗░
╚█████╔╝██║░╚═╝░██║██║░╚███║██║██████╦╝╚█████╔╝░░░██║░░░██╔╝╚██╗
░╚════╝░╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝╚═════╝░░╚════╝░░░░╚═╝░░░╚═╝░░╚═╝

**/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;
pragma experimental ABIEncoderV2;

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
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: INTERNAL TRANSFER_FAILED');
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract OmnibotX is Ownable {
    string private constant _name = unicode"Omnibot X";
    string private constant _symbol = unicode"OMNIX";
    uint256 private constant _totalSupply = 100_000_000 * 1e18;

    uint256 public maxTransactionAmount = _totalSupply / 50;
    uint256 public maxWallet = _totalSupply / 50;
    uint256 public swapTokensAtAmount = (_totalSupply * 2) / 10000;

    address private revWallet;
    address private treasuryWallet;
    address private teamWallet;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint8 public buyTotalFees = 20;
    uint8 public sellTotalFees = 20;

    uint8 public revFee = 50;
    uint8 public treasuryFee = 25;
    uint8 public teamFee = 25;

    bool private swapping;
    bool public limitsInEffect = true;
    bool private launched;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniswapV2Pair;

    constructor() {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), WETH);
        automatedMarketMakerPairs[uniswapV2Pair] = true;

        revWallet = msg.sender;
        treasuryWallet = msg.sender;
        teamWallet = msg.sender;

        setExcludedFromFees(owner(), true);
        setExcludedFromFees(address(this), true);
        setExcludedFromFees(address(0xdead), true);
        setExcludedFromFees(teamWallet, true);
        setExcludedFromFees(revWallet, true);
        setExcludedFromFees(treasuryWallet, true);
        setExcludedFromFees(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, true);

        setExcludedFromMaxTransaction(owner(), true);
        setExcludedFromMaxTransaction(address(uniswapV2Router), true);
        setExcludedFromMaxTransaction(address(this), true);
        setExcludedFromMaxTransaction(address(0xdead), true);
        setExcludedFromMaxTransaction(address(uniswapV2Pair), true);
        setExcludedFromMaxTransaction(teamWallet, true);
        setExcludedFromMaxTransaction(revWallet, true);
        setExcludedFromMaxTransaction(treasuryWallet, true);

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);

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

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        if (!launched && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            revert("Trading not enabled");
        }

        if (limitsInEffect) {
            if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping) {
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTx");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                } else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount,"Sell transfer amount exceeds the maxTx");
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;

        if (canSwap && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 fees = 0;
        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 1000;
            } else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 1000;
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

    function setDistributionFees(uint8 _RevFee, uint8 _TreasuryFee, uint8 _teamFee) external onlyOwner {
        revFee = _RevFee;
        treasuryFee = _TreasuryFee;
        teamFee = _teamFee;
        require((revFee + treasuryFee + teamFee) == 100, "Distribution have to be equal to 100%");
    }

    function setFees(uint8 _buyTotalFees, uint8 _sellTotalFees) external onlyOwner {
        require(_buyTotalFees <= 30, "Buy fees must be less than or equal to 3%");
        require(_sellTotalFees <= 30, "Sell fees must be less than or equal to 3%");
        buyTotalFees = _buyTotalFees;
        sellTotalFees = _sellTotalFees;
    }

    function setExcludedFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function setExcludedFromMaxTransaction(address account, bool excluded) public onlyOwner {
        _isExcludedMaxTransactionAmount[account] = excluded;
    }

    function enableTrade() external onlyOwner {
        require(!launched, "Already launched");
        launched = true;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed");
        automatedMarketMakerPairs[pair] = value;
    }

    function setSwapAtAmount(uint256 newSwapAmount) external onlyOwner {
        require(newSwapAmount >= (totalSupply() * 1) / 100000, "Swap amount cannot be lower than 0.001% of the supply");
        require(newSwapAmount <= (totalSupply() * 5) / 1000, "Swap amount cannot be higher than 0.5% of the supply");
        swapTokensAtAmount = newSwapAmount;
    }

    function setMaxTxnAmount(uint256 newMaxTx) external onlyOwner {
        require(newMaxTx >= ((totalSupply() * 1) / 1000) / 1e18, "Cannot set max transaction lower than 0.1%");
        maxTransactionAmount = newMaxTx * (10**18);
    }

    function setMaxWalletAmount(uint256 newMaxWallet) external onlyOwner {
        require(newMaxWallet >= ((totalSupply() * 1) / 1000) / 1e18, "Cannot set max wallet lower than 0.1%");
        maxWallet = newMaxWallet * (10**18);
    }

    function updateRevWallet(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Address cannot be zero");
        revWallet = newAddress;
    }

    function updateTreasuryWallet(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Address cannot be zero");
        treasuryWallet = newAddress;
    }

    function updateTeamWallet(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Address cannot be zero");
        teamWallet = newAddress;
    }

    function excludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawStuckETH(address addr) external onlyOwner {
        require(addr != address(0), "Invalid address");

        (bool success, ) = addr.call{value: address(this).balance}("");
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

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(swapThreshold, 0, path, address(this), block.timestamp);

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            uint256 ethForRev = (ethBalance * revFee) / 100;
            uint256 ethForTeam = (ethBalance * teamFee) / 100;
            uint256 ethForTreasury = ethBalance - ethForRev - ethForTeam;

            (success, ) = address(teamWallet).call{value: ethForTeam}("");
            (success, ) = address(treasuryWallet).call{value: ethForTreasury}("");
            (success, ) = address(revWallet).call{value: ethForRev}("");

        }
    }
}