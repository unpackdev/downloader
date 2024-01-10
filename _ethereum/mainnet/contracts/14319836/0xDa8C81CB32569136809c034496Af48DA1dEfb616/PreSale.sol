// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./IAnftifyNFT.sol";

contract PreSale is Ownable {
    struct Voucher {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

	mapping(address => bool) public addressMinted;
	uint256 public maxMintsPerAddress;
	uint256 public maxMintsForSaleType;
	uint256 public totalMinted;
	uint256 public mintPrice;
	string public saleType;
	address public nft;
	address public treasury;
	bool public pause = true;

 	event MaxMintsForSaleTypeSet(uint256 maxMintsForSaleType);
	event MaxMintPerAddressSet(uint256 maxMintsPerAddress);
	event MintPriceSet(uint256 mintPrice);
	event SaleTypeSet(string saleType);
	event NFTAddressSet(address nft);
	event TreasuryAddressUpdated(address treasury);
	event PauseUpdated(bool pause);

	constructor(uint256 _maxMintsForSaleType, uint256 _maxMintsPerAddress, uint256 _mintPrice, string memory _saleType, address _nft, address _treasury) {
		require(_maxMintsForSaleType > 0, "PreSale: maxMintsForSaleType should be greater than zero");
		require(_maxMintsPerAddress > 0, "PreSale: maxMintsPerAddress should be greater than zero");
		require(bytes(_saleType).length > 0, "PreSale: Cannot set empty saleType");
		require(_nft != address(0), "PreSale: NFT address cannot be zero address");
		require(_treasury != address(0), "PreSale: treasury address cannot be zero address");

		maxMintsForSaleType = _maxMintsForSaleType;
		maxMintsPerAddress = _maxMintsPerAddress;
		mintPrice = _mintPrice;
		saleType = _saleType;
		nft = _nft;
		treasury = _treasury;

		emit MaxMintsForSaleTypeSet(maxMintsForSaleType);
		emit MaxMintPerAddressSet(maxMintsPerAddress);
		emit MintPriceSet(mintPrice);
		emit SaleTypeSet(saleType);
		emit NFTAddressSet(nft);
		emit TreasuryAddressUpdated(treasury);
	}

    /// Mint function for presale
	/// @dev mints by addresses validated using verified vouchers signed by an admin signer
	/// @notice mints token to addresses eligible for presale
	/// @param amount number of tokens to mint in transaction
	/// @param voucher voucher signed by an admin signer
	function mint(uint256 amount, Voucher memory voucher) 
		external 
		payable 
		validateEthPayment(amount)
		saleIsOpen(amount)
	{
		require(
			amount > 0,
			"PreSale: 0 number of presale mints"
		);

		require(
			amount <= maxMintsPerAddress,
			"PreSale: Exceeds number of presale mints allowed per address"
		);

		require(
			!addressMinted[msg.sender],
			"PreSale: Already minted"
		);
		bytes32 digest = keccak256(abi.encode(saleType, msg.sender));
		require(_isVerifiedVoucher(digest, voucher), "PreSale: Invalid voucher");

		addressMinted[msg.sender] = true;
		totalMinted = totalMinted + amount;
		IAnftifyNFT(nft).mint(amount, msg.sender);

		(bool success, ) = treasury.call{value: address(this).balance}("");
		require(success, "Transfer failed.");
	}

	/// @dev check that the voucher sent was signed by the admin signer
	function _isVerifiedVoucher(bytes32 digest, Voucher memory voucher)
		internal
		view
		returns (bool)
	{
		address signer = ecrecover(digest, voucher.v, voucher.r, voucher.s);
		require(signer != address(0), "ECDSA: invalid signature"); // Added check for zero address
		return signer == owner();
	}

	function setTreasury(address _treasury) public onlyOwner {
		require(_treasury != address(0), "PreSale: treasury address cannot be zero address");
		treasury = _treasury;
		emit TreasuryAddressUpdated(treasury);
    }
	
	function setPause(bool _pause) public onlyOwner {
		pause = _pause;
		emit PauseUpdated(pause);
    }

    /// Modifier to validate eth value on payable functions
	/// @param amount number of tokens to mint in transaction
	modifier validateEthPayment(uint256 amount) {
		require(
			mintPrice * amount <= msg.value,
			"PreSale: Ether value sent is not correct"
		);
		_;
	}

	modifier saleIsOpen(uint256 amount) {
		require(
			totalMinted + amount <= maxMintsForSaleType,
			"PreSale: Exceeds number of total presale mints allowed"
		);
		require(
			!pause, 
			"PreSale: Paused"
		);
        _;
    }
}