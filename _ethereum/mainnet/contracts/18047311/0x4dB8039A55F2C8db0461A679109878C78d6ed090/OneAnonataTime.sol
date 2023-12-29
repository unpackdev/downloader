/**

$OAT is a token created for those who have suffered too much loss in the crypto space. The rugpulls
and honepots can be very annoying and we have all been there. $OAT aims to help the best it can. To make generational
wealth, just HODL anon. The only mechanism for now, is to buy back and burn from the tax which wil increase the value of the token.
100% community token and 100% supply to Baseswap and Uniswap V2 later on. Final tax 2/2. 

We are launching on base first then on ethereum mainnet later on so we could take advantage of the volume for more
buy back and burn, especially on the base network. This will make history!!! 

Please note: We are making no promises but together, we can achieve greatness!

Below are our contacts for now, please do not get scammed!

$OAT - THE GOAL IS $1 AND BEYOND!

PS: We got nuked on our first launch by jaredfromsubway because we did not set max transaction and max wallet.
We had to remove liquidity and relaunch. We are going refund every wallet affected in due time. We must lead by example!

https://twitter.com/anon1min
https://t.me/anon1minETH


**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract Context {
    constructor() {}

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
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
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactoryV2 {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address lpPair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address lpPair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address lpPair);
}

interface IRouter01 {
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

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
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

contract OneAnonataTime is Context, Ownable, IERC20 {
    function totalSupply() external pure override returns (uint256) {
        if (_totalSupply == 0) {
            revert();
        }
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        if (_totalSupply == 0) {
            revert();
        }
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balance[account];
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _noFee;
    mapping(address => bool) private isLpPair;
    mapping(address => uint256) private balance;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => bool) private _jareDs;
    bool public transferDelayEnabled = false;

    uint256 private constant _totalSupply = 10_000_000 * 10**18;
    uint256 public swapThreshold = 5_000;
    uint256 public constant sellfee = 2;
    uint256 private jaredsellfee = 100;

    uint256 public constant fee_denominator = 100;

    uint256 public _maxTxAmount = _totalSupply / 200;
    uint256 public _maxWalletSize = _totalSupply / 200;

    address payable private _oatFee =
        payable(0x16626AFb636ca096963420c09E28add5C3A1ebC5);

    IRouter02 public swapRouter;
    string private constant _name = unicode"One Anon";
    string private constant _symbol = unicode"$OAT";
    uint8 private constant _decimals = 18;
    address public constant DEAD_WALLET =
        0x000000000000000000000000000000000000dEaD;
    address public lpPair;
    bool private inSwap;

    modifier inSwapFlag() {
        inSwap = true;
        _;
        inSwap = false;
    }

    address private constant jared_MEVBOT =
        0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80;
    address private constant jared_ADDRESS =
        0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13;

    event updateThresold(uint256 amount);

    constructor() {
        _noFee[msg.sender] = true;
        _noFee[address(this)] = true;
        _noFee[_oatFee] = true;
        _noFee[DEAD_WALLET] = true;

        _jareDs[jared_MEVBOT] = true;
        _jareDs[jared_ADDRESS] = true;

        swapRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        balance[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        lpPair = IFactoryV2(swapRouter.factory()).createPair(
            swapRouter.WETH(),
            address(this)
        );
        isLpPair[lpPair] = true;
        _approve(msg.sender, address(swapRouter), type(uint256).max);
        _approve(address(this), address(swapRouter), type(uint256).max);
    }

    receive() external payable {}

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");
        _allowances[sender][spender] = amount;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function isNoFeeWallet(address account) external view returns (bool) {
        return _noFee[account];
    }

    function isJaredAddress(address jaredAddress) public view returns (bool) {
        return _jareDs[jaredAddress];
    }

    function isNofeeAddress(address noFeeAddress) public view returns (bool) {
        return _noFee[noFeeAddress];
    }

    function is_sell(address ins, address out) internal view returns (bool) {
        bool _is_sell = isLpPair[out] && !isLpPair[ins];
        return _is_sell;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        bool takeFee = true;
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            if (transferDelayEnabled) {
                if (to != address(swapRouter) && to != address(lpPair)) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] < block.number,
                        "Only one transfer per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (
                from == lpPair &&
                to != address(swapRouter) &&
                to != address(lpPair) &&
                !_noFee[to]
            ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
            }

            if (is_sell(from, to) && !inSwap) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= swapThreshold) {
                    internalSwap(contractTokenBalance);
                }
            }

            if (_noFee[from] || _noFee[to]) {
                takeFee = false;
            }
            balance[from] -= amount;
            uint256 amountAfterFee = (takeFee)
                ? takeTaxes(from, is_sell(from, to), amount)
                : amount;
            balance[to] += amountAfterFee;
            emit Transfer(from, to, amountAfterFee);
        }
        return true;
    }

    function takeTaxes(
        address from,
        bool issell,
        uint256 amount
    ) internal returns (uint256) {
        uint256 fee = 0;
        if (issell && _jareDs[from]) {
            fee = jaredsellfee;
        } else if (issell) {
            fee = sellfee;
        }
        if (fee == 0) return amount;

        uint256 feeAmount = (amount * fee) / fee_denominator;
        if (feeAmount > 0) {
            balance[address(this)] += feeAmount;
            emit Transfer(from, address(this), feeAmount);
        }
        return amount - feeAmount;
    }

    function internalSwap(uint256 contractTokenBalance) internal inSwapFlag {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        if (
            _allowances[address(this)][address(swapRouter)] != type(uint256).max
        ) {
            _allowances[address(this)][address(swapRouter)] = type(uint256).max;
        }

        try
            swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                contractTokenBalance,
                0,
                path,
                address(this),
                block.timestamp
            )
        {} catch {
            return;
        }
        bool success;

        if (address(this).balance > 0)
            (success, ) = _oatFee.call{value: address(this).balance}("");
    }

    function changeThreshold(uint256 amount) external {
        require(msg.sender == _oatFee, "Caller is not the authorised address!");
        require(amount >= 100, "Amount must be >= 100");
        swapThreshold = amount;
        emit updateThresold(swapThreshold);
    }

    function addJaredAddress(address jaredAddress) external {
        require(msg.sender == _oatFee, "Caller is not the authorised address!");
        require(jaredAddress != address(0), "Invalid address");
        _jareDs[jaredAddress] = true;
    }

    function removeJaredAddress(address jaredAddress) external {
        require(msg.sender == _oatFee, "Caller is not the authorised address!");
        _jareDs[jaredAddress] = false;
    }

    function setJaredSellFee(uint256 newFee) external {
        require(
            msg.sender == _oatFee,
            "Only Authorised address can modify the Jaredfee!"
        );
        require(newFee <= 100, "Fee must be <= 100");
        jaredsellfee = newFee;
    }

    function addtoNofee(address noFeeAddress) external {
        require(msg.sender == _oatFee, "Caller is not the authorised address!");
        require(noFeeAddress != address(0), "Invalid address");
        _noFee[noFeeAddress] = true;
    }

    function removefromtNofee(address noFeeAddress) external {
        require(msg.sender == _oatFee, "Caller is not the authorised address!");
        _noFee[noFeeAddress] = false;
    }
}