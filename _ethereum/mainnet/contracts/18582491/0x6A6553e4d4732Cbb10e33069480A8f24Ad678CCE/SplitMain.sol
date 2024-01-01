// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "./ISplitMain.sol";
import "./SplitWallet.sol";
import "./Clones.sol";
import "./IERC20Upgradeable.sol";
import "./SafeTransferLib.sol";
import "./IWETH.sol";
import "./ISonaSwap.sol";
import "./Ownable.sol";

/// @title SplitMain
/// @author @SonaEngineering; forked from 0xSplits <will@0xSplits.xyz>
/// @notice A composable and gas-efficient protocol for deploying splitter contracts.
/// @dev Split recipients, ownerships, and keeper fees are stored onchain as calldata & re-passed as args / validated
/// via hashing when needed. Each split gets its own address & proxy for maximum composability with other contracts onchain.
/// For these proxies, we extended EIP-1167 Minimal Proxy Contract to avoid `DELEGATECALL` inside `receive()` to accept
/// hard gas-capped `sends` & `transfers`.
contract SplitMain is ISplitMain, Ownable {
	using SafeTransferLib for address;
	using SafeTransferLib for IERC20;

	/// ERRORS

	/// @notice Unauthorized sender `sender`
	/// @param sender Transaction sender
	error UnauthorizedController(address sender);
	/// @notice Invalid number of accounts `accountsLength`, must have at least 2
	/// @param accountsLength Length of accounts array
	error InvalidSplit__TooFewAccounts(uint256 accountsLength);
	/// @notice Array lengths of accounts & percentAllocations don't match (`accountsLength` != `allocationsLength`)
	/// @param accountsLength Length of accounts array
	/// @param allocationsLength Length of percentAllocations array
	error InvalidSplit__AccountsAndAllocationsMismatch(
		uint256 accountsLength,
		uint256 allocationsLength
	);
	/// @notice Invalid percentAllocations sum `allocationsSum` must equal `PERCENTAGE_SCALE`
	/// @param allocationsSum Sum of percentAllocations array
	error InvalidSplit__InvalidAllocationsSum(uint32 allocationsSum);
	/// @notice Invalid accounts ordering at `index`
	/// @param index Index of out-of-order account
	error InvalidSplit__AccountsOutOfOrder(uint256 index);
	/// @notice Invalid percentAllocation of zero at `index`
	/// @param index Index of zero percentAllocation
	error InvalidSplit__AllocationMustBePositive(uint256 index);
	/// @notice Invalid distributorFee `distributorFee` cannot be greater than 10% (1e5)
	/// @param distributorFee Invalid distributorFee amount
	error InvalidSplit__InvalidDistributorFee(uint32 distributorFee);
	/// @notice Invalid hash `hash` from split data (accounts, percentAllocations, distributorFee)
	/// @param hash Invalid hash
	error InvalidSplit__InvalidHash(bytes32 hash);
	/// @notice Invalid new controlling address `newController` for mutable split
	/// @param newController Invalid new controller
	error InvalidNewController(address newController);

	//
	// STRUCTS
	//

	/// @notice holds Split metadata
	struct Split {
		bytes32 hash;
		address controller;
		address newPotentialController;
	}

	//
	// Storage
	//

	//
	// STORAGE - CONSTANTS & IMMUTABLES
	//

	/// @notice constant to scale uints into percentages (1e6 == 100%)
	uint256 public constant PERCENTAGE_SCALE = 1e6;
	/// @notice maximum distributor fee; 1e5 = 10%/// PERCENTAGE_SCALE
	uint256 internal constant _MAX_DISTRIBUTOR_FEE = 1e5;
	/// @notice address of wallet implementation for split proxies
	address public immutable override walletImplementation;
	/// @notice address of the WETH token
	IWETH public immutable WETH9;
	/// @notice address of the USDC token
	IERC20 public immutable USDC;
	/// @notice address of the swapper contract that converts (W)ETH to USDC
	ISonaSwap public swap;

	//
	// STORAGE - VARIABLES - PRIVATE & INTERNAL
	//

	/// @notice mapping to account ETH balances
	mapping(address => uint256) internal _ethBalances;
	/// @notice mapping to account ERC20 balances
	mapping(IERC20 => mapping(address => uint256)) internal _erc20Balances;
	/// @notice mapping to Split metadata
	mapping(address => Split) internal _splits;

	//
	// MODIFIERS
	//

	/// @notice Reverts if the sender doesn't own the split `split`
	/// @param split Address to check for control
	modifier onlySplitController(address split) {
		if (msg.sender != _splits[split].controller)
			revert UnauthorizedController(msg.sender);
		_;
	}

	/// @notice Reverts if the sender isn't the new potential controller of split `split`
	/// @param split Address to check for new potential control
	modifier onlySplitNewPotentialController(address split) {
		if (msg.sender != _splits[split].newPotentialController)
			revert UnauthorizedController(msg.sender);
		_;
	}

	/// @notice Reverts if the split with recipients represented by `accounts` and `percentAllocations` is malformed
	/// @param accounts Ordered, unique list of addresses with ownership in the split
	/// @param percentAllocations Percent allocations associated with each address
	modifier validSplit(
		address[] memory accounts,
		uint32[] memory percentAllocations
	) {
		_validSplit(accounts, percentAllocations);
		_;
	}

	/// @notice Reverts if `newController` is the zero address
	/// @param newController Proposed new controlling address
	modifier validNewController(address newController) {
		if (newController == address(0)) revert InvalidNewController(newController);
		_;
	}

	// CONSTRUCTOR

	constructor(IWETH _weth, IERC20 _usdc, ISonaSwap _swap) {
		walletImplementation = address(new SplitWallet());
		WETH9 = _weth;
		USDC = _usdc;
		swap = _swap;

		_initializeOwner(msg.sender);
	}

	// FUNCTIONS

	// FUNCTIONS - PUBLIC & EXTERNAL

	/// @notice Receive ETH
	/// @dev Used by split proxies in `distributeETH` to transfer ETH to `SplitMain`
	///		Funds sent outside of `distributeETH` will be unrecoverable
	receive() external payable {} // solhint-disable-line no-empty-blocks

	/// @notice Creates a new split with recipients `accounts` with ownerships `percentAllocations`, a keeper fee for splitting of `distributorFee` and the controlling address `controller`
	/// @param accounts Ordered, unique list of addresses with ownership in the split
	/// @param percentAllocations Percent allocations associated with each address
	/// @return split Address of newly created split
	function createSplit(
		address[] calldata accounts,
		uint32[] calldata percentAllocations
	)
		public
		override
		validSplit(accounts, percentAllocations)
		returns (address split)
	{
		bytes32 splitHash = _hashSplit(accounts, percentAllocations);
		// create mutable split
		split = Clones.clone(walletImplementation);
		_splits[split].controller = msg.sender;
		// store split's hash in storage for future verification
		_splits[split].hash = splitHash;
		emit CreateSplit(split);
	}

	/// @notice create multiple splits in a one call
	/// @dev the same config can be created multiple times
	/// @param splits the array structured objects representing the split configs
	function createSplits(
		SplitInput[] calldata splits
	) external override returns (address[] memory splitAddresses) {
		uint256 splitsLength = splits.length;
		splitAddresses = new address[](splitsLength);
		for (uint256 idx; idx < splitsLength; idx++) {
			splitAddresses[idx] = createSplit(
				splits[idx].accounts,
				splits[idx].percentAllocations
			);
		}
	}

	/// @notice Updates an existing split with recipients `accounts` with ownerships `percentAllocations` and a keeper fee for splitting of `distributorFee`
	/// @param split Address of mutable split to update
	/// @param accounts Ordered, unique list of addresses with ownership in the split
	/// @param percentAllocations Percent allocations associated with each address
	function updateSplit(
		address split,
		address[] calldata accounts,
		uint32[] calldata percentAllocations
	)
		external
		override
		onlySplitController(split)
		validSplit(accounts, percentAllocations)
	{
		_updateSplit(split, accounts, percentAllocations);
	}

	/// @notice Begins transfer of the controlling address of mutable split `split` to `newController`
	///  @dev Two-step control transfer inspired by [dharma](https://github.com/dharma-eng/dharma-smart-wallet/blob/master/contracts/helpers/TwoStepOwnable.sol)
	///  @param split Address of mutable split to transfer control for
	///  @param newController Address to begin transferring control to
	function transferControl(
		address split,
		address newController
	)
		external
		override
		onlySplitController(split)
		validNewController(newController)
	{
		_splits[split].newPotentialController = newController;
		emit InitiateControlTransfer(split, newController);
	}

	/// @notice Cancels transfer of the controlling address of mutable split `split`
	/// @param split Address of mutable split to cancel control transfer for
	function cancelControlTransfer(
		address split
	) external override onlySplitController(split) {
		delete _splits[split].newPotentialController;
		emit CancelControlTransfer(split);
	}

	/// @notice Accepts transfer of the controlling address of mutable split `split`
	/// @param split Address of mutable split to accept control transfer for
	function acceptControl(
		address split
	) external override onlySplitNewPotentialController(split) {
		delete _splits[split].newPotentialController;
		emit ControlTransfer(split, _splits[split].controller, msg.sender);
		_splits[split].controller = msg.sender;
	}

	/// @notice Distributes the ETH balance for split `split`
	/// @dev `accounts`, `percentAllocations`, and `distributorFee` are verified by hashing
	/// & comparing to the hash in storage associated with split `split`
	/// @param split Address of split to distribute balance for
	/// @param accounts Ordered, unique list of addresses with ownership in the split
	/// @param percentAllocations Percent allocations associated with each address
	function distributeETH(
		address split,
		address[] calldata accounts,
		uint32[] calldata percentAllocations
	) external override validSplit(accounts, percentAllocations) {
		// use internal fn instead of modifier to avoid stack depth compiler errors
		_validSplitHash(split, accounts, percentAllocations);
		_convertWETHToUSDCAndDistribute(split, accounts, percentAllocations);
	}

	/// @notice Updates & distributes the ETH balance for split `split`
	/// @dev only callable by SplitController
	/// @param split Address of split to distribute balance for
	/// @param accounts Ordered, unique list of addresses with ownership in the split
	/// @param percentAllocations Percent allocations associated with each address
	function updateAndDistributeETH(
		address split,
		address[] calldata accounts,
		uint32[] calldata percentAllocations
	)
		external
		override
		onlySplitController(split)
		validSplit(accounts, percentAllocations)
	{
		_updateSplit(split, accounts, percentAllocations);
		// know splitHash is valid immediately after updating; only accessible via controller
		_convertWETHToUSDCAndDistribute(split, accounts, percentAllocations);
	}

	/// @notice Distributes the ERC20 `token` balance for split `split`
	/// @dev `accounts`, `percentAllocations`, and `distributorFee` are verified by hashing
	/// & comparing to the hash in storage associated with split `split`
	/// @dev pernicious ERC20s may cause overflow in this function inside
	/// _scaleAmountByPercentage, but results do not affect ETH & other ERC20 balances
	/// @param split Address of split to distribute balance for
	/// @param token Address of ERC20 to distribute balance for
	/// @param accounts Ordered, unique list of addresses with ownership in the split
	/// @param percentAllocations Percent allocations associated with each address
	function distributeERC20(
		address split,
		IERC20 token,
		address[] calldata accounts,
		uint32[] calldata percentAllocations
	) external override validSplit(accounts, percentAllocations) {
		// use internal fn instead of modifier to avoid stack depth compiler errors
		_validSplitHash(split, accounts, percentAllocations);

		if (address(token) == address(USDC)) {
			_distributeERC20(split, token, accounts, percentAllocations);
		} else if (address(token) == address(WETH9)) {
			_convertWETHToUSDCAndDistribute(split, accounts, percentAllocations);
		} else {
			uint256 proxyBalance = token.balanceOf(split);
			SplitWallet(split).sendERC20ToMain(token, proxyBalance);
			_erc20Balances[token][_splits[split].controller] += proxyBalance;
		}
	}

	/// @notice Updates & distributes the ERC20 `token` balance for split `split`
	/// @dev only callable by SplitController
	/// @dev pernicious ERC20s may cause overflow in this function inside
	/// _scaleAmountByPercentage, but results do not affect ETH & other ERC20 balances
	/// @param split Address of split to distribute balance for
	/// @param token Address of ERC20 to distribute balance for
	/// @param accounts Ordered, unique list of addresses with ownership in the split
	/// @param percentAllocations Percent allocations associated with each address
	function updateAndDistributeERC20(
		address split,
		IERC20 token,
		address[] calldata accounts,
		uint32[] calldata percentAllocations
	)
		external
		override
		onlySplitController(split)
		validSplit(accounts, percentAllocations)
	{
		_updateSplit(split, accounts, percentAllocations);
		// know splitHash is valid immediately after updating; only accessible via controller
		_distributeERC20(split, token, accounts, percentAllocations);
	}

	/// @notice Withdraw ETH &/ ERC20 balances for account `account`
	/// @param account Address to withdraw on behalf of
	/// @param withdrawETH Withdraw all ETH if nonzero
	/// @param tokens Addresses of ERC20s to withdraw
	function withdraw(
		address account,
		uint256 withdrawETH,
		IERC20[] calldata tokens
	) external override {
		uint256[] memory tokenAmounts = new uint256[](tokens.length);
		uint256 ethAmount;
		if (withdrawETH != 0) {
			ethAmount = _withdraw(account);
		}
		unchecked {
			// overflow should be impossible in for-loop index
			for (uint256 i = 0; i < tokens.length; ++i) {
				// overflow should be impossible in array length math
				tokenAmounts[i] = _withdrawERC20(account, tokens[i]);
			}
			emit Withdrawal(account, ethAmount, tokens, tokenAmounts);
		}
	}

	/// @notice the owner updates the SonaSwap implementation to `_newSwap`
	/// @param _newSwap the new ISonaSwapImplementation to be utilized
	function updateSwap(ISonaSwap _newSwap) external onlyOwner {
		swap = _newSwap;
	}

	/// FUNCTIONS - VIEWS

	/// @notice Returns the current hash of split `split`
	/// @param split Split to return hash for
	/// @return Split's hash
	function getHash(address split) external view returns (bytes32) {
		return _splits[split].hash;
	}

	/// @notice Returns the current controller of split `split`
	/// @param split Split to return controller for
	/// @return Split's controller
	function getController(address split) external view returns (address) {
		return _splits[split].controller;
	}

	/// @notice Returns the current ETH balance of account `account`
	/// @param account Account to return ETH balance for
	/// @return Account's balance of ETH
	function getETHBalance(address account) external view returns (uint256) {
		return
			_ethBalances[account] +
			(_splits[account].hash != 0 ? account.balance : 0);
	}

	/// @notice Returns the ERC20 balance of token `token` for account `account`
	/// @param account Account to return ERC20 `token` balance for
	/// @param token Token to return balance for
	/// @return Account's balance of `token`
	function getERC20Balance(
		address account,
		IERC20 token
	) external view returns (uint256) {
		return
			_erc20Balances[token][account] +
			(_splits[account].hash != 0 ? token.balanceOf(account) : 0);
	}

	/// FUNCTIONS - PRIVATE & INTERNAL

	/// @notice Sums array of uint32s
	/// @param numbers Array of uint32s to sum
	/// @return sum Sum of `numbers`.
	function _getSum(uint32[] memory numbers) internal pure returns (uint32 sum) {
		// overflow should be impossible in for-loop index
		uint256 numbersLength = numbers.length;
		for (uint256 i = 0; i < numbersLength; ) {
			sum += numbers[i];
			unchecked {
				// overflow should be impossible in for-loop index
				++i;
			}
		}
	}

	/// @notice ensure a split configuration is valid in both contents and organization
	/// @dev reverts if there are fewer than 2 accounts, the arrays are different length,
	/// the allocations don't add up to 1e6, or accounts aren't sorted in the array
	/// @param accounts Ordered, unique list of addresses with ownership in the split
	/// @param percentAllocations Percent allocations associated with each address
	function _validSplit(
		address[] memory accounts,
		uint32[] memory percentAllocations
	) internal pure {
		if (accounts.length < 2)
			revert InvalidSplit__TooFewAccounts(accounts.length);
		if (accounts.length != percentAllocations.length)
			revert InvalidSplit__AccountsAndAllocationsMismatch(
				accounts.length,
				percentAllocations.length
			);
		// _getSum should overflow if any percentAllocation[i] < 0
		if (_getSum(percentAllocations) != PERCENTAGE_SCALE)
			revert InvalidSplit__InvalidAllocationsSum(_getSum(percentAllocations));
		unchecked {
			// overflow should be impossible in for-loop index
			// cache accounts length to save gas
			uint256 loopLength = accounts.length - 1;
			for (uint256 i = 0; i < loopLength; ++i) {
				// overflow should be impossible in array access math
				if (accounts[i] >= accounts[i + 1])
					revert InvalidSplit__AccountsOutOfOrder(i);
				if (percentAllocations[i] == uint32(0))
					revert InvalidSplit__AllocationMustBePositive(i);
			}
			// overflow should be impossible in array access math with validated equal array lengths
			if (percentAllocations[loopLength] == uint32(0))
				revert InvalidSplit__AllocationMustBePositive(loopLength);
		}
	}

	/// @notice Hashes a split
	/// @param accounts Ordered, unique list of addresses with ownership in the split
	/// @param percentAllocations Percent allocations associated with each address
	/// @return computedHash Hash of the split.
	function _hashSplit(
		address[] memory accounts,
		uint32[] memory percentAllocations
	) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked(accounts, percentAllocations));
	}

	/// @notice Updates an existing split with recipients `accounts` with ownerships `percentAllocations` and a keeper fee for splitting of `distributorFee`
	/// @param split Address of mutable split to update
	/// @param accounts Ordered, unique list of addresses with ownership in the split
	/// @param percentAllocations Percent allocations associated with each address
	function _updateSplit(
		address split,
		address[] calldata accounts,
		uint32[] calldata percentAllocations
	) internal {
		bytes32 splitHash = _hashSplit(accounts, percentAllocations);
		// store new hash in storage for future verification
		_splits[split].hash = splitHash;
		emit UpdateSplit(split);
	}

	/// @notice Checks hash from `accounts`, `percentAllocations` against the hash stored for `split`
	/// @param split Address of hash to check
	/// @param accounts Ordered, unique list of addresses with ownership in the split
	/// @param percentAllocations Percent allocations associated with each address
	function _validSplitHash(
		address split,
		address[] memory accounts,
		uint32[] memory percentAllocations
	) internal view {
		bytes32 hash = _hashSplit(accounts, percentAllocations);
		if (_splits[split].hash != hash) revert InvalidSplit__InvalidHash(hash);
	}

	/// @notice Distributes the ETH balance for split `split`
	/// @dev `accounts`, `percentAllocations`, and `distributorFee` must be verified before calling
	/// @param split Address of split to distribute balance for
	/// @param accounts Ordered, unique list of addresses with ownership in the split
	/// @param percentAllocations Percent allocations associated with each address
	function _distributeETH(
		address split,
		address[] memory accounts,
		uint32[] memory percentAllocations
	) internal {
		uint256 mainBalance = _ethBalances[split];
		uint256 proxyBalance = split.balance;
		// if mainBalance is positive, leave 1 in SplitMain for gas efficiency
		uint256 amountToSplit;
		unchecked {
			// underflow should be impossible
			if (mainBalance > 0) mainBalance -= 1;
			// overflow should be impossible
			amountToSplit = mainBalance + proxyBalance;
		}
		if (mainBalance > 0) _ethBalances[split] = 1;
		// emit event with gross amountToSplit
		emit DistributeETH(split, amountToSplit);

		// flush proxy ETH balance to SplitMain
		// split proxy should be guaranteed to exist at this address after validating splitHash
		// (attacker can't deploy own contract to address with high balance & empty sendETHToMain
		// to drain ETH from SplitMain)
		// could technically check if (change in proxy balance == change in SplitMain balance)
		// before/after external call, but seems like extra gas for no practical benefit

		if (proxyBalance > 0) SplitWallet(split).sendETHToMain(proxyBalance);
		unchecked {
			// distribute remaining balance
			// overflow should be impossible in for-loop index
			// cache accounts length to save gas
			uint256 accountsLength = accounts.length;
			for (uint256 i = 0; i < accountsLength; ++i) {
				uint256 balance = _scaleAmountByPercentage(
					amountToSplit,
					percentAllocations[i]
				);

				if (!_trySendingETH(accounts[i], balance)) {
					// overflow should be impossible with validated allocations
					_ethBalances[accounts[i]] += balance;
				}
			}
		}
	}

	function _convertWETHToUSDCAndDistribute(
		address split,
		address[] memory accounts,
		uint32[] memory percentAllocations
	) internal returns (uint256 usdcToSplit) {
		uint256 wethToSwap;
		uint256 mainBalance = _erc20Balances[WETH9][split];
		uint256 mainETHBalance = _ethBalances[split];
		uint256 proxyBalance = WETH9.balanceOf(split);
		uint256 proxyETHBalance = split.balance;
		unchecked {
			// if mainBalance &/ proxyBalance are positive, leave 1 for gas efficiency
			// underflow should be impossible
			if (proxyBalance > 0) proxyBalance -= 1;
			// underflow should be impossible
			if (mainBalance > 0) {
				mainBalance -= 1;
			}
			if (mainETHBalance > 0) {
				mainETHBalance -= 1;
			}
			// overflow should be impossible
			wethToSwap =
				mainBalance +
				mainETHBalance +
				proxyBalance +
				proxyETHBalance;
			// split proxy should be guaranteed to exist at this address after validating splitHash
			// (attacker can't deploy own contract to address with high ERC20 balance & empty
			// sendERC20ToMain to drain ERC20 from SplitMain)
			// doesn't support rebasing or fee-on-transfer tokens
			// flush extra proxy ERC20 balance to SplitMain
			if (proxyBalance > 0)
				SplitWallet(split).sendERC20ToMain(WETH9, proxyBalance);

			if (proxyETHBalance > 0) {
				SplitWallet(split).sendETHToMain(proxyETHBalance);
				WETH9.deposit{ value: proxyETHBalance }();
			}

			if (mainETHBalance > 0) {
				WETH9.deposit{ value: mainETHBalance }();
			}
		}

		WETH9.approve(address(swap), wethToSwap);
		usdcToSplit = swap.swapWEthForUSDC(wethToSwap);
		unchecked {
			// cache accounts length to save gas
			uint256 accountsLength = accounts.length;
			for (uint256 i = 0; i < accountsLength; ++i) {
				uint256 balance = _scaleAmountByPercentage(
					usdcToSplit,
					percentAllocations[i]
				);

				if (!_trySendingERC20(USDC, accounts[i], balance))
					_erc20Balances[USDC][accounts[i]] += balance;
			}
		}
	}

	function _trySendingETH(
		address account,
		uint256 amount
	) internal returns (bool success) {
		// solhint-disable-next-line check-send-result
		return payable(account).send(amount);
	}

	/// @notice Distributes the ERC20 `token` balance for split `split`
	/// @dev `accounts`, `percentAllocations`, and `distributorFee` must be verified before calling
	/// @dev pernicious ERC20s may cause overflow in this function inside
	/// _scaleAmountByPercentage, but results do not affect ETH & other ERC20 balances
	/// @param split Address of split to distribute balance for
	/// @param token Address of ERC20 to distribute balance for
	/// @param accounts Ordered, unique list of addresses with ownership in the split
	/// @param percentAllocations Percent allocations associated with each address
	function _distributeERC20(
		address split,
		IERC20 token,
		address[] memory accounts,
		uint32[] memory percentAllocations
	) internal {
		uint256 amountToSplit;
		uint256 mainBalance = _erc20Balances[token][split];
		uint256 proxyBalance = token.balanceOf(split);
		unchecked {
			// if mainBalance &/ proxyBalance are positive, leave 1 for gas efficiency
			// underflow should be impossible
			if (proxyBalance > 0) proxyBalance -= 1;
			// underflow should be impossible
			if (mainBalance > 0) {
				mainBalance -= 1;
			}
			// overflow should be impossible
			amountToSplit = mainBalance + proxyBalance;
		}
		if (mainBalance > 0) _erc20Balances[token][split] = 1;
		// emit event with gross amountToSplit (before deducting distributorFee)
		emit DistributeERC20(split, token, amountToSplit);

		// split proxy should be guaranteed to exist at this address after validating splitHash
		// (attacker can't deploy own contract to address with high ERC20 balance & empty
		// sendERC20ToMain to drain ERC20 from SplitMain)
		// doesn't support rebasing or fee-on-transfer tokens
		// flush extra proxy ERC20 balance to SplitMain
		if (proxyBalance > 0)
			SplitWallet(split).sendERC20ToMain(token, proxyBalance);

		// distribute remaining balance
		// overflows should be impossible in for-loop with validated allocations
		unchecked {
			// cache accounts length to save gas
			uint256 accountsLength = accounts.length;
			for (uint256 i = 0; i < accountsLength; ++i) {
				uint256 balance = _scaleAmountByPercentage(
					amountToSplit,
					percentAllocations[i]
				);

				if (!_trySendingERC20(token, accounts[i], balance))
					_erc20Balances[token][accounts[i]] += balance;
			}
		}
	}

	function _trySendingERC20(
		IERC20 token,
		address account,
		uint256 amount
	) internal returns (bool success) {
		// TODO for and modify the solady `safeTransfer` function to return false
		// when the receiver contract doesn't have the right interface
		return token.transfer(account, amount);
	}

	/// @notice Multiplies an amount by a scaled percentage
	/// @param amount Amount to get `scaledPercentage` of
	/// @param scaledPercent Percent scaled by PERCENTAGE_SCALE
	/// @return scaledAmount Percent of `amount`.
	function _scaleAmountByPercentage(
		uint256 amount,
		uint256 scaledPercent
	) internal pure returns (uint256 scaledAmount) {
		// use assembly to bypass checking for overflow & division by 0
		// scaledPercent has been validated to be < PERCENTAGE_SCALE)
		// & PERCENTAGE_SCALE will never be 0
		// pernicious ERC20s may cause overflow, but results do not affect ETH & other ERC20 balances

		// solhint-disable-next-line no-inline-assembly
		assembly ("memory-safe") {
			/* eg (100/// 2*1e4) / (1e6) */
			scaledAmount := div(mul(amount, scaledPercent), PERCENTAGE_SCALE)
		}
	}

	/// @notice Withdraw ETH for account `account`
	/// @param account Account to withdrawn ETH for
	/// @return withdrawn Amount of ETH withdrawn
	function _withdraw(address account) internal returns (uint256 withdrawn) {
		// leave balance of 1 for gas efficiency
		// underflow if ethBalance is 0
		withdrawn = _ethBalances[account] - 1;
		_ethBalances[account] = 1;
		account.safeTransferETH(withdrawn);
	}

	/// @notice Withdraw ERC20 `token` for account `account`
	/// @param account Account to withdrawn ERC20 `token` for
	/// @return withdrawn Amount of ERC20 `token` withdrawn
	function _withdrawERC20(
		address account,
		IERC20 token
	) internal returns (uint256 withdrawn) {
		// leave balance of 1 for gas efficiency
		// underflow if erc20Balance is 0
		withdrawn = _erc20Balances[token][account] - 1;
		_erc20Balances[token][account] = 1;
		address(token).safeTransfer(account, withdrawn);
	}
}
