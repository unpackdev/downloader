// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";

/**
 * @author GoArt Metaverse Blockchain Team
 * @title GoArtKeys
 * @notice Free mint GoArtKeys.
 */
contract GoArtKeys is ERC721A, Pausable, Ownable, ERC2981, ReentrancyGuard {
	using Strings for uint256;

	/// Sale phases are defined here.
	enum SalePhase {
		Phase01,
		Phase02,
		Phase03,
		Phase04
	}

	/// There can be only 4 types of coupons as defined here.
	enum CouponType {
		Og,
		Whitelist,
		Public,
		Custom
	}

	/// max supply for this collection
	uint64 public constant maxSupply = 5555;

	/// 10% royalty rate for secondary sales
	uint96 public constant royaltyRate = 1000;

	/// base token uri
	string private baseURI = "https://goartlive.blob.core.windows.net/free-mint/unrevealed/data/";

	/// admin signer address for mints
	address private adminSigner;

	/// store used signatures to avoid them from being reused
	mapping(bytes => bool) private usedSignatures;

	event NewURI(string newURI, address updatedBy);
	event updatePhase(SalePhase phase, address updatedBy);
	event updateAdminSigner(address adminSigner, address updatedBy);
	event royaltyAddressUpdated(address newRoyaltyAddress, address updatedBy);

	/// Start from Phase01
	SalePhase public phase = SalePhase.Phase01;

	/**
	 * @notice constructor
	 *
	 * @param _adminSigner admin signer address for mint
	 * @param _treasuryWallet royalty fee receiver
	 */
	constructor(address _adminSigner, address _treasuryWallet) ERC721A("GoArtKeys", "GAK") {
		adminSigner = _adminSigner;
		_setDefaultRoyalty(_treasuryWallet, royaltyRate);
		_pause();
	}

	/**
	 * @dev setAdminSigner updates adminSigner
	 *
	 * Emits a {updateAdminSigner} event.
	 *
	 * Requirements:
	 *
	 * - Only the owner can call this function
	 */
	function setAdminSigner(address _newAdminSigner) external onlyOwner {
		adminSigner = _newAdminSigner;
		emit updateAdminSigner(_newAdminSigner, msg.sender);
	}

	/**
	 * @dev setRoyaltyAddress updates royaltyAddress
	 *
	 * Emits a {royaltyAddressUpdated} event.
	 *
	 * Requirements:
	 *
	 * - Only the owner can call this function
	 */
	function setRoyaltyAddress(address _newRoyaltyAddress) external onlyOwner {
		_setDefaultRoyalty(_newRoyaltyAddress, royaltyRate);
		emit royaltyAddressUpdated(_newRoyaltyAddress, msg.sender);
	}

	/**
     * @dev setPhase updates the price and the phase to (Locked, Private, Presale or Public).
     $
     * Emits a {Unpaused} event.
     *
     * Requirements:
     *
     * - Only the owner can call this function
     */
	function setPhase(SalePhase phase_) external onlyOwner {
		phase = phase_;
		emit updatePhase(phase_, msg.sender);
	}

	/**
	 * @dev setBaseUri updates the new token URI in contract.
	 *
	 * Emits a {NewURI} event.
	 *
	 * Requirements:
	 *
	 * - Only owner of contract can call this function
	 **/
	function setBaseUri(string memory uri) external onlyOwner {
		baseURI = uri;
		emit NewURI(uri, msg.sender);
	}

	/**
	 * @dev Mint to mint nft
	 *
	 * Emits [Transfer] event.
	 *
	 * Requirements:
	 *
	 * - should have a valid coupon if we are ()
	 **/
	function mint(
		uint64 amount,
		bytes memory signature,
		CouponType couponType
	) external whenNotPaused nonReentrant {
		// this recreates the message that was signed on the client
		bytes32 message = prefixed(
			keccak256(abi.encodePacked(msg.sender, couponType, block.chainid, this))
		);

		require(recoverSigner(message, signature) == adminSigner, "Invalid signature");

		require(!usedSignatures[signature], "Signature has been used earlier");

		usedSignatures[signature] = true;

		require(totalSupply() + amount < maxSupply + 1, "Max supply reached");

		if (phase == SalePhase.Phase01) {
			require(
				couponType == CouponType.Og || couponType == CouponType.Custom,
				"Invalid coupon"
			);
		} else if (phase == SalePhase.Phase02) {
			require(
				couponType == CouponType.Whitelist || couponType == CouponType.Custom,
				"Invalid coupon"
			);
		} else if (phase == SalePhase.Phase03) {
			require(
				couponType == CouponType.Og ||
					couponType == CouponType.Whitelist ||
					couponType == CouponType.Public ||
					couponType == CouponType.Custom,
				"Invalid coupon"
			);
		} else if (phase == SalePhase.Phase04) {
			require(
				couponType == CouponType.Public || couponType == CouponType.Custom,
				"Invalid coupon"
			);
		} else {
			revert("Invalid phase.");
		}

		/// mint
		_mint(msg.sender, amount);
	}

	/**
	 * Add support for interfaces
	 * @dev ERC721A, ERC2981
	 * @param interfaceId corresponding interfaceId
	 * @return bool true if supported, false otherwise
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC721A, ERC2981)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

	/**
	 * @dev getAdminSigner returns the adminSigner address
	 *
	 */
	function getAdminSigner() public view returns (address) {
		return adminSigner;
	}

	/**
	 * @dev getbaseURI returns the base uri
	 *
	 */
	function getbaseURI() public view returns (string memory) {
		return baseURI;
	}

	/**
	 * @dev tokenURI returns the uri to meta data
	 *
	 */
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "GoArt Keys: Query for non-existent token");
		return
			bytes(baseURI).length > 0
				? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"))
				: "";
	}

	/// @dev Returns the starting token ID.
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	/**
	 * @dev pause() is used to pause contract.
	 *
	 * Emits a {Paused} event.
	 *
	 * Requirements:
	 *
	 * - Only the owner can call this function
	 **/
	function pause() public onlyOwner whenNotPaused {
		_pause();
	}

	/**
	 * @dev unpause() is used to unpause contract.
	 *
	 * Emits a {Unpaused} event.
	 *
	 * Requirements:
	 *
	 * - Only the owner can call this function
	 **/
	function unpause() public onlyOwner whenPaused {
		_unpause();
	}

	/// signature methods.
	function splitSignature(bytes memory sig)
		internal
		pure
		returns (
			uint8 v,
			bytes32 r,
			bytes32 s
		)
	{
		require(sig.length == 65);

		assembly {
			// first 32 bytes, after the length prefix.
			r := mload(add(sig, 32))
			// second 32 bytes.
			s := mload(add(sig, 64))
			// final byte (first byte of the next 32 bytes).
			v := byte(0, mload(add(sig, 96)))
		}

		return (v, r, s);
	}

	function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
		(uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

		return ecrecover(message, v, r, s);
	}

	/// builds a prefixed hash to mimic the behavior of eth_sign.
	function prefixed(bytes32 hash) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
	}
}
