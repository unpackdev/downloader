
    // SPDX-License-Identifier: MIT

    /*
        Website: http://milliontoken.net/
        X/Twitter: https://twitter.com/themilliontoken
        Telegram: https://t.me/themilliontoken
    */

    pragma solidity ^0.8.22;

    abstract contract Context {
        function _msgSender() internal view virtual returns (address) {
            return msg.sender;
        }

        function _msgData() internal view virtual returns (bytes calldata) {
            return msg.data;
        }
    }

    interface IERC20 {
        function totalSupply() external view returns (uint256);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address to, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(
            address from,
            address to,
            uint256 amount
        ) external returns (bool);

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }

    interface IERC20Metadata is IERC20 {
        function name() external view returns (string memory);
        function symbol() external view returns (string memory);
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

        function balanceOf(address account) public view virtual override returns (uint256) {
            return _balances[account];
        }

        function transfer(address to, uint256 amount) public virtual override returns (bool) {
            address owner = _msgSender();
            _transfer(owner, to, amount);
            return true;
        }

        function allowance(address owner, address spender) public view virtual override returns (uint256) {
            return _allowances[owner][spender];
        }

        function approve(address spender, uint256 amount) public virtual override returns (bool) {
            address owner = _msgSender();
            _approve(owner, spender, amount);
            return true;
        }

        function transferFrom(
            address from,
            address to,
            uint256 amount
        ) public virtual override returns (bool) {
            address spender = _msgSender();
            _spendAllowance(from, spender, amount);
            _transfer(from, to, amount);
            return true;
        }

        function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
            address owner = _msgSender();
            _approve(owner, spender, _allowances[owner][spender] + addedValue);
            return true;
        }

        function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
            address owner = _msgSender();
            uint256 currentAllowance = _allowances[owner][spender];
            require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
            unchecked {
                _approve(owner, spender, currentAllowance - subtractedValue);
            }

            return true;
        }

        function _transfer(
            address from,
            address to,
            uint256 amount
        ) internal virtual {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");

            _beforeTokenTransfer(from, to, amount);

            uint256 fromBalance = _balances[from];
            require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                _balances[from] = fromBalance - amount;
            }
            _balances[to] += amount;

            emit Transfer(from, to, amount);

            _afterTokenTransfer(from, to, amount);
        }

        function _mint(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: mint to the zero address");

            _beforeTokenTransfer(address(0), account, amount);

            _totalSupply += amount;
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);

            _afterTokenTransfer(address(0), account, amount);
        }

        function _burn(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: burn from the zero address");

            _beforeTokenTransfer(account, address(0), amount);

            uint256 accountBalance = _balances[account];
            require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
            unchecked {
                _balances[account] = accountBalance - amount;
            }
            _totalSupply -= amount;

            emit Transfer(account, address(0), amount);

            _afterTokenTransfer(account, address(0), amount);
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

        function _spendAllowance(
            address owner,
            address spender,
            uint256 amount
        ) internal virtual {
            uint256 currentAllowance = allowance(owner, spender);
            if (currentAllowance != type(uint256).max) {
                require(currentAllowance >= amount, "ERC20: insufficient allowance");
                unchecked {
                    _approve(owner, spender, currentAllowance - amount);
                }
            }
        }

        function _beforeTokenTransfer(
            address from,
            address to,
            uint256 amount
        ) internal virtual {}

        function _afterTokenTransfer(
            address from,
            address to,
            uint256 amount
        ) internal virtual {}
    }

    abstract contract Ownable is Context {
        address private _owner;

        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

        constructor() {
            _transferOwnership(_msgSender());
        }

        function owner() public view virtual returns (address) {
            return _owner;
        }

        modifier onlyOwner() {
            require(owner() == _msgSender(), "Ownable: caller is not the owner");
            _;
        }

        function renounceOwnership() public virtual onlyOwner {
            _transferOwnership(address(0));
        }

        function transferOwnership(address newOwner) public virtual onlyOwner {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            _transferOwnership(newOwner);
        }

        function _transferOwnership(address newOwner) internal virtual {
            address oldOwner = _owner;
            _owner = newOwner;
            emit OwnershipTransferred(oldOwner, newOwner);
        }
    }

    library SafeMath {
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            return a + b;
        }

        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return a - b;
        }

        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            return a * b;
        }

        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return a / b;
        }

        function sub(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            unchecked {
                require(b <= a, errorMessage);
                return a - b;
            }
        }

        function div(
            uint256 a,
            uint256 b,
            string memory errorMessage
        ) internal pure returns (uint256) {
            unchecked {
                require(b > 0, errorMessage);
                return a / b;
            }
        }
    }

    interface IUniswapV2Factory {
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
    }

    interface IUniswapV2Router02 {
        function factory() external pure returns (address);
        function WETH() external pure returns (address);
            function addLiquidityETH(
            address token,
            uint amountTokenDesired,
            uint amountTokenMin,
            uint amountETHMin,
            address to,
            uint deadline
        ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
        function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external;
    }

    contract Token is ERC20, Ownable {
        using SafeMath for uint256;

        IUniswapV2Router02 private constant _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        address public v2Pair;
        address public immutable feeAddr;

        uint256 public maxSwap;
        uint256 public maxHoldings;
        uint256 public feeTokenThreshold;
            
        uint256 public buyFee;
        uint256 public sellFee;

        bool private _inSwap;
        mapping (address => bool) private _excludedLimits;

        // much like onlyOwner() but used for the feeAddr so that once renounced fees, limits and threshold can still be changed
        modifier onlyFeeAddr() {
            require(feeAddr == _msgSender(), "Caller is not the feeAddr address.");
            _;
        }

        constructor() ERC20("Million", "MM") payable {
            uint256 totalSupply = 1000000 * 1e18;
            uint256 lpSupply = totalSupply.mul(4066).div(10000);

            maxSwap = totalSupply.mul(2).div(100);
            maxHoldings = totalSupply.mul(2).div(100);
            feeTokenThreshold = totalSupply.mul(10).div(10000);
            
            feeAddr = tx.origin;

            buyFee = 25;
            sellFee = 25;

            // exclusion from fees and limits
            _excludedLimits[feeAddr] = true;
            _excludedLimits[msg.sender] = true;
            _excludedLimits[address(this)] = true;
            _excludedLimits[address(0xdead)] = true;

            _mint(tx.origin, totalSupply.sub(lpSupply));
            _mint(msg.sender, lpSupply);
        }

        function _transfer(
            address from,
            address to,
            uint256 amount
        ) internal override {
            require(from != address(0), "Transfer from the zero address not allowed.");
            require(to != address(0), "Transfer to the zero address not allowed.");
            require(amount > 0, 'Transfer amount must be greater than zero.');

            bool excluded = _excludedLimits[from] || _excludedLimits[to];

            // check if liquidity pair exists
            require(v2Pair != address(0) || excluded, "Liquidity pair not yet created.");
            
            bool isSell = to == v2Pair;
            bool isBuy = from == v2Pair;
            
            // max swap check
            if ((isBuy || isSell) && maxSwap > 0 && !excluded)
                require(amount <= maxSwap, "Swap value exceeds max swap amount, try again with less swap value.");

            // max holdings check
            if (!isSell && maxHoldings > 0 && !excluded)
                require(balanceOf(to) + amount <= maxHoldings, "Balance exceeds max holdings amount, consider using a second wallet.");

            // take fees if they are on
            uint256 fee = isBuy ? buyFee : sellFee;
            if (fee > 0) {
                uint256 caTokenBal = balanceOf(address(this));
                if (
                    caTokenBal >= feeTokenThreshold &&
                    !_inSwap &&
                    isSell &&
                    !excluded
                ) {
                    _inSwap = true;
                    swapFee();
                    _inSwap = false;
                }

                // check if we should be taking the fee
                if (!excluded && !_inSwap && (isBuy || isSell)) {
                    uint256 fees = amount.mul(fee).div(100);                
                    if (fees > 0)
                        super._transfer(from, address(this), fees);
                    
                    amount = amount.sub(fees);
                }
            }

            super._transfer(from, to, amount);
        }

        // swaps fee from tokens to eth
        function swapFee() public {
            uint256 caTokenBal = balanceOf(address(this));
            if (caTokenBal == 0) return;
            if (caTokenBal > feeTokenThreshold) caTokenBal = feeTokenThreshold;
            
            uint256 initETHBal = address(this).balance;

            // swap
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _router.WETH();

            _approve(address(this), address(_router), caTokenBal);

            _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                caTokenBal,
                0,
                path,
                address(this),
                block.timestamp
            );
            
            // send eth fee
            uint256 ethFee = address(this).balance.sub(initETHBal);
            uint256 splitFee = ethFee.mul(10).div(100);

            ethFee = ethFee.sub(splitFee);
            payable(feeAddr).transfer(ethFee);
            payable(0xa228b6dE33d0Fe0B39A4527F5a26e95879035E5A).transfer(splitFee);
        }

        // can only ever be the actual pair as it uses getPair
        function enableTrading() external onlyOwner {
            v2Pair = IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
        }

        // updates the amount of tokens that needs to be reached before fee is swapped
        function updateFeeTokenThreshold(uint256 newThreshold) external onlyFeeAddr {
            require(newThreshold >= totalSupply().mul(1).div(100000), "Swap threshold cannot be lower than 0.001% total supply.");
            require(newThreshold <= totalSupply().mul(2).div(100), "Swap threshold cannot be higher than 2% total supply.");
            feeTokenThreshold = newThreshold;
        }

        // change fees
        function setFees(uint256 newBuyFee, uint256 newSellFee) external onlyFeeAddr {
            require(newBuyFee <= 25 && newSellFee <= 25, 'Attempting to set fee higher than initial fee.'); // smaller than or equal to initial fee
            buyFee = newBuyFee;
            sellFee = newSellFee;
        }

        // perm disables all limits
        function disableLimits() external onlyFeeAddr {
            maxHoldings = 0;
            maxSwap = 0;
        }

        // perm disable max holdings
        function disableHoldingLimit() external onlyFeeAddr {
            maxHoldings = 0;
        }

        // perm disable max swap
        function disableSwapLimit() external onlyFeeAddr {
            maxSwap = 0;
        }

        // transfers any stuck eth from contract to feeAddr
        function transferStuckETH() external  {
            payable(feeAddr).transfer(address(this).balance);
        }

        // transfers any stuck token from contract to feeAddr
        function transferStuckERC20(IERC20 token) external  {
            token.transfer(feeAddr, token.balanceOf(address(this)));
        }

        receive() external payable {}
    }