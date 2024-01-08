// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";

contract VivaMuertos is Pausable, Ownable, ERC721Burnable, ERC721Enumerable {
	using Counters for Counters.Counter;
	using Strings for uint256;
	Counters.Counter private _tokenIdCounter;

	string private baseURI =
		"ipfs://QmTeBpGznuePaWyF9WKZiu7G3TemdCEJYLw6p4t9eo8dVv/";
	string private baseExtension = ".json";
	uint256 constant PRICE = .035 ether;
	// Max supply will be will be 9999 because TokenID starts counting at 0
	uint256 constant MAX_SUPPLY = 9999;
	address payable private VHF =
		payable(0x7720fD6250D5719f8Fa3E1C52137cc3Bc3262FcE);
	address payable private LaloCota =
		payable(0x13e28D6Edf473cbdCeA2b2c4Ced5Fb2b369F4f71);

	// Triggers ONLY if actual Ether is sent to this contract
	receive() external payable {}

	fallback() external payable {}

	constructor() ERC721("Muertos", "MRTO") {
		mint(25);
		_pause();
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function currentTokenID() public view returns (uint256) {
		return _tokenIdCounter.current();
	}

	function readBenefactors() public view onlyOwner returns (address, address) {
		return (VHF, LaloCota);
	}

	function safeMint(address to) public onlyOwner {
		_safeMint(to, _tokenIdCounter.current());
		_tokenIdCounter.increment();
	}

	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		require(
			_exists(tokenId),
			"ERC721Metadata: URI query for nonexistent token"
		);

		string memory tokenBaseURI = _baseURI();

		return
			bytes(tokenBaseURI).length > 0
				? string(
					abi.encodePacked(tokenBaseURI, tokenId.toString(), baseExtension)
				)
				: "";
	}

	function mint(uint256 _mintAmount) public payable whenNotPaused {
		require(_mintAmount > 0, "Need to mint at least 1 NFT");
		require(
			_tokenIdCounter.current() + _mintAmount <= MAX_SUPPLY,
			"Max NFT limit exceeded"
		);

		if (_msgSender() != owner()) {
			require(msg.value >= PRICE * _mintAmount, "Insufficient funds");
		}

		for (uint256 i; i < _mintAmount; i++) {
			_safeMint(_msgSender(), _tokenIdCounter.current());
			_tokenIdCounter.increment();
		}
	}

	function withdraw() external onlyOwner {
		// Pays Lalo 5% of balance
		(bool hs, ) = LaloCota.call{value: (address(this).balance / 100) * 5}("");
		require(hs, "Lalo error");
		// Pays VHF 95% of the contract balance.
		(bool os, ) = VHF.call{value: (address(this).balance)}("");
		require(os, "Valley mistake");
	}

	function setWithdrawalAccounts(uint256 _account, address _newAddress)
		external
		onlyOwner
	{
		require(
			_account == 1 || _account == 2,
			"You must designate a valid account number, enter 1 to change VHF or enter 2 to change lalo"
		);
		_account == 1 ? VHF = payable(_newAddress) : LaloCota = payable(
			_newAddress
		);
	}

	//@note This function withdraws 60/40 split after
	function withdrawAfterMints() external onlyOwner {
		// 60/40
		if (_tokenIdCounter.current() == MAX_SUPPLY) {
			// This will payout Lalo 40% of the contract balance.
			//
			(bool hs, ) = LaloCota.call{value: (address(this).balance / 100) * 40}(
				""
			);
			require(hs);
			//Then this pays out valleywise the remaining 60%
			(bool os, ) = VHF.call{value: (address(this).balance)}("");
			require(os);
		}
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal override(ERC721, ERC721Enumerable) whenNotPaused {
		super._beforeTokenTransfer(from, to, tokenId);
	}
}
