pragma solidity 0.6.6;

import "./ERC1155Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC20.sol";
import "./AccessControlMixin.sol";
import "./IChildToken.sol";
import "./NativeMetaTransaction.sol";
import "./ContextMixin.sol";

contract ChildMintableERC1155 is
	ERC1155Upgradeable,
	IChildToken,
	AccessControlMixin,
	NativeMetaTransaction,
	ContextMixin
{
	bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

	string public name;

	/**
	 * @notice This function replace the constructor and should be called  once after contact creation
	 * @dev setting up collection info and permissions
	 * @param _name collection name
	 * @param uri_ basic URI for collection
	 * @param owner_ the owner of collection which have DEFAULT_ADMIN_ROLE
	 * @param childChainManager abi encoded ids array and amounts array
	 */
	function initialize(
		string memory _name,
		string memory uri_,
		address owner_,
		address childChainManager
	) public initializer {
		name = _name;

		__ERC1155_init(uri_);

		_setupContractId("ChildMintableERC1155");
		_setupRole(DEFAULT_ADMIN_ROLE, owner_);
		_setupRole(DEPOSITOR_ROLE, childChainManager);
		_initializeEIP712(uri_);
	}

	/**
	 * @notice called when tokens are deposited on root chain
	 * @dev Should be callable only by ChildChainManager
	 * Should handle deposit by minting the required tokens for user
	 * Make sure minting is done only by this function
	 * @param user user address for whom deposit is being done
	 * @param depositData abi encoded ids array and amounts array
	 */
	function deposit(address user, bytes calldata depositData)
		external
		override
		only(DEPOSITOR_ROLE)
	{
		(uint256[] memory ids, uint256[] memory amounts, bytes memory data) =
			abi.decode(depositData, (uint256[], uint256[], bytes));
		require(user != address(0), "ChildMintableERC1155: INVALID_DEPOSIT_USER");
		_mintBatch(user, ids, amounts, data);
	}

	/**
	 * @notice called when user wants to withdraw single token back to root chain
	 * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
	 * @param id id to withdraw
	 * @param amount amount to withdraw
	 */
	function withdrawSingle(uint256 id, uint256 amount) external override {
		_burn(_msgSender(), id, amount);
	}

	/**
	 * @notice called when user wants to batch withdraw tokens back to root chain
	 * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
	 * @param ids ids to withdraw
	 * @param amounts amounts to withdraw
	 */
	function withdrawBatch(uint256[] calldata ids, uint256[] calldata amounts) external override {
		_burnBatch(_msgSender(), ids, amounts);
	}

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
	) external override only(DEFAULT_ADMIN_ROLE) {
		_mint(account, id, amount, data);
	}

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
	) external override only(DEFAULT_ADMIN_ROLE) {
		_mintBatch(to, ids, amounts, data);
	}

	/**
	 * @notice See definition of `_burn` in ERC1155 contract
	 * @dev This implementation only allows user to burn only own or approved token
	 */
	function burn(
		address account,
		uint256 id,
		uint256 value
	) public virtual override {
		require(
			account == _msgSender() || isApprovedForAll(account, _msgSender()),
			"ChildMintableERC1155: caller is not owner nor approved"
		);
		_burn(account, id, value);
	}

	/**
	 * @notice Return the owner of contract, the who create collection and have DEFAULT_ADMIN_ROLE
	 * @dev This function required by opensea.io to correctly shown the owner of collection
	 */
	function owner() public view override returns (address) {
		return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
	}

	// This is to support Native meta transactions
	// never use msg.sender directly, use _msgSender() instead
	function _msgSender() internal view override returns (address payable sender) {
		return ContextMixin.msgSender();
	}
}
