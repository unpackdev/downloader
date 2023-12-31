/**
LANDLORD GAME

Twitter: https://twitter.com/LANDLORDgameERC
Telegram: https://t.me/+TiY0nEyim38xZjgx

Realestate owner wants to put his realestate up for rent, so he hires a LANDLORD to take care of the tennants.
LANDLORD pays the owner a cut of the rent he collects.

Every 10 min interval, LANDLORD is switched to the highest bidding LANDLORD (he purchased the most tokens).
During that timeframe, thete is an ongoing bidding war for next interval.
After the interval is over a new LANDLORD is chosen by the criteria of the most token purchased.

If you choose to sell your tokens at any point, your eligibility to collect rent is permanently revoked.

If the highest bidding LANDLORD sells their tokens bidding war restarts.
If there are no LANDLORDs interested, owner collects all the rent on his own.

Rent is paid in token transfer taxes.

Initial taxes are set to 3.5%.
The LANDLORD has all rights to change taxes and rent collection address however he wants (10% max)
Until the new LANDLORD sets everything up taxes are set to default and tax is sent to owner address.

When LANDLORD sets taxes, he has to write the transacrion on etherscan. Taxes are set with one decimal (eg. for 3.5% tax LANDLORD would need to set it to 35 in the contract call) 
**/

// SPDX-License-Identifier: MIT
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

contract LANDLORDGAME is Context, IERC20, Ownable {
    string private constant _name = unicode"LANDLORDGAME";
    string private constant _symbol = unicode"LLG";

    using SafeMath for uint256;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isDisqualified;
    mapping(address => bool) private bots;

    uint256 public _buyTax = 35;
    uint256 public _sellTax = 35;
    uint256 private _ownerLANDLORDSplit = 280;
    uint256 private _openTradingBlock;
    uint256 private _startBlock;
    uint256 public _LANDLORDForBlocks = 50;
    uint256 public _toBeatAmount = 0;
    address payable public _LANDLORD;
    address payable public _LANDLORDToBe;
    address payable public _rentCollector;
    address payable public _propertyOwner;
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000 * 10**_decimals;
    uint256 public _taxSwapThreshold = 1000 * 10**_decimals;
    uint256 public _maxTaxSwap = 20000 * 10**_decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _propertyOwner = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _LANDLORD = payable(_propertyOwner);
        _LANDLORDToBe = payable(_propertyOwner);
        _rentCollector = payable(_propertyOwner);
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

    function getLANDLORD() public view returns (address) {
        return _LANDLORD;
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
        uint256 ownerTaxAmount = 0;
        if (from != _propertyOwner && to != _propertyOwner) {
            taxAmount = amount.mul(_buyTax).div(1000);
            ownerTaxAmount = taxAmount.mul(_ownerLANDLORDSplit).div(1000);
            taxAmount = taxAmount - ownerTaxAmount;

            if (to == uniswapV2Pair && from != _propertyOwner) {
                taxAmount = amount.mul(_sellTax).div(1000);
                ownerTaxAmount = taxAmount.mul(_ownerLANDLORDSplit).div(1000);
                taxAmount = taxAmount - ownerTaxAmount;

                _isDisqualified[msg.sender] = true;

                if (_LANDLORD == msg.sender) {
                    _startBlock = block.number;
                    _toBeatAmount = 0;
                    _LANDLORD = _LANDLORDToBe;
                }
                if (_LANDLORDToBe == msg.sender) {
                    _toBeatAmount = 0;
                    _LANDLORDToBe = _propertyOwner;
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThreshold
            ) {
                swapTokensForEth(
                    min(amount, min(contractTokenBalance, _maxTaxSwap))
                );
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (_startBlock + _LANDLORDForBlocks >= block.number) {
            _toBeatAmount = 0;
            _LANDLORD = _LANDLORDToBe;
            _LANDLORDToBe = _propertyOwner;
            _rentCollector = _propertyOwner;
            _buyTax = 35;
            _sellTax = 35;
            _startBlock = block.number;
        }

        if (
            _toBeatAmount < amount &&
            to != address(uniswapV2Router) &&
            to != uniswapV2Pair &&
            to != address(this) &&
            _isDisqualified[msg.sender] == false
        ) {
            _LANDLORDToBe = payable(to);
            _toBeatAmount = amount;
        }

        if (taxAmount > 0) {
            _balances[_rentCollector] = _balances[_rentCollector].add(
                taxAmount
            );
            _balances[address(this)] = _balances[address(this)].add(
                ownerTaxAmount
            );
            emit Transfer(from, _rentCollector, taxAmount);
            emit Transfer(from, address(this), ownerTaxAmount);
        }
        uint256 amountToReceive = amount.sub(taxAmount.add(ownerTaxAmount));
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amountToReceive);
        emit Transfer(from, to, amountToReceive);
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

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function startLANDLORDGAME() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)).sub(10000),
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
        _startBlock = block.number;
        _openTradingBlock = block.number;
    }

    function sendETHToFee(uint256 amount) private {
        _propertyOwner.transfer(amount);
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function deleteBots(address[] memory notbot) public onlyOwner {
        for (uint256 i = 0; i < notbot.length; i++) {
            bots[notbot[i]] = false;
        }
    }

    function changeFees(
        uint256 _newBuyFee,
        uint256 _newSellFee,
        address payable rentCollector
    ) public {
        require(_msgSender() == _LANDLORD);
        require(
            _newBuyFee >= 0 &&
                _newBuyFee <= 100 &&
                _newSellFee >= 0 &&
                _newSellFee <= 100
        );
        _buyTax = _newBuyFee;
        _sellTax = _newSellFee;
        _rentCollector = rentCollector;
    }

    function evictLANDLORD() public {
        require(_msgSender() == _propertyOwner);
        _LANDLORD = _propertyOwner;
    }

    function changeLANDLORDDuretion(uint256 _forBlocks) public {
        require(_msgSender() == _propertyOwner);
        _LANDLORDForBlocks = _forBlocks;
    }

    function manualSwap() external {
        require(_msgSender() == _propertyOwner);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            _propertyOwner.transfer(ethBalance);
        }
    }

    receive() external payable {}
}