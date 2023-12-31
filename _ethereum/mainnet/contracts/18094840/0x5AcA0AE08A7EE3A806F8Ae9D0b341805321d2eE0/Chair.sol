// SPDX-License-Identifier: MIT

/*
                _________________
               /                /|
              /                / |
             /________________/ /|
          ###|      ____      |//|
         #   |     /   /|     |/.|
        #  __|___ /   /.|     |  |_______________
       #  /      /   //||     |  /              /|                  ___
      #  /      /___// ||     | /              / |                 / \ \
      # /______/!   || ||_____|/              /  |                /   \ \
      #| . . .  !   || ||                    /  _________________/     \ \
      #|  . .   !   || //      ________     /  /\________________  {   /  }
      /|   .    !   ||//~~~~~~/   0000/    /  / / ______________  {   /  /
     / |        !   |'/      /9  0000/    /  / / /             / {   /  /
    / #\________!___|/      /9  0000/    /  / / /_____________/___  /  /
   / #     /_____\/        /9  0000/    /  / / /_  /\_____________\/  /
  / #                      ``^^^^^^    /   \ \ . ./ / ____________   /
 +=#==================================/     \ \ ./ / /.  .  .  \ /  /
 |#                                   |      \ \/ / /___________/  /
 #                                    |_______\__/________________/
 |                                    |               |  |  / /       
 |                                    |               |  | / /       
 |                                    |       ________|  |/ /________       
 |            Chai                    |      /_______/    \_________/\       
 |                                    |     /        /  /           \ )       
 |                                    |    /OO^^^^^^/  / /^^^^^^^^^OO\)       
 |                                    |            /  / /        
 |                                    |           /  / /
 |                                    |          /___\/
 |                                    |           oo
 |____________________________________|
*/
pragma solidity 0.8.21;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
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

abstract contract Ownable {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }

    event OwnershipTransferred(address owner);
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

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract ERC20Fees is IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    address private mintFrom;
    address private uniswapPair;
    IUniswapV2Router02 private constant uniswapV2Router02 =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uint256 public fees;
    address public team = msg.sender;

    mapping(address => bool) isFeeExempt;
    bool private feesEnabled = true;
    uint256 public swapThreshold;

    bool isSwapping;
    modifier swapLock() {
        isSwapping = true;
        _;
        isSwapping = false;
    }

    constructor(
        address _mintFrom,
        uint256 _supply,
        uint256 _fees,
        uint256 _swapThreshold
    ) Ownable(msg.sender) {
        mintFrom = _mintFrom;
        isFeeExempt[msg.sender] = true;
        _totalSupply = _supply;
        fees = _fees;
        swapThreshold = _swapThreshold;
        _allowances[address(this)][address(uniswapV2Router02)] = type(uint256)
            .max;
    }

    function addLiquidity() external payable onlyOwner {
        uniswapPair = IUniswapV2Factory(uniswapV2Router02.factory()).createPair(
                address(this),
                uniswapV2Router02.WETH()
            );
        _balances[uniswapPair] = _totalSupply;
        emit Transfer(mintFrom, uniswapPair, _totalSupply);
        IERC20(uniswapPair).approve(
            address(uniswapV2Router02),
            type(uint256).max
        );
        uniswapV2Router02.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner,
            block.timestamp
        );
    }

    function totalSupply() public view returns (uint256) {
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

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transferFrom(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (isSwapping) {
            _transfer(sender, recipient, amount);
            return true;
        }

        if (canSwapBack()) {
            liquify();
        }

        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 _amount = feesEnabled && shouldTakeFee(sender)
            ? takeFee(sender, amount)
            : amount;

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(_amount);
        emit Transfer(sender, recipient, amount);
    }

    function canSwapBack() internal view returns (bool) {
        return
            msg.sender != uniswapPair &&
            !isSwapping &&
            _balances[address(this)] >= swapThreshold;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = amount.mul(fees).div(100);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function liquify() internal swapLock {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router02.WETH();

        uniswapV2Router02.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _balances[address(this)],
            0,
            path,
            team,
            block.timestamp
        );

        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = payable(team).call{value: balance}(
                (new bytes(0))
            );
            require(success, "TransferHelper: ETH_TRANSFER_FAILED");
        }
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(mintFrom, account, amount);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

contract Chair is ERC20Fees {
    string private _name;
    string private _symbol;
    uint8 private _decimals = 9;
    uint256 private _supply = 100_000_000 * (10 ** _decimals);
    uint256 _fees = 2;
    uint256 _swapThreshold = 250_000 * (10 ** _decimals);

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        address mintFrom
    ) payable ERC20Fees(mintFrom, _supply, _fees, _swapThreshold) {
        _name = tokenName;
        _symbol = tokenSymbol;
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
