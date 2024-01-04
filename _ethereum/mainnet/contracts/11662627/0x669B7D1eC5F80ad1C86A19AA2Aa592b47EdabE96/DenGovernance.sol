pragma solidity >=0.5.12;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
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
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
   * @param  interfaceID The ERC-165 interface ID that is queried for support.s
   * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
   *      This function MUST NOT consume more than 5,000 gas.
   * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
   */
  function supportsInterface(bytes4 interfaceID) external view returns (bool);

}

interface IERC1155 {
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _id,
		uint256 _amount,
		bytes calldata _data
	) external;

	function balanceOf(address _owner, uint256 _id) external view returns (uint256);

	function burn(uint256 id, uint256 amount) external;
}

contract DenGovernance is ReentrancyGuard {
	event PeriodAdded(uint256 periodId, uint256 endEpoch, uint256 lotId, uint256 maxIssuance);
	event Staked(address owner, uint256 periodId, uint256 quantity);
	event Withdrawn(address, uint256);

	using SafeMath for uint256;

	struct GovernancePeriod {
		address tokenAddress;
		uint256 amount;
		uint256 startEpoch;
		uint256 endEpoch;
		uint256 lotId;
		uint256 issued;
		uint256 maxIssuance;
		uint256 fee; // 1 decimal allowed Example: 3.5% = 35
		uint256 feesCollected;
		uint256 deposited;
		uint256 withdrawn;
	}

	mapping(uint256 => GovernancePeriod) public governancePeriods;
	mapping(address => bool) public protectedTokens;

	uint256 public totalPeriods;
	address public lotAddress;
	address public denGovernance;

	constructor(address _denGovernance, address _lotAddress) public {
		denGovernance = _denGovernance;
		lotAddress = _lotAddress;
	}

	modifier onlyDenGovernance {
		require(msg.sender == denGovernance, "not owner");
		_;
	}

	function withdrawCollectedFees(uint256 periodId) public nonReentrant() onlyDenGovernance {
		GovernancePeriod storage gp = governancePeriods[periodId];
		uint256 amountToWithdraw = gp.feesCollected;
		gp.feesCollected = 0;
		require(IERC20(gp.tokenAddress).transfer(denGovernance, amountToWithdraw), "token transfer failed");
		emit Withdrawn(denGovernance, amountToWithdraw);
	}

	function stakeForPeriod(uint256 periodId, uint256 quantity) public {
		GovernancePeriod storage gp = governancePeriods[periodId];

		require(block.timestamp >= gp.startEpoch, "period not open");
		require(block.timestamp <= gp.endEpoch, "period has ended");
		require(gp.issued.add(quantity) <= gp.maxIssuance, "requested quantity higher than available");

		uint256 depositAmount = gp.amount.mul(quantity);
		uint256 allowance = IERC20(gp.tokenAddress).allowance(msg.sender, address(this));
		require(allowance >= depositAmount, "You need to set a higher allowance");

		// charge a fee
		uint256 feeAmount = depositAmount.mul(gp.fee).div(1000);
		uint256 maxWithdrawAmount = depositAmount.sub(feeAmount);

		gp.feesCollected = gp.feesCollected.add(feeAmount);
		gp.deposited = gp.deposited.add(maxWithdrawAmount);
		gp.issued = gp.issued.add(quantity);

		require(
			IERC20(gp.tokenAddress).transferFrom(msg.sender, address(this), depositAmount),
			"token transfer failed"
		);
		require(IERC1155(lotAddress).balanceOf(address(this), gp.lotId) >= quantity, "lot not present");
		IERC1155(lotAddress).safeTransferFrom(address(this), msg.sender, gp.lotId, quantity, "");

		emit Staked(msg.sender, periodId, quantity);
	}

	function withdrawable(uint256 periodId) public view returns (bool) {
		if (governancePeriods[periodId].endEpoch >= block.timestamp) return true;
		return false;
	}

	function getOwnerBalance(address owner, uint256 periodId)
		public
		view
		returns (uint256 lotBalance, uint256 lpBalance)
	{
		GovernancePeriod memory gp = governancePeriods[periodId];

		lotBalance = IERC1155(lotAddress).balanceOf(owner, gp.lotId);
		if (lotBalance > gp.issued) return (lotBalance, 0);
		lpBalance = lotBalance.mul(gp.deposited.div(gp.issued));

		return (lotBalance, lpBalance);
	}

	function _createGovernancePeriod(
		address tokenAddress,
		uint256 lotId,
		uint256 maxIssuance,
		uint256 amount,
		uint256 fee,
		uint256 startEpoch,
		uint256 endEpoch
	) internal nonReentrant() {
		require(fee < 1000, "fee is too high");
		require(endEpoch > startEpoch, "end is before start");
		require(endEpoch > block.timestamp, "epoch has passed");
		uint256 periodId = totalPeriods;

		GovernancePeriod memory period =
			GovernancePeriod({
				tokenAddress: tokenAddress,
				amount: amount,
				startEpoch: startEpoch,
				endEpoch: endEpoch,
				lotId: lotId,
				issued: 0,
				maxIssuance: maxIssuance,
				fee: fee,
				feesCollected: 0,
				deposited: 0,
				withdrawn: 0
			});

		protectedTokens[tokenAddress] = true;
		governancePeriods[periodId] = period;
		totalPeriods++;

		emit PeriodAdded(periodId, endEpoch, lotId, maxIssuance);
	}

	function _withdraw(
		address owner,
		uint256 periodId,
		uint256 lotId,
		uint256 amount
	) internal nonReentrant() {
		GovernancePeriod storage gp = governancePeriods[periodId];

		require(block.timestamp >= gp.endEpoch, "period has not ended");
		require(lotId == gp.lotId, "lot sent for period is not correct");
		require(amount <= gp.issued, "invalid amount");

		uint256 withdrawableLp = amount.mul(gp.deposited.div(gp.issued));
		require(gp.withdrawn.add(withdrawableLp) <= gp.deposited, "invalid amount requested");
		gp.withdrawn = gp.withdrawn.add(withdrawableLp);

		IERC1155(lotAddress).burn(gp.lotId, amount);
		require(IERC20(gp.tokenAddress).transfer(owner, withdrawableLp), "token transfer failed");

		emit Withdrawn(owner, amount);
	}

	function sweep(address token) external onlyDenGovernance {
		require(!protectedTokens[token], "token is protected");
		IERC20(token).transfer(denGovernance, IERC20(token).balanceOf(address(this)));
	}

	// bytes4(keccak256(_createGovernancePeriod()));
	bytes4 internal constant CREATEPERIOD_SIG = 0xa3b05fe3;

	// bytes4(keccak256(_withdraw(uint256)));
	bytes4 internal constant WITHDRAW_SIG = 0xac6a2b5d;

	/**
	 * @dev Will pass to onERC1155Batch5Received
	 */
	function onERC1155Received(
		address _operator,
		address _from,
		uint256 _id,
		uint256 _amount,
		bytes memory _data
	) public returns (bytes4) {
		uint256[] memory ids = new uint256[](1);
		uint256[] memory amounts = new uint256[](1);

		ids[0] = _id;
		amounts[0] = _amount;

		require(
			this.onERC1155BatchReceived.selector == onERC1155BatchReceived(_operator, _from, ids, amounts, _data),
			"invalid on receive message"
		);

		return this.onERC1155Received.selector;
	}

	function onERC1155BatchReceived(
		address _operator,
		address _from,
		uint256[] memory _ids,
		uint256[] memory _amounts,
		bytes memory _data
	) public returns (bytes4) {
		// Transferred token needs to be LOT
		require(msg.sender == address(lotAddress), "invalid token address");
		require(_ids.length == 1, "invalid LOT amount");

		// Obtain method to call via object signature
		bytes4 functionSignature = abi.decode(_data, (bytes4));

		/***********************************|
        |            Deposit LOT            |
        |__________________________________*/

		if (functionSignature == CREATEPERIOD_SIG) {
			require(_operator == denGovernance, "operator must be den governance");

			(, address tokenAddress, uint256 amount, uint256 fee, uint256 startEpoch, uint256 endEpoch) =
				abi.decode(_data, (bytes4, address, uint256, uint256, uint256, uint256));
			// 0xa3b05fe300000000000000000000000000000000000000000000000000000000
			_createGovernancePeriod(tokenAddress, _ids[0], _amounts[0], amount, fee, startEpoch, endEpoch);

			/***********************************|
            |           Withdraw LOT            |
            |__________________________________*/
		} else if (functionSignature == WITHDRAW_SIG) {
			(, uint256 periodId) = abi.decode(_data, (bytes4, uint256));

			_withdraw(_from, periodId, _ids[0], _amounts[0]);
		} else {
			revert("invalid method");
		}

		// Return success
		return this.onERC1155BatchReceived.selector;
	}

	function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
		return
			interfaceID == 0x01ffc9a7 || // ERC-165 support
			interfaceID == 0x4e2312e0; // ERC-1155 `ERC1155TokenReceiver` support
	}
}