// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Cards Minter
/// @author Studio Avante
/// @notice Mints new Game Cards for Endless Crawler
/// @dev Depends on upgradeable ICardsStore contract, containing all the available cards data
pragma solidity ^0.8.16;
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./ICardsStore.sol";

contract CardsMinter is ERC1155, ERC1155Burnable, ERC1155Supply, Ownable {

	bool private _paused;

	/// @notice The current ICardsStore contract
	ICardsStore public _store;

	/// @notice Emitted when contract is paused/unpaused
	/// @param paused True if the contract was paused, False if it was unpaused
	event Paused(bool indexed paused);

	/// @notice Emitted when the Store contract is updated
	/// @param store The new Store contract address
	/// @param version The new Store contract version
	event SetStore(address indexed store, uint8 indexed version);

	/// @notice Emitted when a new card is minted
	/// @param account The owner of the new card
	/// @param id Token id
	/// @param id Amount minted
	event Minted(address indexed account, uint256 indexed id, uint256 amount);

	/// @notice Emitted when a new card is burned
	/// @param account The owner of the burned card
	/// @param id Token id
	/// @param id Amount burned
	event Burned(address indexed account, uint256 indexed id, uint256 amount);

	constructor(address store) ERC1155('') {
		setStore(store);
	}

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

	//---------------
	// Public
	//

	/// @notice Check if the purchases are paused
	/// @return bool True if paused, False if unpaused
	function isPaused() public view returns (bool) {
		return _paused;
	}

	/// @notice Returns a Token unit price, not considering availability
	/// @param id Token id
	/// @return price Price of the token, in WEI
	function getPrice(uint256 id) external view returns (uint256) {
		return _store.getCardPrice(id);
	}

	/// @notice Run all require tests for a successful purchase()
	/// @param id Token id
	/// @param value Value that will be sent to purchase(), in WEI
	/// @return bool True if purchase is allowed, False if not
	/// @return reason The reason when purchase now allowed
	function canPurchase(uint256 id, uint256 value) public view returns (bool, string memory) {
		if (_paused) {
			return (false, 'Paused');
		}
		try _store.beforeMint(id, totalSupply(id), balanceOf(msg.sender, id), value) {
			return (true, '');
		} catch Error(string memory reason_) {
			return (false, reason_);
		}
	}

	/// @notice Purchases 1 Token for the Sender. The message value must be equal or higher than getPrice(id)
	/// @param id Token id
	/// @param data Nevermind, use []
  function purchase(uint256 id, bytes memory data) public payable {
    require(!_paused, 'Paused');
    _store.beforeMint(id, totalSupply(id), balanceOf(msg.sender, id), msg.value);
    _mint(msg.sender, id, 1, data);
    emit Minted(msg.sender, id, 1);
  }

	/// @notice Burn tokens. Sender must be owner or approved
	/// @param id Token id
	/// @param amount The amount of tokens to burn
	function burn(uint256 id, uint256 amount) public {
		ERC1155Burnable.burn(msg.sender, id, amount);
		emit Burned(msg.sender, id, amount);
	}

	/// @notice Returns a token metadata, compliant with ERC1155Metadata_URI
	/// @param id Token id
	/// @return metadata Token metadata, as json string base64 encoded
	function uri(uint256 id) public view override returns (string memory) {
		return _store.uri(id);
	}

	//---------------
	// Admin
	//

	///@notice admin function
	function setStore(address store) public onlyOwner {
		_store = ICardsStore(store);
		emit SetStore(store, _store.getVersion());
	}

	///@notice admin function
	function setPaused(bool paused_) public onlyOwner {
		_paused = paused_;
		emit Paused(_paused);
	}

	///@notice admin function
  function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
    _mint(account, id, amount, data);
    emit Minted(account, id, amount);
  }

	///@notice admin function
  function mintBatch(address account, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner {
   _mintBatch(account, ids, amounts, data);
		for (uint256 i = 0; i < ids.length; i++) {
			emit Minted(account, ids[i], amounts[i]);
		}
  }

	///@notice admin function
	function checkout(uint256 eth) public onlyOwner {
		payable(msg.sender).transfer(Math.min(eth * 1_000_000_000_000_000_000, address(this).balance));
	}
}
