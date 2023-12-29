// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./IToken.sol";
import "./ERC20TokenRecover.sol";
import "./ERC1363.sol";
import "./IKARMAAntiBot.sol";
import "./LimitedOwner.sol";

// import "./console.sol";

interface IFactory {
	function createPair(
		address tokenA,
		address tokenB
	) external returns (address pair);
}

interface IRouter {
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

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;
}

abstract contract BaseToken is
	Initializable,
	ContextUpgradeable,
	OwnableUpgradeable,
	LimitedOwner,
	IToken,
	ERC20Upgradeable,
	ERC20TokenRecover,
	ERC1363
{

	address public deployer;

	address public constant DEAD = address(0xdead);

	mapping(address => uint256) private _balances;
	mapping(address => bool) public excludedFromFees;

	IRouter public router;
	address public pair;

	bool public tradingEnabled;

	uint256 public maxTxAmount;
	uint256 public maxWalletAmount;

	IKARMAAntiBot public antibot;
	bool public enableAntiBot;
	address public karmaDeployer;

	uint8 _decimals;

	uint256[50] __gap;

	constructor() {
		deployer = _msgSender();
	}

	function __BaseToken_init(
		string memory name,
		string memory symbol,
		uint8 decim,
		uint256 supply,
		address limitedOwner
	) public virtual {
		// msg.sender = address(0) when using Clone.
		require(
			deployer == address(0) || _msgSender() == deployer,
			"UNAUTHORIZED"
		);
		require(decim > 3 && decim < 19, "DECIM");

		deployer = _msgSender();

		super.__ERC20_init(name, symbol);
		super.__Ownable_init_unchained();
		// super.__ERC20Capped_init_unchained(supply);
		// super.__ERC20Burnable_init_unchained(true);
		_decimals = decim;

		_mint(_msgSender(), supply);
		transferLimitedOwner(limitedOwner);
		transferOwnership(tx.origin);
	}

	function decimals()
		public
		view
		virtual
		override(ERC20Upgradeable, IERC20MetadataUpgradeable)
		returns (uint8)
	{
		return _decimals;
	}

	//== BEP20 owner function ==
	function getOwner() public view override returns (address) {
		return owner();
	}

	//== Mandatory overrides ==/
	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(
		bytes4 interfaceId
	) public view virtual override(ERC1363) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	function _mint(
		address account,
		uint256 amount
	) internal virtual override(ERC20Upgradeable) {
		super._mint(account, amount);
	}

	function disableAntiBot(
	) external onlyLimitedOrOwner {
		require(enableAntiBot == true, "ALREADY_DISABLED");
		enableAntiBot = false;
	}

	function updateExcludedFromFees(
		address _address,
		bool state
	) external onlyLimitedOrOwner {
		excludedFromFees[_address] = state;
	}

	function updateMaxTxAmount(uint256 amount) external onlyLimitedOrOwner {
		require(amount > (totalSupply() / 10000), "maxTxAmount < 0.01%");
		require(
			(amount > maxTxAmount && msg.sender == limitedOwner()) ||
				(msg.sender == karmaDeployer && owner() == karmaDeployer),
			"Only Karma deployer"
		);
		maxTxAmount = amount;
	}

	function updateMaxWalletAmount(uint256 amount) external onlyLimitedOrOwner {
		require(amount > (totalSupply() / 10000), "maxWalletAmount < 0.01%");
		require(
			(amount > maxWalletAmount && msg.sender == limitedOwner()) ||
				(msg.sender == karmaDeployer && owner() == karmaDeployer),
			"Only Karma deployer"
		);
		maxWalletAmount = amount;
	}

	function enableTrading() external onlyLimitedOrOwner {
		require(!tradingEnabled, "Trading already active");

		tradingEnabled = true;
		if (enableAntiBot) {
			antibot.launch(pair, address(router));
		}
	}

	function disableTrading() external onlyOwner {
		require(
			msg.sender == karmaDeployer && owner() == karmaDeployer,
			"Only karma deployer can disable"
		);
		tradingEnabled = false;
	}

	function setEnableAntiBot(bool _enable) external onlyOwner {
		enableAntiBot = _enable;
	}

	// fallbacks
	receive() external payable {}
}
