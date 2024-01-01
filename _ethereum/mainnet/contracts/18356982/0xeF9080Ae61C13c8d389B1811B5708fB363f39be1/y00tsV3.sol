// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./SafeERC20.sol";

import "./UUPSUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./Ownable2StepUpgradeable.sol";
import "./IWormhole.sol";
import "./BytesLib.sol";

//                                                      @@@@@@              @@
//   @@@@@@    @@@@@   @@@@@@@@@@@      @@@@@@@@@@@     @@@@@@
//   @@@@@@   @@@@@@ @@@@@@@@@@@@@@   @@@@@@@@@@@@@@  @@@@@@@@@@@  @@@@@@@@@@
//    @@@@@@  @@@@@/@@@@@@    @@@@@@ @@@@@@    @@@@@@ @@@@@@@@@@@ @@@@@@(@@@
//     @@@@@%@@@@@@ @@@@@      @@@@@ @@@@@      @@@@@   @@@@@@    @@@@@@@@
//     @@@@@@@@@@@@ @@@@@@     @@@@@ @@@@@@     @@@@@   @@@@@@     @@@@@@@@@@
//      @@@@@@@@@@   @@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@   @@@@@@         @@@@@@@
//      &@@@@@@@@     @@@@@@@@@@@@&    @@@@@@@@@@@@&     @@@@@@@@ @@@@@@@@@@@
//  @@@@@@@@@@@.        &@@@@@@@         &@@@@@@@          @@@@@@ @@@@@@@@@
//  @@@@@@@@

/**
 * @title  y00ts ERC-721 Smart Contract
 */
contract y00ts is UUPSUpgradeable, ERC2981Upgradeable, Ownable2StepUpgradeable, ERC721Upgradeable {
	using BytesLib for bytes;
	using SafeERC20 for IERC20;

	// Wormhole chain id that valid vaas must have -- must be Polygon.
	uint16 constant SOURCE_CHAIN_ID = 5;

	// -- immutable members (baked into the code by the constructor of the logic contract)

	// Core layer Wormhole contract. Exposed so higher-level contract can
	// interact with the wormhole interface.
	IWormhole immutable _wormhole;
	// Only VAAs from this emitter can mint NFTs with our contract (prevents spoofing).
	bytes32 private immutable _emitterAddress;
	// Common URI for all NFTs handled by this contract.
	bytes32 private immutable _baseUri;
	uint8 private immutable _baseUriLength;

	// Dictionary of VAA hash => flag that keeps track of claimed VAAs
	mapping(bytes32 => bool) private _claimedVaas;
	// Storage gap so that future upgrades to the contract can add new storage variables.
	uint256[50] __gap;

	error WrongEmitterChainId();
	error WrongEmitterAddress();
	error FailedVaaParseAndVerification(string reason);
	error VaaAlreadyClaimed();
	error InvalidMessageLength();
	error BaseUriEmpty();
	error BaseUriTooLong();
	error InvalidMsgValue();
	error FailedToSend();

	event Minted(uint256 indexed tokenId, address indexed receiver);
	event BatchMinted(uint256[] tokenIds, address indexed receiver);

	//constructor for the logic(!) contract
	constructor(IWormhole wormhole, bytes32 emitterAddress, bytes memory baseUri) {
		if (baseUri.length == 0) {
			revert BaseUriEmpty();
		}
		if (baseUri.length > 32) {
			revert BaseUriTooLong();
		}

		_wormhole = wormhole;
		_emitterAddress = emitterAddress;
		_baseUri = bytes32(baseUri);
		_baseUriLength = uint8(baseUri.length);

		//brick logic contract
		initialize("", "", address(1), 0);
		renounceOwnership();
	}

	//intentionally empty (we only want the onlyOwner modifier "side-effect")
	function _authorizeUpgrade(address) internal override onlyOwner {}

	//"constructor" of the proxy contract
	function initialize(
		string memory name,
		string memory symbol,
		address royaltyReceiver,
		uint96 royaltyFeeNumerator
	) public initializer {
		__UUPSUpgradeable_init();
		__ERC721_init(name, symbol);
		__ERC2981_init();
		__Ownable_init();

		_setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
	}

	/**
	 * @notice Mints an NFT based on a valid VAA
	 * @param vaa Wormhole message that must have been published by the Polygon Y00tsV2 instance
	 * of the NFT collection with the specified emitter on Polygon (chainId = 5). The VAA contains
	 * a single token ID and a recipient address.
	 */
	function receiveAndMint(bytes calldata vaa) external {
		IWormhole.VM memory vm = _verifyMintMessage(vaa);

		(uint256 tokenId, address evmRecipient) = parsePayload(vm.payload);
		_safeMint(evmRecipient, tokenId);
		emit Minted(tokenId, evmRecipient);
	}

	/**
	 * @notice Mints a batch of NFTs based on a valid VAA
	 * @param vaa Wormhole message that must have been published by the Polygon Y00tsV2 instance
	 * of the NFT collection with the specified emitter on Polygon (chainId = 5). The VAA contains
	 * a list of token IDs and a recipient address.
	 */
	function receiveAndMintBatch(bytes calldata vaa) external {
		IWormhole.VM memory vm = _verifyMintMessage(vaa);

		(uint256[] memory tokenIds, address evmRecipient) = parseBatchPayload(vm.payload);

		uint256 tokenCount = tokenIds.length;
		for (uint256 i = 0; i < tokenCount; ) {
			_safeMint(evmRecipient, tokenIds[i]);

			unchecked {
				i += 1;
			}
		}
		emit BatchMinted(tokenIds, evmRecipient);
	}

	function parsePayload(
		bytes memory message
	) internal pure returns (uint256 tokenId, address evmRecipient) {
		if (message.length != BytesLib.uint16Size + BytesLib.addressSize)
			revert InvalidMessageLength();

		tokenId = message.toUint16(0);
		evmRecipient = message.toAddress(BytesLib.uint16Size);
	}

	function parseBatchPayload(
		bytes memory message
	) internal pure returns (uint256[] memory, address) {
		uint256 messageLength = message.length;
		uint256 endTokenIndex = messageLength - BytesLib.addressSize;
		uint256 batchSize = endTokenIndex / BytesLib.uint16Size;

		if (
			messageLength <= BytesLib.uint16Size + BytesLib.addressSize ||
			endTokenIndex % BytesLib.uint16Size != 0
		) {
			revert InvalidMessageLength();
		}

		//parse the recipient
		address evmRecipient = message.toAddress(endTokenIndex);

		//parse the tokenIds
		uint256[] memory tokenIds = new uint256[](batchSize);
		for (uint256 i = 0; i < batchSize; ) {
			unchecked {
				tokenIds[i] = message.toUint16(i * BytesLib.uint16Size);
				i += 1;
			}
		}

		return (tokenIds, evmRecipient);
	}

	function _verifyMintMessage(bytes calldata vaa) internal returns (IWormhole.VM memory) {
		(IWormhole.VM memory vm, bool valid, string memory reason) = _wormhole.parseAndVerifyVM(
			vaa
		);
		if (!valid) revert FailedVaaParseAndVerification(reason);

		if (vm.emitterChainId != SOURCE_CHAIN_ID) revert WrongEmitterChainId();

		if (vm.emitterAddress != _emitterAddress) revert WrongEmitterAddress();

		if (_claimedVaas[vm.hash]) revert VaaAlreadyClaimed();

		_claimedVaas[vm.hash] = true;

		return vm;
	}

	// ---- ERC721 ----

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		return string.concat(super.tokenURI(tokenId), ".json");
	}

	function _baseURI() internal view virtual override returns (string memory baseUri) {
		baseUri = new string(_baseUriLength);
		bytes32 tmp = _baseUri;
		assembly ("memory-safe") {
			mstore(add(baseUri, 32), tmp)
		}
	}

	// ---- ERC165 ----

	function supportsInterface(
		bytes4 interfaceId
	) public view virtual override(ERC2981Upgradeable, ERC721Upgradeable) returns (bool) {
		return
			ERC2981Upgradeable.supportsInterface(interfaceId) ||
			ERC721Upgradeable.supportsInterface(interfaceId);
	}

	// ---- ERC2981 ----

	function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
		_setDefaultRoyalty(receiver, feeNumerator);
	}

	function deleteDefaultRoyalty() external onlyOwner {
		_deleteDefaultRoyalty();
	}

	function setTokenRoyalty(
		uint256 tokenId,
		address receiver,
		uint96 feeNumerator
	) external onlyOwner {
		_setTokenRoyalty(tokenId, receiver, feeNumerator);
	}

	function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
		_resetTokenRoyalty(tokenId);
	}
}
