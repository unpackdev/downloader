// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./ERC1155PausableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";

contract DigiAssets is
	Initializable,
	ContextUpgradeable,
	OwnableUpgradeable,
	ERC1155BurnableUpgradeable,
	ERC1155PausableUpgradeable,
	ERC1155SupplyUpgradeable
{
	using SafeERC20Upgradeable for IERC20Upgradeable;
	
	function initialize(string memory uri, address alphaTokenContract) public virtual initializer {
		__Context_init_unchained();
		__ERC165_init_unchained();
		__Ownable_init_unchained();
		__ERC1155_init_unchained(uri);
		__ERC1155Burnable_init_unchained();
		__Pausable_init_unchained();
		__ERC1155Pausable_init_unchained();
		__ERC1155Supply_init_unchained();

		setInventoryManager(_msgSender());

		_alphaTokenContract = IERC20Upgradeable(alphaTokenContract);
	}
	
	IERC20Upgradeable private _alphaTokenContract;
	address private _inventoryManager;

	struct assetStruct {
		uint256 Category;
		uint256 Rarity;
		uint256 Price;
		uint256 Limit;
	}

	mapping(uint256 => assetStruct) private _assetInventory;

	event InventoryChanged(uint256 id, uint256 Category, uint256 price, uint256 limit);
	event InventoryManagerTransferred(address indexed oldManager, address indexed newManager);

	function fetchSaleFunds() external onlyOwner {
		payable(_msgSender()).transfer(address(this).balance);
	}

	function fetchAlphaToken() external onlyOwner {
		_alphaTokenContract.safeTransfer(_msgSender(), _alphaTokenContract.balanceOf(address(this)));
	}
	function pause() public virtual onlyOwner {
		_pause();
	}

	function unpause() public virtual onlyOwner {
		_unpause();
	}

	modifier onlyInventoryManager() {
		require(inventoryManager() == _msgSender(), "caller is not the inventory manager");
		_;
	}

	function setInventoryManager(address newManager) public onlyOwner {
		address oldManager = _inventoryManager;
		_inventoryManager = newManager;
		emit InventoryManagerTransferred(oldManager, newManager);
	}

	function inventoryManager() public view returns (address) {
		return _inventoryManager;
	}

	function getInventory(uint256 id) public view returns (assetStruct memory) {
		return _assetInventory[id];
	}

	function setInventory(
		uint256[] memory ids,
		uint256[] memory categories,
		uint256[] memory rarities,
		uint256[] memory prices,
		uint256[] memory limits
	) external onlyInventoryManager {
		require(
			ids.length == categories.length &&
			ids.length == rarities.length &&
			ids.length == prices.length &&
			ids.length == limits.length,
			"`ids`, `categories`, `rarities`, `prices` and `limits` must have the same length"
		);

		for (uint8 i = 0; i < ids.length; i++){
			uint256 id = ids[i];
			uint256 category = categories[i];
			uint256 rarity = rarities[i];
			uint256 price = prices[i];
			uint256 limit = limits[i];

			assetStruct memory assetInventory;

			assetInventory.Category = category;
			assetInventory.Rarity = rarity;
			assetInventory.Price = price;
			assetInventory.Limit = limit;

			_assetInventory[id] = assetInventory;

			emit InventoryChanged(id, category, price, limit);
		}
	}

	function mint(
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) external {
		require(totalSupply(id)+amount <= _assetInventory[id].Limit, 'Amount exceeds limit');

		_alphaTokenContract.safeTransferFrom(_msgSender(), address(this), _assetInventory[id].Price * amount);

		_mint(to, id, amount, data);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC1155Upgradeable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual override(ERC1155Upgradeable, ERC1155PausableUpgradeable, ERC1155SupplyUpgradeable) {
		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

	}
	uint256[50] private __gap;
}
