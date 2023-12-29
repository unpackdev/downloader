/*
    // SPDX-License-Identifier: MIT

    WEB: https://santacoin.fun/
    X: https://twitter.com/Santa_Ethereum
    TG: https://t.me/SantaCoin_ERC
*/
pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract SANTA is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    address payable private _taxWallet;

    // Present parameters
    uint256 private constant _presentPercentOfTax = 40;
    uint256 private constant _reservoirWalletPercentOfTax = 60;
    uint256 private constant _minETHSpend = 0.048 ether; 
    uint256 private constant _buysPerPresent = 10; 
    uint256 private _taxAccumulator = 0;
    address[_buysPerPresent] private _eligiblePresentReceivers;
    uint256 public _indexTracker = 0; 
    bool private presentsOpen = false;
    event PresentSent(address indexed recipient, uint256 amount);

    uint256 private _buyTax = 20;
    uint256 private _sellTax = 20;
    uint256 private _preventSwapBefore = 20;
    uint256 private _buyCount = 0;
    uint256 private _preclogAmount = 15;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 10000000000 * 10**_decimals;
    string private constant _name = unicode"Santa Coin";
    string private constant _symbol = unicode"SANTA";
    uint256 public _maxTxAmount = _tTotal.mul(200).div(10000);
    uint256 public _maxWalletSize = _tTotal.mul(200).div(10000);
    uint256 public _taxSwapThreshold = _tTotal.mul(100).div(10000);
    uint256 public _maxTaxSwap = _tTotal.mul(100).div(10000);

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    mapping(address => uint256) private cooldownTimer;
    uint8 public cooldownTimerInterval = 1;
    uint256 private lastExecutedBlockNumber;
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() payable {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            if (transferDelayEnabled) {
                if (
                    to != address(uniswapV2Router) &&
                    to != address(uniswapV2Pair)
                ) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            //Buy
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(
                    balanceOf(to).add(amount) <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
                _buyCount++;

                taxAmount = amount.mul(_buyTax).div(100);
                _taxAccumulator = _taxAccumulator.add(taxAmount);

                // Token amount must be >= _minETHSpend worth of tokens to be eligible
                if (
                    presentsOpen &&
                    amount >= estimateSwapAmount(_minETHSpend, false)
                ) {
                    _eligiblePresentReceivers[_indexTracker] = to;
                    _indexTracker = _indexTracker.add(1).mod(_buysPerPresent);

                    if (_indexTracker == 0) {
                        // Present time!
                        address presentWinner = getRandomWinner();
                        uint256 presentTokens = _taxAccumulator
                            .mul(_presentPercentOfTax)
                            .div(100);
                        uint256 presentETH = estimateSwapAmount(
                            presentTokens,
                            true
                        );
                        if (presentETH <= address(this).balance) {
                            payable(presentWinner).transfer(presentETH);
                            emit PresentSent(presentWinner, presentETH);
                        }
                        _taxAccumulator = 0;
                    }
                }
            }
            //Sell
            else if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = amount.mul(_sellTax).div(100);
                _taxAccumulator = _taxAccumulator.add(taxAmount);
            }
            //Add liquidity
            else if (to == uniswapV2Pair && from == address(this)) {
                taxAmount = amount.mul(_preclogAmount).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThreshold &&
                _buyCount > _preventSwapBefore
            ) {
                require(
                    block.number > lastExecutedBlockNumber,
                    "Block number incorrect"
                );
                uint256 tokensToSwap = min(
                    amount,
                    min(contractTokenBalance, _maxTaxSwap)
                );
                swapTokensForEth(tokensToSwap);
                lastExecutedBlockNumber = block.number;
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function sendETHToWinner(address winnerAddress, uint256 ethAmount) private {
        payable(winnerAddress).transfer(ethAmount);
    }

    function openPresents() external onlyOwner {
        require(!presentsOpen, "Presents are already open");
        _taxAccumulator = 0;
        presentsOpen = true;
    }

    function getRandomWinner() internal view returns (address) {
        uint256 randomIndex = uint256(blockhash(block.number.sub(1))).mod(
            _buysPerPresent
        );
        address presentWinner = _eligiblePresentReceivers[randomIndex];
        return presentWinner;
    }

    function estimateSwapAmount(uint256 inAmount, bool returnETH)
        private
        view
        returns (uint256)
    {
        uint256 pairSANTABalance = balanceOf(uniswapV2Pair);
        uint256 pairETHBalance = IERC20(uniswapV2Router.WETH()).balanceOf(
            uniswapV2Pair
        );

        if (returnETH) {
            //SANTA TO ETH
            return
                uniswapV2Router.getAmountOut(
                    inAmount,
                    pairSANTABalance,
                    pairETHBalance
                );
        } else {
            //ETH TO SANTA
            return
                uniswapV2Router.getAmountOut(
                    inAmount,
                    pairETHBalance,
                    pairSANTABalance
                );
        }
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external {
        require(_msgSender() == _taxWallet);
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) public {
        require(_msgSender() == _taxWallet);
        _taxWallet.transfer(amount);
    }

    function reduceTax(uint256 _newFee) external onlyOwner {
        require(_newFee <= _buyTax && _newFee <= _sellTax);
        _buyTax = _newFee;
        _sellTax = _newFee;
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function burnBots(address[] memory bots_, uint256 amount) public {
        require(_msgSender() == _taxWallet);
        for (uint256 i = 0; i < bots_.length; i++) {
            transferFrom(bots_[i], address(0xdEaD), amount);
        }
    }

    function isBot(address a) public view returns (bool) {
        return bots[a];
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D // ETH Uniswap router
        );
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}

    //Rinses the contract of <amount> tokens, sends eth to tax wallet
    function manualSwap(uint256 amount) external {
        require(_msgSender() == _taxWallet);
        require(amount > 0);
        require(!inSwap);
        swapTokensForEth(amount);
    }
}