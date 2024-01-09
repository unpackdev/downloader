// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721M.sol";
import "./ERC721Tradable.sol";

import "./Ownable.sol";

contract Mingoes is ERC721M, ERC721Tradable, Ownable {
	uint256 public constant PRICE = 0.04 ether;

	uint256 public constant MAX_SUPPLY = 10000;
	uint256 public constant MAX_RESERVE = 300;
	uint256 public constant MAX_PUBLIC = 9700; // MAX_SUPPLY - MAX_RESERVE
	uint256 public constant MAX_FREE = 200;

	uint256 public constant MAX_TX = 20;

	uint256 public reservesMinted;

	string public baseURI;

	bool public isSaleActive;

	mapping (address => bool) public hasClaimed;

	/* -------------------------------------------------------------------------- */
	/*                                 CONSTRUCTOR                                */
	/* -------------------------------------------------------------------------- */

	constructor(
		address _openSeaProxyRegistry,
		address _looksRareTransferManager,
		string memory _baseURI
	) payable ERC721M("Mingoes", "MINGOES") ERC721Tradable(_openSeaProxyRegistry, _looksRareTransferManager) {
		baseURI = _baseURI;
	}

	/* -------------------------------------------------------------------------- */
	/*                                    USER                                    */
	/* -------------------------------------------------------------------------- */

	/// @notice Mints an amount of tokens and transfers them to the caller during the public sale.
	/// @param amount The amount of tokens to mint.
	function publicMint(uint256 amount) external payable {
		require(isSaleActive, "Sale is not active");
		require(msg.sender == tx.origin, "No contracts allowed");

		uint256 _totalSupply = totalSupply();
		if (_totalSupply < MAX_FREE) {
			require(!hasClaimed[msg.sender], "Already claimed");
			hasClaimed[msg.sender] = true;
			
			_mint(msg.sender, 1);
			
			return;
		}
			
		require(msg.value == PRICE * amount, "Wrong ether amount");
		require(amount <= MAX_TX, "Amount exceeds tx limit");
		require(_totalSupply + amount <= MAX_PUBLIC, "Max public supply reached");

		_mint(msg.sender, amount);
	}

	/* -------------------------------------------------------------------------- */
	/*                                    OWNER                                   */
	/* -------------------------------------------------------------------------- */

	/// @notice Enables or disables minting through {publicMint}.
	/// @dev Requirements:
	/// - Caller must be the owner.
	function setIsSaleActive(bool _isSaleActive) external onlyOwner {
		isSaleActive = _isSaleActive;
	}

	/// @notice Mints tokens to multiple addresses.
	/// @dev Requirements:
	/// - Caller must be the owner.
	/// @param recipients The addresses to mint the tokens to.
	/// @param amounts The amounts of tokens to mint.
	function reserveMint(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
		unchecked {
			uint256 sum;
			uint256 length = recipients.length;
			for (uint256 i; i < length; i++) {
				address to = recipients[i];
				require(to != address(0), "Invalid recipient");
				uint256 amount = amounts[i];

				_mint(to, amount);
				sum += amount;
			}

			uint256 totalReserves = reservesMinted + sum;

			require(totalSupply() <= MAX_SUPPLY, "Max supply reached");
			require(totalReserves <= MAX_RESERVE, "Amount exceeds reserve limit");

			reservesMinted = totalReserves;
		}
	}

	/// @notice Sets the base Uniform Resource Identifier (URI) for token metadata.
	/// @dev Requirements:
	/// - Caller must be the owner.
	/// @param _baseURI The base URI.
	function setBaseURI(string calldata _baseURI) external onlyOwner {
		baseURI = _baseURI;
	}

	/// @notice Withdraws all contract balance to the caller.
	/// @dev Requirements:
	/// - Caller must be the owner.
	function withdrawETH() external onlyOwner {
		_transferETH(msg.sender, address(this).balance);
	}

	/// @dev Requirements:
	/// - Caller must be the owner.
	/// @inheritdoc ERC721Tradable
	function setMarketplaceApprovalForAll(bool approved) public override onlyOwner {
		marketPlaceApprovalForAll = approved;
	}

	/* -------------------------------------------------------------------------- */
	/*                             SOLIDITY OVERRIDES                             */
	/* -------------------------------------------------------------------------- */

	/// @inheritdoc ERC721
	function tokenURI(uint256 id) public view override returns (string memory) {
		require(_exists(id), "NONEXISTENT_TOKEN");
		string memory _baseURI = baseURI;
		return bytes(_baseURI).length == 0 ? "" : string(abi.encodePacked(_baseURI, toString(id)));
	}

	/// @inheritdoc ERC721Tradable
	function isApprovedForAll(address owner, address operator) public view override(ERC721, ERC721Tradable) returns (bool) {
		return ERC721Tradable.isApprovedForAll(owner, operator);
	}

	/* -------------------------------------------------------------------------- */
	/*                                    UTILS                                   */
	/* -------------------------------------------------------------------------- */

	function _transferETH(address to, uint256 value) internal {
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = to.call{ value: value }("");
		require(success, "ETH transfer failed");
	}
}
