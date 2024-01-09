
// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "LinearMath.sol";

interface IERC20 {
	function approve(address spender, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
	function balanceOf(address owner) external view returns (uint256);
	function totalSupply() external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeERC20 {
	using Address for address;

	function safeTransfer(IERC20 token, address to, uint256 value) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
	}

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

	/**
	* @dev Deprecated. This function has issues similar to the ones found in
	* {IERC20-approve}, and its usage is discouraged.
	*
	* Whenever possible, use {safeIncreaseAllowance} and
	* {safeDecreaseAllowance} instead.
	*/
	function safeApprove(IERC20 token, address spender, uint256 value) internal {
		// safeApprove should only be called when setting an initial allowance,
		// or when resetting it to zero. To increase and decrease it, use
		// 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
		// solhint-disable-next-line max-line-length
		require((value == 0) || (token.allowance(address(this), spender) == 0),
			"SafeERC20: approve from non-zero to non-zero allowance"
		);
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
	}

	/**
	* @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
	* on the return value: the return value is optional (but if data is returned, it must not be false).
	* @param token The token targeted by the call.
	* @param data The call data (encoded using abi.encode or one of its variants).
	*/
	function _callOptionalReturn(IERC20 token, bytes memory data) private {
		// We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
		// we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
		// the target address contains contract code and also asserts for success in the low-level call.

		bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
		if (returndata.length > 0) { // Return data is optional
			// solhint-disable-next-line max-line-length
			require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
		}
	}
}

library Address {
	/**
	* @dev Returns true if `account` is a contract.
	*
	* [IMPORTANT]
	* ====
	* It is unsafe to assume that an address for which this function returns
	* false is an externally-owned account (EOA) and not a contract.
	*
	* Among others, `isContract` will return false for the following
	* types of addresses:
	*
	*  - an externally-owned account
	*  - a contract in construction
	*  - an address where a contract will be created
	*  - an address where a contract lived, but was destroyed
	* ====
	*/
	function isContract(address account) internal view returns (bool) {
		// This method relies on extcodesize, which returns 0 for contracts in
		// construction, since the code is only stored at the end of the
		// constructor execution.

		uint256 size;
		// solhint-disable-next-line no-inline-assembly
		assembly { size := extcodesize(account) }
		return size > 0;
	}

	/**
	* @dev Performs a Solidity function call using a low level `call`. A
	* plain`call` is an unsafe replacement for a function call: use this
	* function instead.
	*
	* If `target` reverts with a revert reason, it is bubbled up by this
	* function (like regular Solidity function calls).
	*
	* Returns the raw returned data. To convert to the expected return value,
	* use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
	*
	* Requirements:
	*
	* - `target` must be a contract.
	* - calling `target` with `data` must not revert.
	*
	* _Available since v3.1._
	*/
	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCall(target, data, "Address: low-level call failed");
	}

	/**
	* @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
	* `errorMessage` as a fallback revert reason when `target` reverts.
	*
	* _Available since v3.1._
	*/
	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	/**
	* @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	* but also transferring `value` wei to `target`.
	*
	* Requirements:
	*
	* - the calling contract must have an ETH balance of at least `value`.
	* - the called Solidity function must be `payable`.
	*
	* _Available since v3.1._
	*/
	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}

	/**
	* @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
	* with `errorMessage` as a fallback revert reason when `target` reverts.
	*
	* _Available since v3.1._
	*/
	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.call{ value: value }(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
		if (success) {
			return returndata;
		} else {
			// Look for revert reason and bubble it up if present
			if (returndata.length > 0) {
				// The easiest way to bubble the revert reason is using memory via assembly

				// solhint-disable-next-line no-inline-assembly
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

interface IUniswapV3Pair {
	function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

struct FundManagement {
	address sender;
	bool fromInternalBalance;
	address payable recipient;
	bool toInternalBalance;
}

enum SwapKind { GIVEN_IN, GIVEN_OUT }

struct SingleSwap {
	bytes32 poolId;
	SwapKind kind;
	address assetIn;
	address assetOut;
	uint256 amount;
	bytes userData;
}

interface IVault {
    function getPoolTokens(bytes32 poolD) external view returns (address[] memory, uint256[] memory);
	function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline) external payable returns (uint256);
}

interface WAToken {
	function staticToDynamicAmount(uint256) external view returns (uint256);
	function deposit(address, uint256, uint16, bool) external returns (uint256);
	function withdraw(address, uint256, bool) external returns (uint256, uint256);
}

interface LinearPool {
   	//BasePool
	function getPoolId() external view returns (bytes32);
	function getSwapFeePercentage() external view returns (uint256);
	function getScalingFactors() external view returns (uint256[] memory);

	//LinearPool
	function getMainToken() external view returns (address);
	function getWrappedToken() external view returns (address);
	function getBptIndex() external view returns (uint256);
	function getMainIndex() external view returns (uint256);
	function getWrappedIndex() external view returns (uint256);
	function getRate() external view returns (uint256);
	function getWrappedTokenRate() external view returns (uint256);
	function getTargets() external view returns (uint256 lowerTarget, uint256 upperTarget);
}

contract Rebalancer {
    using SafeERC20 for IERC20;

    uint256 private constant MAX_UINT = 2 ** 256 - 1;

    IVault constant private VAULT = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    IUniswapV3Pair constant private DAI_POOL = IUniswapV3Pair(0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168);
	IUniswapV3Pair constant private USDC_USDT_POOL = IUniswapV3Pair(0x3416cF6C708Da44DB2624D63ea0AAef7113527C6);

	address constant private DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant private USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
	address constant private USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

	address constant private WDAI = 0x02d60b84491589974263d922D9cC7a3152618Ef6;
	address constant private WUSDC = 0xd093fA4Fb80D09bB30817FDcd442d4d02eD3E5de;
	address constant private WUSDT = 0xf8Fd466F12e236f4c96F7Cce6c79EAdB819abF58;

    uint256 constant private ONE = 10**18;

	constructor() {
		IERC20(DAI).approve(address(WDAI), MAX_UINT);
		IERC20(USDC).approve(address(WUSDC), MAX_UINT);
		IERC20(USDT).safeApprove(address(WUSDT), MAX_UINT);

		IERC20(DAI).approve(address(VAULT), MAX_UINT);
		IERC20(USDC).approve(address(VAULT), MAX_UINT);
		IERC20(USDT).safeApprove(address(VAULT), MAX_UINT);

		IERC20(WDAI).approve(address(VAULT), MAX_UINT);
		IERC20(WUSDC).approve(address(VAULT), MAX_UINT);
		IERC20(WUSDT).approve(address(VAULT), MAX_UINT);
	}

    function rebalance(LinearPool _pool, uint256 _desiredBalance) public payable {
        (SingleSwap memory _swap, uint256 _amountInNeededForSwap) = getSwapAndAmountInNeeded(_pool, _desiredBalance);
        address _mainToken = _swap.kind == SwapKind.GIVEN_IN ? _swap.assetIn : _swap.assetOut;

        // perform flash loan
        IUniswapV3Pair _uniswapPool = _mainToken == DAI ? DAI_POOL : USDC_USDT_POOL;
        uint256 _amountNeededForFlashLoan = _swap.kind == SwapKind.GIVEN_IN ? _amountInNeededForSwap : WAToken(address(_swap.assetIn)).staticToDynamicAmount(_amountInNeededForSwap);
        bytes memory _swapData = abi.encode(_swap, _amountNeededForFlashLoan, _amountInNeededForSwap, msg.sender);
        if (_mainToken == USDT) _uniswapPool.flash(address(this), 0, _amountNeededForFlashLoan, _swapData);
        else _uniswapPool.flash(address(this), _amountNeededForFlashLoan, 0, _swapData);
    }

    function getSwapAndAmountInNeeded(LinearPool _pool, uint256 _desiredBalance) public view returns (SingleSwap memory _swap, uint256 _amountInNeededForSwap) {
        LinearMath.Params memory _params = LinearMath.Params({
            fee: _pool.getSwapFeePercentage(),
            lowerTarget: 0,
            upperTarget: 0
        });
        (_params.lowerTarget, _params.upperTarget) = _pool.getTargets();
        uint256[] memory _scalingFactors = _pool.getScalingFactors();
        uint256 _mainTokenIndex = _pool.getMainIndex();
        (address[] memory _tokenAddresses, uint256[] memory _tokenBalances) = VAULT.getPoolTokens(_pool.getPoolId());
        uint256 _mainTokenBalance = _tokenBalances[_mainTokenIndex];

        if (_desiredBalance == 0) {
			uint256 _scaledUpperTarget = _params.upperTarget * ONE / _scalingFactors[_mainTokenIndex];
			uint256 _scaledLowerTarget = _params.upperTarget * ONE / _scalingFactors[_mainTokenIndex];

            if (_mainTokenBalance > _scaledUpperTarget) {
                _desiredBalance = _scaledUpperTarget;
            } else if (_mainTokenBalance < _scaledLowerTarget) {
                _desiredBalance = _scaledLowerTarget;
            } else {
				revert("Already in range and no desired balance specified");
			}
        }

        // calculate amount needed.
        uint256 _swapAmount = _mainTokenBalance < _desiredBalance ? _desiredBalance - _mainTokenBalance : _mainTokenBalance - _desiredBalance;
        _amountInNeededForSwap = _mainTokenBalance < _desiredBalance ? _swapAmount : getWrappedInForMainOut(_swapAmount, _mainTokenBalance * _scalingFactors[_mainTokenIndex] / ONE, _scalingFactors[_mainTokenIndex], _scalingFactors[_pool.getWrappedIndex()], _params);
        _swap = SingleSwap(
			_pool.getPoolId(),
			_mainTokenBalance > _desiredBalance ? SwapKind.GIVEN_OUT : SwapKind.GIVEN_IN,
			_mainTokenBalance > _desiredBalance ? _tokenAddresses[_pool.getWrappedIndex()] : _tokenAddresses[_mainTokenIndex],
			_mainTokenBalance > _desiredBalance ? _tokenAddresses[_mainTokenIndex] : _tokenAddresses[_pool.getWrappedIndex()],
			_swapAmount,
			new bytes(0)
		);
        return (_swap, _amountInNeededForSwap);
    }

    // Uniswap V3 Flash Callback
	function uniswapV3FlashCallback(uint256, uint256, bytes calldata _data) external payable {
		(SingleSwap memory _swap, uint256 _initialAmount, uint256 _requiredBalance, address _msgSender) = abi.decode(_data, (SingleSwap, uint256, uint256, address));
		address mainToken = address(_swap.kind == SwapKind.GIVEN_IN ? _swap.assetIn : _swap.assetOut);
		require(msg.sender == address(DAI_POOL) || msg.sender == address(USDC_USDT_POOL), "bad 3. no");
		require(IERC20(mainToken).balanceOf(address(this)) >= _initialAmount, "Flash loan didnt do it");

		doSwap(_swap, _initialAmount, _requiredBalance);

		uint256 _repayment = _initialAmount + (_initialAmount / 10000) + 1;
	
        uint256 _balance = IERC20(mainToken).balanceOf(address(this));
        if (_balance < _repayment) {
            uint256 _deficit = _repayment - _balance;
            IERC20(mainToken).safeTransferFrom(_msgSender, address(this), _deficit);
        }

		IERC20(mainToken).safeTransfer(msg.sender, _repayment);
	}

    function getWrappedInForMainOut(uint256 _mainOut, uint256 _mainBalance, uint256 _mainScalingFactor, uint256 _wrappedScalingFactor, LinearMath.Params memory _params) public pure returns (uint256) {
        _mainOut = _mainOut * _mainScalingFactor / ONE;

        uint256 amountIn = LinearMath._calcWrappedInPerMainOut(_mainOut, _mainBalance, _params);

        return (((amountIn * ONE) - 1) /  _wrappedScalingFactor) + 1;
    }

    function getWrappedOutForMainIn(uint256 _mainIn, uint256 _mainBalance, uint256 _mainScalingFactor, uint256 _wrappedScalingFactor, LinearMath.Params memory _params) public pure returns (uint256) {
        _mainIn = _mainIn * _mainScalingFactor / ONE;

        uint256 amountOut = LinearMath._calcWrappedOutPerMainIn(_mainIn, _mainBalance, _params);

        return amountOut * ONE / _wrappedScalingFactor;
    }

    function estimateDeficitRequirement(LinearPool _pool, uint256 _desiredBalance) external view returns (uint256) {
        (SingleSwap memory _swap, uint256 _amountInNeededForSwap) = getSwapAndAmountInNeeded(_pool, _desiredBalance);

        uint256 _amountNeededForFlashLoan = _swap.kind == SwapKind.GIVEN_IN ? _amountInNeededForSwap : WAToken(address(_swap.assetIn)).staticToDynamicAmount(_amountInNeededForSwap);
		_amountNeededForFlashLoan += (_amountNeededForFlashLoan / 10000) + 1;

		uint256 _amountOut =  _swap.amount;
		if (_swap.kind == SwapKind.GIVEN_IN) {
			LinearMath.Params memory _params = LinearMath.Params({
				fee: _pool.getSwapFeePercentage(),
				lowerTarget: 0,
				upperTarget: 0
			});
			(_params.lowerTarget, _params.upperTarget) = _pool.getTargets();
			uint256[] memory _scalingFactors = _pool.getScalingFactors();
			uint256 _mainTokenIndex = _pool.getMainIndex();
			uint256 _wrappedTokenIndex = _pool.getWrappedIndex();
			(, uint256[] memory _tokenBalances) = VAULT.getPoolTokens(_pool.getPoolId());
			uint256 _mainTokenBalance = _tokenBalances[_mainTokenIndex];
			_amountOut = getWrappedOutForMainIn(_swap.amount, _mainTokenBalance, _scalingFactors[_mainTokenIndex], _scalingFactors[_wrappedTokenIndex], _params);
			_amountOut = WAToken(address(_swap.assetOut)).staticToDynamicAmount(_amountOut);
		}

		return _amountOut >= _amountNeededForFlashLoan ? 0 : _amountNeededForFlashLoan - _amountOut;
    }

    function doSwap(SingleSwap memory swap, uint256 _initialAmount, uint256 _requiredBalance) private {
		uint256 limit = swap.kind == SwapKind.GIVEN_IN ? 0 : MAX_UINT;
		FundManagement memory fundManagement = FundManagement(address(this), false, payable(address(this)), false);
		if (swap.kind == SwapKind.GIVEN_OUT) wrapToken(address(swap.assetIn), _initialAmount);
		require(IERC20(swap.assetIn).balanceOf(address(this)) >= _requiredBalance, "Not enough asset in balance");
		VAULT.swap(swap, fundManagement, limit, block.timestamp);
		if (swap.kind == SwapKind.GIVEN_IN) unwrapToken(address(swap.assetOut), IERC20(swap.assetOut).balanceOf(address(this)));
	}

	function wrapToken(address _wrappedToken, uint256 _amount) private {
		WAToken(_wrappedToken).deposit(address(this), _amount, 0, true);
	}

	function unwrapToken(address _wrappedToken, uint256 _amount) private {
		WAToken(_wrappedToken).withdraw(address(this), _amount, true);
	}

	receive() payable external {}
}