// SPDX-License-Identifier: MIT

// Attention all users! 

// Montage Token takes a strong stance against any form of malicious trading behaviour. We prioritize the safety & security of our community and our enabling ecosystem. 
// Any user (BOT or human) engaging in activities that threaten the integrity of our services, such as interfering with transactions, will be swiftly identified and blacklisted. 
// This means permanently restricted from accessing our services. We urge all users to adhere to ethical practices when trading our token and respect these  terms of service. 
// Let us work together to maintain a trusted and secure environment for all Montage investors worldwide.
 
pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

library Address {
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			"Address: insufficient balance"
		);

		(bool success, ) = recipient.call{value: amount}("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);
	}

	function functionCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
		functionCallWithValue(
			target,
			data,
			value,
			"Address: low-level call with value failed"
		);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			"Address: insufficient balance for call"
		);
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{value: value}(
		data
		);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data)
	internal
	view
	returns (bytes memory)
	{
		return
		functionStaticCall(
			target,
			data,
			"Address: low-level static call failed"
		);
	}

	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");

		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return
		functionDelegateCall(
			target,
			data,
			"Address: low-level delegate call failed"
		);
	}

	function functionDelegateCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");

		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) private pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

contract MontageToken is Ownable, ERC20 {
    using Address for address;

    IRouter public uniswapV2Router;
    address public uniswapV2Pair;

    string private constant _name = "Montage Token";
    string private constant _symbol = "MTGX";

    bool public isTradingEnabled;

    uint256 public initialSupply = 10000000000 * (10**18);
    uint256 public maxWalletAmount = initialSupply * 200 / 10000;

    bool private _swapping;
    uint256 public minimumTokensBeforeSwap = initialSupply - (initialSupply - 1);
	uint256 public acceptableSlippagePercent= 0;

    address public targetAWallet;
    address public targetBWallet;
	address public targetCWallet;

    struct CustomTaxPeriod {
        uint32 targetAFeeOnBuy; //liquidity
        uint32 targetAFeeOnSell;
        uint32 targetBFeeOnBuy; //marketing
        uint32 targetBFeeOnSell;
		uint32 targetCFeeOnBuy; //charity
		uint32 targetCFeeOnSell;
        uint32 burnFeeOnBuy;
        uint32 burnFeeOnSell;
    }

    // Base taxes
    CustomTaxPeriod private _base = CustomTaxPeriod(0, 618, 1000, 1000, 0, 1000, 0, 382);

    bool private _pairCreated;
    bool private _launchTokensClaimed;
    uint256 private _launchBlockNumber;

    mapping (address => bool) private _isBlocked;
    mapping(address => bool) private _isAllowedToTradeWhenDisabled;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxWalletLimit;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint32 private _targetAFee;
    uint32 private _targetBFee;
	uint32 private _targetCFee;
    uint32 private _burnFee;
    uint32 private _totalFee;

    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event BlockedAccountChange(address indexed holder, bool indexed status);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
    event WalletChange(string indexed indentifier,address indexed newWallet,address indexed oldWallet);
    event FeeChange(string indexed identifier,uint32 targetAFee, uint32 targetBFee, uint32 targetCFee, uint32 burnFee);
    event CustomTaxPeriodChange(uint256 indexed newValue,uint256 indexed oldValue,string indexed taxType);
    event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
    event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ClaimOverflow(address token, uint256 amount);
    event TradingStatusChange(bool indexed newValue, bool indexed oldValue);
    event Liquify(uint256 ethReceived, uint256 tokensIntoLiqudity);
    event FeesApplied(uint32 targetAFee, uint32 targetBFee, uint32 targetCFee, uint32 burnFee, uint32 totalFee);
    event TokenBurn(uint32 burnFee, uint256 amountToBurn);

    constructor() ERC20(_name, _symbol) {
        targetAWallet = owner();
        targetBWallet = owner();
		targetCWallet = owner();

        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		address _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;
		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isAllowedToTradeWhenDisabled[owner()] = true;
        _isAllowedToTradeWhenDisabled[address(this)] = true;

        _isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;

        _mint(owner(), initialSupply);
    }

    receive() external payable {}

    function activateTrading() external onlyOwner {
        isTradingEnabled = true;
        if(_launchBlockNumber == 0) {
            _launchBlockNumber = block.number;
        }
        emit TradingStatusChange(true, false);
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "Montage: Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;
		emit AutomatedMarketMakerPairChange(pair, value);
	}
    function allowTradingWhenDisabled(address account, bool allowed) external onlyOwner {
        _isAllowedToTradeWhenDisabled[account] = allowed;
        emit AllowedWhenTradingDisabledChange(account, allowed);
    }
    function blockAccount(address account) external onlyOwner {
        require(!_isBlocked[account], "Montage: Account is already blocked");
        _isBlocked[account] = true;
        emit BlockedAccountChange(account, true);
    }
    function unblockAccount(address account) external onlyOwner {
        require(_isBlocked[account], "Montage: Account is not blcoked");
        _isBlocked[account] = false;
        emit BlockedAccountChange(account, false);
    }
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFee[account] != excluded,"Montage: Account is already the value of 'excluded'");
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }
    function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] != excluded,"Montage: Account is already the value of 'excluded'");
        _isExcludedFromMaxWalletLimit[account] = excluded;
        emit ExcludeFromMaxWalletChange(account, excluded);
    }
    function setWallets(address newTargetAWallet, address newTargetBWallet, address newTargetCWallet) external onlyOwner {
        if (targetAWallet != newTargetAWallet) {
            require(newTargetAWallet != address(0), "Montage: The targetAWallet cannot be 0");
            emit WalletChange("targetAWallet", newTargetAWallet, targetAWallet);
            targetAWallet = newTargetAWallet;
        }
        if (targetBWallet != newTargetBWallet) {
            require(newTargetBWallet != address(0), "Montage: The targetBWallet cannot be 0");
            emit WalletChange("targetBWallet", newTargetBWallet, targetBWallet);
            targetBWallet = newTargetBWallet;
        }
		if (targetCWallet != newTargetCWallet) {
			require(newTargetCWallet != address(0), "Montage: The targetCWallet cannot be 0");
			emit WalletChange("targetCWallet", newTargetCWallet, targetCWallet);
			targetCWallet = newTargetCWallet;
		}
    }
    function setFeesOnBuy(uint32 _targetAFeeOnBuy, uint32 _targetBFeeOnBuy, uint32 _targetCFeeOnBuy, uint32 _burnFeeOnBuy) external onlyOwner {
        require(_targetAFeeOnBuy + _targetBFeeOnBuy + _targetCFeeOnBuy + _burnFeeOnBuy <= 10000, "Montage: Fees must be less or equal to 10%");
        _setCustomBuyTaxPeriod(_base,_targetAFeeOnBuy,_targetBFeeOnBuy, _targetCFeeOnBuy, _burnFeeOnBuy);
        emit FeeChange("baseFees-Buy",_targetAFeeOnBuy,_targetBFeeOnBuy, _targetCFeeOnBuy, _burnFeeOnBuy);
    }
    function setFeesOnSell(uint32 _targetAFeeOnSell, uint32 _targetBFeeOnSell, uint32 _targetCFeeOnSell, uint32 _burnFeeOnSell) external onlyOwner {
        require(_targetAFeeOnSell + _targetBFeeOnSell + _targetCFeeOnSell + _burnFeeOnSell <= 10000, "Montage: Fees must be less or equal to 10%");
        _setCustomSellTaxPeriod(_base,_targetAFeeOnSell, _targetBFeeOnSell, _targetCFeeOnSell, _burnFeeOnSell);
        emit FeeChange("baseFees-Sell",_targetAFeeOnSell, _targetBFeeOnSell, _targetCFeeOnSell, _burnFeeOnSell);
    }
    function setUniswapRouter(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router),"Montage: The router already has that address");
        emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
        uniswapV2Router = IRouter(newAddress);
    }
    function setMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(newValue >= totalSupply() * 10 / 1000, "Montage: Max wallet value must be greater than or equal to 1% of supply");
        require(newValue != maxWalletAmount,"Montage: Cannot update maxWalletAmount to same value");
        emit MaxWalletAmountChange(newValue, maxWalletAmount);
        maxWalletAmount = newValue;
    }
    function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
        require(newValue != minimumTokensBeforeSwap,"Montage: Cannot update minimumTokensBeforeSwap to same value");
        emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
        minimumTokensBeforeSwap = newValue;
    }
    function claimLaunchTokens() external onlyOwner {
		require(block.number - _launchBlockNumber > 5, "Montage: Only claim launch tokens after first 5 blocks");
        require(!_launchTokensClaimed, "Montage: Launch tokens have been claimed");
        _launchTokensClaimed = true;
		uint256 tokenBalance = balanceOf(address(this));
        (bool success) = IERC20(address(this)).transfer(owner(), tokenBalance);
        if (success){
            emit ClaimOverflow(address(this), tokenBalance);
        }
    }
    function claimETHOverflow(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Montage: Cannot send more than contract balance");
        (bool success, ) = address(owner()).call{ value: amount }("");
        if (success) {
            emit ClaimOverflow(uniswapV2Router.WETH(), amount);
        }
    }
	function setAcceptableSlippage(uint256 value) external onlyOwner {
		require (value <= 1000, "Montage: Acceptable slippage cannot be more than 100%!") ;
		acceptableSlippagePercent = value;
	}

    // Getters
    function getBuyFees() external view returns (uint32, uint32, uint32, uint32) {
        return (_base.targetAFeeOnBuy, _base.targetBFeeOnBuy, _base.targetCFeeOnBuy, _base.burnFeeOnBuy);
    }
    function getSellFees() external view returns (uint32, uint32, uint32, uint32) {
        return (_base.targetAFeeOnSell, _base.targetBFeeOnSell, _base.targetCFeeOnSell, _base.burnFeeOnSell);
    }
    // Main
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
		require(!_isBlocked[to], "Montage: Account is blocked");
		require(!_isBlocked[from], "Montage: Account is blocked");

		if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (!_isAllowedToTradeWhenDisabled[from] && !_isAllowedToTradeWhenDisabled[to]) {
            require(isTradingEnabled, "Montage: Trading is currently disabled.");
        }

        _adjustTaxes(automatedMarketMakerPairs[from], automatedMarketMakerPairs[to]);
        bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

        if (
            isTradingEnabled &&
            canSwap &&
            !_swapping &&
            _totalFee > 0 &&
            automatedMarketMakerPairs[to]
        ) {
            _swapping = true;
            _swapAndTransfer();
            _swapping = false;
        }

        bool takeFee = !_swapping && isTradingEnabled;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        if (takeFee && _totalFee > 0) {
            uint256 fee = (amount * _totalFee) / 100000;
            amount = amount - fee;
            super._transfer(from, address(this), fee);
        }

		if (!_isExcludedFromMaxWalletLimit[to]) {
			require((balanceOf(to) + amount) <= maxWalletAmount, "Montage: Expected wallet amount exceeds the maxWalletAmount.");
		}

        super._transfer(from, to, amount);
    }
    function _adjustTaxes(bool isBuy,bool isSell) private {
        _targetAFee = 0;
        _targetBFee = 0;
		_targetCFee = 0;
        _burnFee = 0;

        if (isBuy) {
            if (block.number - _launchBlockNumber <= 5) {
                _targetAFee = 100000;
            } else {
                _targetAFee = _base.targetAFeeOnBuy;
                _targetBFee = _base.targetBFeeOnBuy;
				_targetCFee = _base.targetCFeeOnBuy;
                _burnFee = _base.burnFeeOnBuy;
            }
        }
        if (isSell) {
            _targetAFee = _base.targetAFeeOnSell;
            _targetBFee = _base.targetBFeeOnSell;
			_targetCFee = _base.targetCFeeOnSell;
            _burnFee = _base.burnFeeOnSell;
        }
        _totalFee = _targetAFee + _targetBFee + _targetCFee + _burnFee;
        emit FeesApplied(_targetAFee, _targetBFee, _targetCFee, _burnFee, _totalFee);
    }
    function _setCustomSellTaxPeriod(CustomTaxPeriod storage map, uint32 _targetAFeeOnSell, uint32 _targetBFeeOnSell, uint32 _targetCFeeOnSell, uint32 _burnFeeOnSell ) private {
        if (map.targetAFeeOnSell != _targetAFeeOnSell) {
            emit CustomTaxPeriodChange(_targetAFeeOnSell,map.targetAFeeOnSell,"targetAFeeOnSell");
            map.targetAFeeOnSell = _targetAFeeOnSell;
        }
        if (map.targetBFeeOnSell != _targetBFeeOnSell) {
            emit CustomTaxPeriodChange(_targetBFeeOnSell,map.targetBFeeOnSell,"targetBFeeOnSell");
            map.targetBFeeOnSell = _targetBFeeOnSell;
        }
		if (map.targetCFeeOnSell != _targetCFeeOnSell) {
			emit CustomTaxPeriodChange(_targetCFeeOnSell,map.targetCFeeOnSell,"targetCFeeOnSell");
			map.targetCFeeOnSell = _targetCFeeOnSell;
		}
        if (map.burnFeeOnSell != _burnFeeOnSell) {
            emit CustomTaxPeriodChange(_burnFeeOnSell,map.burnFeeOnSell,"burnFeeOnSell");
            map.burnFeeOnSell = _burnFeeOnSell;
        }
    }
    function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map, uint32 _targetAFeeOnBuy, uint32 _targetBFeeOnBuy, uint32 _targetCFeeOnBuy, uint32 _burnFeeOnBuy) private {
        if (map.targetAFeeOnBuy != _targetAFeeOnBuy) {
            emit CustomTaxPeriodChange(_targetAFeeOnBuy,map.targetAFeeOnBuy,"targetAFeeOnBuy");
            map.targetAFeeOnBuy = _targetAFeeOnBuy;
        }
        if (map.targetBFeeOnBuy != _targetBFeeOnBuy) {
            emit CustomTaxPeriodChange(_targetBFeeOnBuy,map.targetBFeeOnBuy,"targetBFeeOnBuy");
            map.targetBFeeOnBuy = _targetBFeeOnBuy;
        }
		if (map.targetCFeeOnBuy != _targetCFeeOnBuy) {
			emit CustomTaxPeriodChange(_targetCFeeOnBuy,map.targetCFeeOnBuy,"targetCFeeOnBuy");
			map.targetCFeeOnBuy = _targetCFeeOnBuy;
		}
        if (map.burnFeeOnBuy != _burnFeeOnBuy) {
            emit CustomTaxPeriodChange(_burnFeeOnBuy,map.burnFeeOnBuy,"burnFeeOnBuy");
            map.burnFeeOnBuy = _burnFeeOnBuy;
        }
    }
    function _swapAndTransfer() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;
        uint32 _totalFeePrior = _totalFee;

        uint256 amountToLiquify = contractBalance * _targetAFee / _totalFeePrior / 2;
        uint256 amountToBurn = contractBalance * _burnFee / _totalFeePrior;
        uint256 amountToSwap = contractBalance - amountToLiquify - amountToBurn;

        if (amountToBurn > 0) {
            super._burn(address(this), amountToBurn);
            emit TokenBurn(_burnFee, amountToBurn);
        }

        _swapTokensForETH(amountToSwap);

        uint256 ETHBalanceAfterSwap = address(this).balance - initialETHBalance;
        uint256 totalETHFee = _totalFeePrior - (_targetAFee / 2) - _burnFee;
        uint256 amountETHTargetA = ETHBalanceAfterSwap * _targetAFee / totalETHFee / 2;
		uint256 amountETHTargetB = ETHBalanceAfterSwap * _targetBFee / totalETHFee;
        uint256 amountETHTargetC = ETHBalanceAfterSwap - amountETHTargetA - amountETHTargetB;

        Address.sendValue(payable(targetBWallet),amountETHTargetB);
		Address.sendValue(payable(targetCWallet),amountETHTargetC);

        if (amountToLiquify > 0) {
            _addLiquidity(amountToLiquify, amountETHTargetA);
            emit Liquify(amountETHTargetA, amountToLiquify);
        }
        _totalFee = _totalFeePrior;
    }
    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);

		uint256 minAmountOut;
		if (acceptableSlippagePercent == 0) {
			// Disable slippage protection if zero is set to acceptableSlippagePercent (it would always revert otherwise)
			minAmountOut = 0;
		} else {
			// Determine the minimum out token percentage ie. if tokenAmount was 100 and 20% was the acceptable slippage,
			// the result will be 20 tokens.
			uint256 minAmountOutPercentage = (tokenAmount * acceptableSlippagePercent) / 1000;
			//1 Determine the min amount out by subtracting total token amount the min out percentage so
			// the final result would be at least 80 tokens out.
			minAmountOut = tokenAmount - minAmountOutPercentage;
		}

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
			minAmountOut,
            path,
            address(this),
            block.timestamp
        );
    }
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{ value: ethAmount }(
            address(this),
            tokenAmount,
            1, // slippage is unavoidable
            1, // slippage is unavoidable
            targetAWallet,
            block.timestamp
        );
    }
}