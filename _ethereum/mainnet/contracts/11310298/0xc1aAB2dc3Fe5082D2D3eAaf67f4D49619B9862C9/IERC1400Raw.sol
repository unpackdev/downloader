pragma solidity 0.6.6;


/**
 * @title IERC1400Raw token standard
 * @dev ERC1400Raw interface
 */
interface IERC1400Raw {
	/**
	 * [ERC1400Raw INTERFACE (1/13)]
	 * @dev Get the name of the token, e.g., "MyToken".
	 * @return Name of the token.
	 */
	function name() external view returns (string memory); // 1/13

	/**
	 * [ERC1400Raw INTERFACE (2/13)]
	 * @dev Get the symbol of the token, e.g., "MYT".
	 * @return Symbol of the token.
	 */
	function symbol() external view returns (string memory); // 2/13

	// implemented in ERC20
	// function totalSupply() external view returns (uint256); // 3/13
	// function balanceOf(address owner) external view returns (uint256); // 4/13

	/**
	 * [ERC1400Raw INTERFACE (5/13)]
	 * @dev Get the smallest part of the token that’s not divisible.
	 * @return The smallest non-divisible part of the token.
	 */
	function granularity() external view returns (uint256); // 5/13

	/**
	 * [ERC1400Raw INTERFACE (6/13)]
	 * @dev Get the list of controllers
	 * @return List of addresses of all the controllers.
	 */
	// function controllers() external view returns (address[] memory); // 6/13

	/**
	 * [ERC1400Raw INTERFACE (7/13)]
	 * @dev Set a third party operator address as an operator of 'msg.sender' to transfer
	 * and redeem tokens on its behalf.
	 * @param operator Address to set as an operator for 'msg.sender'.
	 */
	function authorizeOperator(address operator) external; // 7/13

	/**
	 * [ERC1400Raw INTERFACE (8/13)]
	 * @dev Remove the right of the operator address to be an operator for 'msg.sender'
	 * and to transfer and redeem tokens on its behalf.
	 * @param operator Address to rescind as an operator for 'msg.sender'.
	 */
	function revokeOperator(address operator) external; // 8/13

	/**
	 * [ERC1400Raw INTERFACE (9/13)]
	 * @dev Indicate whether the operator address is an operator of the tokenHolder address.
	 * @param operator Address which may be an operator of tokenHolder.
	 * @param tokenHolder Address of a token holder which may have the operator address as an operator.
	 * @return 'true' if operator is an operator of 'tokenHolder' and 'false' otherwise.
	 */
	function isOperator(address operator, address tokenHolder)
		external
		view
		returns (bool); // 9/13

	/**
	 * [ERC1400Raw INTERFACE (10/13)]
	 * function transferWithData
	 * is overridden in ERC1400Partition
	 */

	/**
	 * [ERC1400Raw INTERFACE (11/13)]
	 * function transferFromWithData
	 * is overridden in ERC1400Partition
	 */

	/**
	 * [ERC1400Raw INTERFACE (12/13)]
	 * function redeem
	 * is not needed when using ERC1400Partition
	 */

	/**
	 * [ERC1400Raw INTERFACE (13/13)]
	 * function redeemFrom
	 * is not needed when using ERC1400Partition
	 */

	/**
	 * @dev Event emitted when tokens are transferred with data
	 */
	event TransferWithData(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256 value,
		bytes data,
		bytes operatorData
	);

	/**
	 * @dev Event emitted when tokens are issued
	 */
	event Issued(
		address indexed operator,
		address indexed to,
		uint256 value,
		bytes data,
		bytes operatorData
	);

	/**
	 * @dev Event emitted when tokens are redeemed
	 */
	event Redeemed(
		address indexed operator,
		address indexed from,
		uint256 value,
		bytes data,
		bytes operatorData
	);

	/**
	 * @dev Event emitted when an operator is authorized
	 */
	event AuthorizedOperator(
		address indexed operator,
		address indexed tokenHolder
	);

	/**
	 * @dev Event emitted when an operator authorization is revoked
	 */
	event RevokedOperator(
		address indexed operator,
		address indexed tokenHolder
	);
}
