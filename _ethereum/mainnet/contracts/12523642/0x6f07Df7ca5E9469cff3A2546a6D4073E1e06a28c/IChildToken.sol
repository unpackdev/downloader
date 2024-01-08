pragma solidity 0.6.6;

interface IChildToken {
	/**
	 * @notice called when tokens are deposited on root chain
	 * @dev Should be callable only by ChildChainManager
	 * Should handle deposit by minting the required tokens for user
	 * Make sure minting is done only by this function
	 * @param user user address for whom deposit is being done
	 * @param depositData abi encoded ids array and amounts array
	 */
	function deposit(address user, bytes calldata depositData) external;

	/**
	 * @notice called when user wants to withdraw single token back to root chain
	 * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
	 * @param id id to withdraw
	 * @param amount amount to withdraw
	 */
	function withdrawSingle(uint256 id, uint256 amount) external;

	/**
	 * @notice called when user wants to batch withdraw tokens back to root chain
	 * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
	 * @param ids ids to withdraw
	 * @param amounts amounts to withdraw
	 */
	function withdrawBatch(uint256[] calldata ids, uint256[] calldata amounts) external;

	/**
	 * @notice See definition of `_mint` in ERC1155 contract
	 * @dev This implementation only allows admins to mint tokens
	 * but can be changed as per requirement
	 */
	function mint(
		address account,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external;

	/**
	 * @notice See definition of `_mintBatch` in ERC1155 contract
	 * @dev This implementation only allows admins to mint tokens
	 * but can be changed as per requirement
	 */
	function mintBatch(
		address to,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		bytes calldata data
	) external;

	/**
	 * @notice See definition of `_burn` in ERC1155 contract
	 * @dev This implementation only allows user to burn only own or approved token
	 */
	function burn(
		address account,
		uint256 id,
		uint256 value
	) external;

	/**
	 * @notice Return the owner of contract, the who create collection and have DEFAULT_ADMIN_ROLE
	 * @dev This function required by opensea.io to correctly shown the owner of collection
	 */
	function owner() external view returns (address);
}
