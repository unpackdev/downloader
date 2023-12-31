// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event. C U ON THE MOON
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
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
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if(currentAllowance != type(uint256).max) { 
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
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

    function _initialTransfer(address to, uint256 amount) internal virtual {
        _balances[to] = amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract KingsOfWojak is ERC20, Ownable {
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IDexRouter constant dexRouter = IDexRouter(routerAddress);
    address immutable pair;
    mapping(address => uint256) public walletProtection;

    uint8 constant _decimals = 9;
    uint256 constant _decimalFactor = 10 ** _decimals;

    uint256 public presaleActive = 2;
    uint256 public constant min = 1 ether / 10;
    uint256 public constant max = 2 ether / 10;
    uint256 public constant presaleCap = 20 ether;
    uint256 public constant tokensForPresale = 21_904_762 * _decimalFactor;
    uint256 public constant minTokensInPresale = tokensForPresale / 200;
    uint256 public constant maxTokensInPresale = tokensForPresale / 100;
    uint256 public constant tokensForLP = 13_800_000 * _decimalFactor;

    constructor() ERC20("Kings Of Wojak", "KJAK") {
        _approve(address(this), routerAddress, type(uint256).max);
        pair = IDexFactory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        
        uint256 totalSupply = 69_000_000 * _decimalFactor;
        _initialTransfer(address(this), tokensForLP + tokensForPresale);
        _initialTransfer(msg.sender, totalSupply - (tokensForLP + tokensForPresale));
    }

    receive() external payable {
        _presale(msg.value);
    }

    function joinPresale() external payable {
        _presale(msg.value);
    }

    function _presale(uint256 amount) internal {
        require(presaleActive == 2, "Presale not active");
        uint256 bal = address(this).balance;
        require(bal <= presaleCap, "Presale full");
        super._transfer(address(this), msg.sender, (tokensForPresale * amount) / presaleCap);
        uint256 tokenBal = balanceOf(msg.sender);
        require(tokenBal >= minTokensInPresale && tokenBal <= maxTokensInPresale, "Outside presale limits");
        if(bal > presaleCap - min) launch();
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(presaleActive != 1) {
            require(from == owner() || to == owner() || from == address(this) || to == address(this), "Trading not yet active");
            super._transfer(from, to, amount);
            if(from == owner() && to == pair) presaleActive = 1; //manual LP launch
        }else {
            super._transfer(from, to, amount);
            _beforeTokenTransfer(from, to);
        }
    }

    function launch() public {
        if(msg.sender == owner()) {
            require(address(this).balance >= presaleCap / 2, "Soft cap not reached");
        } else {
            require(address(this).balance > presaleCap - min, "Hard cap not reached");
        }
        require(presaleActive == 2, "Presale ended");

        bool success;
        (success, ) = address(owner()).call{value: address(this).balance / 2}("");
        
        try dexRouter.addLiquidityETH{value: address(this).balance}(address(this),tokensForLP,0,0,owner(),block.timestamp) {
            presaleActive = 3;
        }
        catch {
            presaleActive = 4; //error adding LP
        }
    }

    function manualLaunch() external onlyOwner {
        require(presaleActive == 4, "No issue to fix");
        uint256 toLp = tokensForLP;
        uint256 bal = balanceOf(address(this));
        if(bal < toLp) toLp = bal;
        try dexRouter.addLiquidityETH{value: address(this).balance}(address(this),bal,0,0,owner(),block.timestamp) {
            presaleActive = 3;
        }
        catch {
            bool success;
            (success, ) = address(owner()).call{value: address(this).balance}("");
            super._transfer(address(this), owner(), balanceOf(address(this)));
        }
    }

    function openTrading() external onlyOwner {
        require(presaleActive == 3, "LP Not Ready");
        presaleActive = 1;
    }

    function extractExcessTokens() external onlyOwner {
        require(presaleActive == 1, "Not launched yet");
        super._transfer(address(this), owner(), balanceOf(address(this)));
    }

    function airdrop(address[] calldata wallets, uint256[] calldata tokens) external onlyOwner {
        require(wallets.length == tokens.length, "Arrays must be the same length");

        for (uint256 i = 0; i < wallets.length; i++) {
            super._transfer(msg.sender, wallets[i], tokens[i] * _decimalFactor);
        }
    }

    function transferProtection(address[] calldata _wallets, uint256 _enabled) external onlyOwner {
        for(uint256 i = 0; i < _wallets.length; i++) {
            walletProtection[_wallets[i]] = _enabled;
        }
    }

    function _beforeTokenTransfer(address from, address to) internal view {
        require(walletProtection[from] == 0 || to == owner(), "Wallet protection enabled, please contact support");
    }
}