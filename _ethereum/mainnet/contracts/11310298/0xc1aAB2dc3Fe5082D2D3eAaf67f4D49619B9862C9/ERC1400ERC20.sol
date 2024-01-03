pragma solidity 0.6.6;

import "./IERC20.sol";

import "./ERC1400Partition.sol";
import "./IERC1400Raw.sol";


/**
 * @author Simon Dosch
 * @title ERC1400ERC20
 * @dev Expands ERC1400s function by those of the ERC20 standard
 */
contract ERC1400ERC20 is ERC1400Partition, IERC20 {
	/**
	 * @dev Returns the ERC20 decimal property as 0
	 * @return uint8 Always returns decimals as 0
	 */
	function decimals() external pure returns (uint8) {
		return uint8(0);
	}

	/**
	 * @dev Returns the amount of tokens in existence.
	 */
	function totalSupply() public override view returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev Returns the amount of tokens owned by `account`.
	 */
	function balanceOf(address who) public override view returns (uint256) {
		return _balances[who];
	}

	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transfer(address to, uint256 value)
		external
		override
		returns (bool)
	{
		_transferFromTotalPartitions(
			_msgSender(),
			_msgSender(),
			to,
			value,
			"",
			""
		);
		// emitted in _transferByPartition
		// emit Transfer(_msgSender(), to, value);		return true;
	}

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender)
		external
		override
		view
		returns (uint256)
	{
		return _allowances[owner][spender];
	}

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits an {Approval} event.
	 */
	function approve(address spender, uint256 value)
		external
		override
		returns (bool)
	{
		// Transfer Blocked - Sender not eligible
		require(spender != address(0), "zero address");

		// mitigate https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
		_allowances[_msgSender()][spender] = 0;

		_allowances[_msgSender()][spender] = value;

		emit Approval(_msgSender(), spender, value);
		return true;
	}

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
		address from,
		address to,
		uint256 value
	) external override returns (bool) {
		// check if is operator by partition or has enough allowance here
		require(value <= _allowances[from][_msgSender()], "allowance too low");
		// Transfer Blocked - Identity restriction

		_allowances[from][_msgSender()] = _allowances[from][_msgSender()].sub(
			value
		);

		// transfer by partition
		_transferFromTotalPartitions(from, from, to, value, "", "");

		// emitted in _transferByPartition
		// emit Transfer(_msgSender(), to, value);
		return true;
	}
}
