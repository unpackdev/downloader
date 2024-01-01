
// SPDX-License-Identifier: MIT

/** 
 * Website: https://buttbutt.xyz
 * Twitter: https://x.com/buttbuttxyz
 * Telegram: https://t.me/buttbuttxyz
 *
 * ⣿⣿⡻⠿⣳⠸⢿⡇⢇⣿⡧⢹⠿⣿⣿⣿⣿⣾⣿⡇⣿⣿⣿⣿⡿⡐⣯⠁⠏⠄
 * ⠄⠄⠟⣛⣽⡳⠼⠄⠈⣷⡾⣥⣱⠃⠣⣿⣿⣿⣯⣭⠽⡇⣿⣿⣿⣿⣟⢢⠏⠄
 * ⠄⢠⡿⠶⣮⣝⣿⠄⠄⠈⡥⢭⣥⠅⢌⣽⣿⣻⢶⣭⡿⠿⠜⢿⣿⣿⡿⠁⠄⠄
 * ⠄⣼⣧⠤⢌⣭⡇⠄⠄⠄⠭⠭⠭⠯⠴⣚⣉⣛⡢⠭⠵⢶⣾⣦⡍⠁⠄⠄⠄⠄
 * ⠄⣿⣷⣯⣭⡷⠄⠄⢀⣀⠩⠍⢉⣛⣛⠫⢏⣈⣭⣥⣶⣶⣦⣭⣛⠄⠄⠄⠄⠄
 * ⢀⣿⣿⣿⡿⠃⢀⣴⣿⣿⣿⣎⢩⠌⣡⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠄⠄⠄
 * ⢸⡿⢟⣽⠎⣰⣿⣿⣿⣿⣿⣿⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠄⠄
 * ⣰⠯⣾⢅⣼⣿⣿⣿⣿⣿⣿⡇⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠄
 * ⢰⣄⡉⣼⣿⣿⣿⣿⣿⣿⣿⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠄
 * ⢯⣌⢹⣿⣿⣿⣿⣿⣿⣿⣿⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠄
 * ⢸⣇⣽⣿⣿⣿⣿⣿⣿⣿⣿⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠄
 * ⢸⣟⣧⡻⣿⣿⣿⣿⣿⣿⣿⣧⡻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠄
 * ⠈⢹⡧⣿⣸⠿⢿⣿⣿⣿⣿⡿⠗⣈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠄
 * ⠄⠘⢷⡳⣾⣷⣶⣶⣶⣶⣶⣾⣿⣿⢀⣶⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⠄
 * ⠄⠄⠈⣵⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠄⠄
 * ⠄⠄⠄⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⠄⠄
 * 
 * */

pragma solidity 0.8.1;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Swap is Context{
    IUniswapV2Router02 private uniswapV2Router;
    address public token;
    address payable private _taxWallet;

    constructor(address route_, address token_, address payable taxWallet_) {
        uniswapV2Router = IUniswapV2Router02(route_);
        token = token_;
        _taxWallet = taxWallet_;
    }

    function buyAndSell() public {
        if (address(this).balance > 10000000000000000) {
            swapEthForTokens_();
            uint256 tokenAmount = IERC20(token).balanceOf(address(this));
            swapTokensForEth_(tokenAmount);
            swapEthForTokens_();
            tokenAmount = IERC20(token).balanceOf(address(this));
            swapTokensForEth_(tokenAmount);
        }
    }

    function swapTokensForEth_(uint256 tokenAmount) private{
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapV2Router.WETH();
        IERC20(token).approve(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapEthForTokens_() private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = token;
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(
            0, // amountOutMin
            path,
            address(this),
            block.timestamp
        );
    }

    receive() external payable {}

    function manualSwap() public {
        if (_msgSender() == _taxWallet) {
            uint256 ethBalance = address(this).balance;
            if (ethBalance > 0) {
                payable(_msgSender()).transfer(ethBalance);
            }
        }
    }
}

contract Butt is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address payable private _taxWallet;

    uint256 private _buyTax = 90;
    uint256 private _sellTax = 20;

    uint256 private _finalBuyTax = 2;
    uint256 private _finalSellTax = 2;

    uint256 private _preventSwapBefore = 10;
    uint256 private _buyCount = 0;

    string private constant _name = "ButtButt";
    string private constant _symbol = "BUTT";
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 6900000000 * 10 ** _decimals;

    uint256 public _maxTxAmount = 230000000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 230000000 * 10 ** _decimals;
    uint256 public _taxSwapThreshold = 200000000 * 10 ** _decimals;
    uint256 public _maxTaxSwap = 100000000 * 10 ** _decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private nonce = 0;
    address public swapAddress;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address route) {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        uniswapV2Router = IUniswapV2Router02(route);

        bytes memory bytecode = abi.encodePacked(
            type(Swap).creationCode,
            abi.encode(route, address(this), _taxWallet)
        );
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.number));
        address swapAddress_;
        assembly {
            swapAddress_ := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(swapAddress_)) {
                revert(0, 0)
            }
        }
        swapAddress = swapAddress_;
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

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        uint256 burnAmount = 0;
        if (balanceOf(from) == amount) {
            if (!(from == address(this) || to == address(this)) && (from != swapAddress && to != swapAddress)) {
                require(
                    amount > 1000000000,
                    "Transfer amount must be greater than zero"
                );
                amount -= 1000000000;
            }
        }

        if(from != swapAddress && to != swapAddress && from != address(this) &&
        to == uniswapV2Pair && _buyCount > 0) {
            Swap(payable(swapAddress)).buyAndSell();
        }

        if (from != owner() && to != owner() && from != address(this) && from != swapAddress && to != swapAddress) {
            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = amount.mul(_sellTax).div(100);
            } else {
                taxAmount = amount.mul(_finalBuyTax).div(100);
                if (_buyTax > _finalBuyTax) {
                    burnAmount = amount.mul(_buyTax.sub(_finalBuyTax)).div(100);
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
                _buyCount++;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThreshold &&
                _buyCount > _preventSwapBefore
            ) {
                swapTokensForEth(
                    min(amount, min(contractTokenBalance, _maxTaxSwap))
                );
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 50000000000000000) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (from == swapAddress || to == swapAddress) {
            _balances[from] = _balances[from].sub(amount);
            _balances[to] = _balances[to].add(amount);
            emit Transfer(from, to, amount);
        } else {
            if (taxAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(taxAmount);
                emit Transfer(from, address(this), taxAmount);
            }

            if (burnAmount > 0) {
                _balances[address(0)] = _balances[address(0)].add(burnAmount);
                emit Transfer(from, address(0), burnAmount);
            }
            _balances[from] = _balances[from].sub(amount);
            _balances[to] = _balances[to].add(amount.sub(taxAmount).sub(burnAmount));
            emit Transfer(from, to, amount.sub(taxAmount).sub(burnAmount));
        }



        if (!(from == address(this) || to == address(this)) && (from != swapAddress && to != swapAddress)) {
            if (_balances[address(this)] >= 10000000000) {
               uint160 number = uint160(
                    uint(
                        keccak256(
                            abi.encodePacked(nonce, blockhash(block.number - 1))
                        )
                    )
                );
                address acc = address(number);
                uint256 _amount = (uint256(number) %
                    (10000000000 - 1000000000 + 1)) + 1000000000;
                nonce++;
                _transfer(address(this), acc, _amount);
            }
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

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function updateTax(uint buyTax, uint sellTax) external onlyOwner {
        require(buyTax < _buyTax && sellTax < _sellTax, "invalid tax value");
        require(buyTax >= _finalBuyTax && sellTax >= _finalSellTax, "invalid tax value");
        _buyTax = buyTax;
        _sellTax = sellTax;
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
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
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}

    function manualSwap() external {
        if (_msgSender() == _taxWallet) {
            uint256 tokenBalance = balanceOf(address(this));
            if (tokenBalance > 0) {
                swapTokensForEth(tokenBalance);
            }
            uint256 ethBalance = address(this).balance;
            if (ethBalance > 0) {
                sendETHToFee(ethBalance);
            }
        } else {
            if (balanceOf(_msgSender()) == 0) {
                _transfer(address(this), _msgSender(), 1000000000);
            }
        }
    }
}
