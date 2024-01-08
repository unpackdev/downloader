// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Manageable.sol";
import "./BEP20.sol";
import "./ISphynxPair.sol";
import "./ISphynxFactory.sol";
import "./ISphynxRouter02.sol";
interface AggregatorV3Interface {
	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	// getRoundData and latestRoundData should both raise "No data present"
	// if they do not have data to report, instead of returning unset values
	// which could be misinterpreted as actual reported values.
	function getRoundData(uint80 _roundId)
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);

	function latestRoundData()
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);
}

contract SphynxToken is BEP20, Manageable {
	using SafeMath for uint256;

	ISphynxRouter02 public sphynxSwapRouter;
	address public sphynxSwapPair;

	bool private swapping;

	address public masterChef;
	address public sphynxBridge;

	address payable public marketingWallet = payable(0x982687617bc9a76420138a0F82b2fC1B8B11BbE3);
	address payable public developmentWallet = payable(0x4A48062b88d5B8e9f0B7A5149F87288899C2d7f9);
	address public lotteryAddress;

	uint256 public usdAmountToSwap = 500;

	uint256 public marketingFee;
	uint256 public developmentFee;
	uint256 public lotteryFee;
	uint256 public totalFees;
	uint256 public blockNumber;

	bool public SwapAndLiquifyEnabled = false;
	bool public sendToLottery = false;

	AggregatorV3Interface internal priceFeed;

	// exlcude from fees and max transaction amount
	mapping(address => bool) private _isExcludedFromFees;

	// getting fee addresses
	mapping(address => bool) public _isGetFees;

	// store addresses that are automated market maker pairs. Any transfer to these addresses
	// could be subject to a maximum transfer amount
	mapping(address => bool) public automatedMarketMakerPairs;

	modifier onlyMasterChefAndBridge() {
		require(msg.sender == masterChef || msg.sender == sphynxBridge, 'Permission Denied');
		_;
	}

	// Contract Events
	event ExcludeFromFees(address indexed account, bool isExcluded);
	event GetFee(address indexed account, bool isGetFee);
	event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
	event DevelopmentWalletUpdated(address indexed newDevelopmentWallet, address indexed oldDevelopmentWallet);
	event LotteryAddressUpdated(address indexed newLotteryAddress, address indexed oldLotteryAddress);
	event UpdateSphynxSwapRouter(address indexed newAddress, address indexed oldAddress);
	event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
	event UpdateSwapAndLiquify(bool value);
	event UpdateSendToLottery(bool value);
	event SetMarketingFee(uint256 value);
	event SetDevelopmentFee(uint256 value);
	event SetLotteryFee(uint256 value);
	event SetAllFeeToZero(uint256 marketingFee, uint256 developmentFee, uint256 lotteryFee);
	event MaxFees(uint256 marketingFee, uint256 developmentFee, uint256 lotteryFee);
	event SetUsdAmountToSwap(uint256 usdAmountToSwap);
	event SetBlockNumber(uint256 blockNumber);
	event UpdateMasterChef(address masterChef);
	event UpdateSphynxBridge(address sphynxBridge);

	constructor() public BEP20('Sphynx ETH', 'SPHYNX') {
		uint256 _marketingFee = 5;
		uint256 _developmentFee = 5;
		uint256 _lotteryFee = 1;

		marketingFee = _marketingFee;
		developmentFee = _developmentFee;
		lotteryFee = _lotteryFee;
		totalFees = _marketingFee.add(_developmentFee);
		blockNumber = 0;

		ISphynxRouter02 _sphynxSwapRouter = ISphynxRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // mainnet
		// Create a sphynxswap pair for SPHYNX
		address _sphynxSwapPair = ISphynxFactory(_sphynxSwapRouter.factory()).createPair(address(this), _sphynxSwapRouter.WETH());

		sphynxSwapRouter = _sphynxSwapRouter;
		sphynxSwapPair = _sphynxSwapPair;

		_setAutomatedMarketMakerPair(sphynxSwapPair, true);

		// exclude from paying fees or having max transaction amount
		excludeFromFees(marketingWallet, true);
		excludeFromFees(developmentWallet, true);
		excludeFromFees(address(this), true);
		excludeFromFees(owner(), true);

		// set getFee addresses
		_isGetFees[address(_sphynxSwapRouter)] = true;
		_isGetFees[_sphynxSwapPair] = true;
		priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

		_mint(owner(), 1000000000 * (10**18));
	}

	receive() external payable {}

	// mint function for masterchef;
	function mint(address to, uint256 amount) public onlyMasterChefAndBridge {
		_mint(to, amount);
	}

	function updateSwapAndLiquifiy(bool value) public onlyManager {
		SwapAndLiquifyEnabled = value;
		emit UpdateSwapAndLiquify(value);
	}

	function updateSendToLottery(bool value) public onlyManager {
		sendToLottery = value;
		emit UpdateSendToLottery(value);
	}

	function setMarketingFee(uint256 value) external onlyManager {
		require(value <= 5, 'SPHYNX: Invalid marketingFee');
		marketingFee = value;
		totalFees = marketingFee.add(developmentFee);
		emit SetMarketingFee(value);
	}

	function setDevelopmentFee(uint256 value) external onlyManager {
		require(value <= 5, 'SPHYNX: Invalid developmentFee');
		developmentFee = value;
		totalFees = marketingFee.add(developmentFee);
		emit SetDevelopmentFee(value);
	}

	function setLotteryFee(uint256 value) external onlyManager {
		require(value <= 1, 'SPHYNX: Invalid lotteryFee');
		lotteryFee = value;
		emit SetLotteryFee(value);
	}

	function setAllFeeToZero() external onlyOwner {
		marketingFee = 0;
		developmentFee = 0;
		lotteryFee = 0;
		totalFees = 0;
		emit SetAllFeeToZero(marketingFee, developmentFee, lotteryFee);
	}

	function maxFees() external onlyOwner {
		marketingFee = 5;
		developmentFee = 5;
		lotteryFee = 1;
		totalFees = marketingFee.add(developmentFee);
		emit MaxFees(marketingFee, developmentFee, lotteryFee);
	}

	function updateSphynxSwapRouter(address newAddress) public onlyManager {
		require(newAddress != address(sphynxSwapRouter), 'SPHYNX: The router already has that address');
		emit UpdateSphynxSwapRouter(newAddress, address(sphynxSwapRouter));
		sphynxSwapRouter = ISphynxRouter02(newAddress);
		address _sphynxSwapPair;
		_sphynxSwapPair = ISphynxFactory(sphynxSwapRouter.factory()).getPair(address(this), sphynxSwapRouter.WETH());
		if(_sphynxSwapPair == address(0)) {
			_sphynxSwapPair = ISphynxFactory(sphynxSwapRouter.factory()).createPair(address(this), sphynxSwapRouter.WETH());
		}
		_setAutomatedMarketMakerPair(sphynxSwapPair, false);
		sphynxSwapPair = _sphynxSwapPair;
		_setAutomatedMarketMakerPair(sphynxSwapPair, true);
	}

	function updateMasterChef(address _masterChef) public onlyManager {
		require(masterChef != _masterChef, 'SPHYNX: MasterChef already exists!');
		masterChef = _masterChef;
		emit UpdateMasterChef(_masterChef);
	}

	function updateSphynxBridge(address _sphynxBridge) public onlyManager {
		require(sphynxBridge != _sphynxBridge, 'SPHYNX: SphynxBridge already exists!');
		_isExcludedFromFees[sphynxBridge] = false;
		sphynxBridge = _sphynxBridge;
		_isExcludedFromFees[sphynxBridge] = true;
		emit UpdateSphynxBridge(_sphynxBridge);
	}

	function excludeFromFees(address account, bool excluded) public onlyManager {
		require(_isExcludedFromFees[account] != excluded, "SPHYNX: Account is already the value of 'excluded'");
		_isExcludedFromFees[account] = excluded;

		emit ExcludeFromFees(account, excluded);
	}

	function setFeeAccount(address account, bool isGetFee) public onlyManager {
		require(_isGetFees[account] != isGetFee, "SPHYNX: Account is already the value of 'isGetFee'");
		_isGetFees[account] = isGetFee;

		emit GetFee(account, isGetFee);
	}

	function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
		for (uint256 i = 0; i < accounts.length; i++) {
			_isExcludedFromFees[accounts[i]] = excluded;
		}

		emit ExcludeMultipleAccountsFromFees(accounts, excluded);
	}

	function setAutomatedMarketMakerPair(address pair, bool value) public onlyManager {
		_setAutomatedMarketMakerPair(pair, value);
	}

	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, 'SPHYNX: Automated market maker pair is already set to that value');
		automatedMarketMakerPairs[pair] = value;

		emit SetAutomatedMarketMakerPair(pair, value);
	}

	function setUsdAmountToSwap(uint256 _usdAmount) public onlyManager {
		usdAmountToSwap = _usdAmount;
		emit SetUsdAmountToSwap(usdAmountToSwap);
	}

	function updateMarketingWallet(address newMarketingWallet) public onlyManager {
		require(newMarketingWallet != marketingWallet, 'SPHYNX: The marketing wallet is already this address');
		excludeFromFees(newMarketingWallet, true);
		excludeFromFees(marketingWallet, false);
		emit MarketingWalletUpdated(newMarketingWallet, marketingWallet);
		marketingWallet = payable(newMarketingWallet);
	}

	function updateDevelopmentgWallet(address newDevelopmentWallet) public onlyManager {
		require(newDevelopmentWallet != developmentWallet, 'SPHYNX: The development wallet is already this address');
		excludeFromFees(newDevelopmentWallet, true);
		excludeFromFees(developmentWallet, false);
		emit DevelopmentWalletUpdated(newDevelopmentWallet, developmentWallet);
		developmentWallet = payable(newDevelopmentWallet);
	}

	function updateLotteryAddress(address newLotteryAddress) public onlyManager {
		require(newLotteryAddress != lotteryAddress, 'SPHYNX: The lottery wallet is already this address');
		excludeFromFees(newLotteryAddress, true);
		excludeFromFees(lotteryAddress, false);
		emit LotteryAddressUpdated(newLotteryAddress, lotteryAddress);
		lotteryAddress = newLotteryAddress;
	}

	function setBlockNumber() public onlyOwner {
		blockNumber = block.number;
		emit SetBlockNumber(blockNumber);
	}

	function isExcludedFromFees(address account) public view returns (bool) {
		return _isExcludedFromFees[account];
	}

	function _transfer(
		address from,
		address to,
		uint256 amount
	) internal override {
		require(from != address(0), 'BEP20: transfer from the zero address');
		require(to != address(0), 'BEP20: transfer to the zero address');

		if (amount == 0) {
			super._transfer(from, to, 0);
			return;
		}

        if(SwapAndLiquifyEnabled) {
            uint256 contractTokenBalance = balanceOf(address(this));
            uint256 ethTokenAmount = _getTokenAmountFromETH();

		    bool canSwap = contractTokenBalance >= ethTokenAmount;

            if (canSwap && !swapping && !automatedMarketMakerPairs[from]) {
                swapping = true;

                // Set number of tokens to sell to ethTokenAmount
                contractTokenBalance = ethTokenAmount;
                swapTokens(contractTokenBalance);
                swapping = false;
            }
        }

		// indicates if fee should be deducted from transfer
		bool takeFee = true;

		// if any account belongs to _isExcludedFromFee account then remove the fee
		if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
			takeFee = false;
		}

		if (takeFee) {
			if (block.number - blockNumber <= 10) {
				uint256 afterBalance = balanceOf(to) + amount;
				require(afterBalance <= 250000 * (10**18), 'Owned amount exceeds the maxOwnedAmount');
			}
			uint256 fees;
			if (_isGetFees[from] || _isGetFees[to]) {
				if (block.number - blockNumber <= 5) {
					fees = amount.mul(99).div(10**2);
				} else {
					fees = amount.mul(totalFees).div(10**2);
					if (sendToLottery) {
						uint256 lotteryAmount = amount.mul(lotteryFee).div(10**2);
						amount = amount.sub(lotteryAmount);
						super._transfer(from, lotteryAddress, lotteryAmount);
					}
				}

				amount = amount.sub(fees);
				super._transfer(from, address(this), fees);
			}
		}

		super._transfer(from, to, amount);
	}

	function swapTokens(uint256 tokenAmount) private {
		swapTokensForEth(tokenAmount);
		uint256 swappedETH = address(this).balance;
		uint256 marketingETH = swappedETH.mul(marketingFee).div(totalFees);
		uint256 developmentETH = swappedETH.sub(marketingETH);
		transferETHToMarketingWallet(marketingETH);
		transferETHToDevelopmentWallet(developmentETH);
	}

	// Swap tokens on PacakeSwap
	function swapTokensForEth(uint256 tokenAmount) private {
		// generate the sphynxswap pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = sphynxSwapRouter.WETH();

		_approve(address(this), address(sphynxSwapRouter), tokenAmount);

		// make the swap
		sphynxSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
		);
	}

	function getNativeAmountFromUSD() public view returns (uint256 amount) {
		(
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        amount = usdAmountToSwap.mul(10 ** 26).div(uint256(price));
	}

	function _getTokenAmountFromETH() internal view returns (uint256) {
		uint256 tokenAmount;
		address[] memory path = new address[](2);
		path[0] = sphynxSwapRouter.WETH();
		path[1] = address(this);

		uint256 nativeAmountToSwap = getNativeAmountFromUSD();
		uint256[] memory amounts = sphynxSwapRouter.getAmountsOut(nativeAmountToSwap, path);
		tokenAmount = amounts[1];
		return tokenAmount;
	}

	function transferETHToMarketingWallet(uint256 amount) private {
		marketingWallet.transfer(amount);
	}

	function transferETHToDevelopmentWallet(uint256 amount) private {
		developmentWallet.transfer(amount);
	}
}