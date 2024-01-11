// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./InterfacesMigrated.sol";
import "./ICelestialCastle.sol";
import "./CelestialPortalMessages.sol";
import "./console.sol";

interface IFxStateSender {
	function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

/**
 * @title Celestial Portal Mainland
 */
contract CelestialPortalMainland is Ownable {
	/// @notice Emited when we replay a call.
	event CallMade(address target, bool success, bytes data);

	/// @notice Emited when a message is sent to polyland
	event MessageToPolyland(address polylandPortal, bytes message);

	/// @notice Emited when a retrieved message is processed.
	// token possible values are 'freaks', 'celestials', 'bucks' or 'all'
	event Retrieve(address receiver, uint256 txId, bytes signature, bytes data, string token);

	/// @notice Fx Root contract address.
	address public fxRoot;
	/// @notice Polyland Portal contract address.
	address public polylandPortal;
	/// @notice Authorized callers mapping.
	mapping(address => bool) public auth;
	/// @notice Portal's wallet
	address public portalWallet;
	/// @notice Completed transactions(used to make sure transactions are not replayed)
	mapping(uint256 => bool) public txsCompleted;
	/// @notice Celestial Castle Mainland
	ICelestialCastle public castleMainland;

	/// @notice Require the sender to be the owner or authorized.
	modifier onlyAuth() {
		require(auth[msg.sender], "CelestialPortalMainland: Unauthorized to use the portal");
		_;
	}

	/// @notice Initialize the contract.
	function initialize(
		address newFxRoot,
		address newPolylandPortal,
		address newCastleMainland,
		address newPortalWallet
	) external onlyOwner {
		fxRoot = newFxRoot;
		polylandPortal = newPolylandPortal;
		castleMainland = ICelestialCastle(newCastleMainland);
		portalWallet = newPortalWallet;
	}

	/// @notice Give authentication to `adds_`.
	function setAuth(address[] calldata addresses, bool authorized) external onlyOwner {
		for (uint256 index = 0; index < addresses.length; index++) {
			auth[addresses[index]] = authorized;
		}
	}

	/// @notice Send a message to the portal via FxRoot.
	function sendMessage(bytes calldata message) external onlyAuth {
		emit MessageToPolyland(polylandPortal, message);
		IFxStateSender(fxRoot).sendMessageToChild(polylandPortal, message);
	}

	/// @notice Clone reflection calls by the owner.
	function replayCall(
		address target_,
		bytes calldata data_,
		bool required_
	) external onlyOwner {
		(bool succ, ) = target_.call(data_);
		if (required_) require(succ, "CelestialPortalMainland: Replay call failed");
		emit CallMade(target_, succ, data_);
	}

	function retrieveAll(
		bytes memory data,
		uint256 txId,
		bytes memory signature
	) external {
		require(verify(data, txId, signature), "Invalid signature");
		require(!txsCompleted[txId], "This transaction has been executed already");
		(
			uint256[] memory freakIds,
			Freak[] memory freaksAttributes,
			uint256[] memory celestialIds,
			CelestialV2[] memory celestialAttributes,
			uint256 fbxAmount,
			bytes32 txType
		) = abi.decode(data, (uint256[], Freak[], uint256[], CelestialV2[], uint256, bytes32));
		require(txType == CelestialPortalMessages.RETRIEVE_ALL, "Wrong tx type");

		txsCompleted[txId] = true;
		castleMainland.retrieveFreaks(msg.sender, freakIds, freaksAttributes);
		castleMainland.retrieveCelestials(msg.sender, celestialIds, celestialAttributes);
		castleMainland.retrieveBucks(msg.sender, fbxAmount);
		emit Retrieve(msg.sender, txId, signature, data, "all");
	}

	function retrieveFreaks(
		bytes memory data,
		uint256 txId,
		bytes memory signature
	) external {
		require(verify(data, txId, signature), "Invalid signature");
		require(!txsCompleted[txId], "This transaction has been executed already");
		(uint256[] memory freakIds, Freak[] memory freaksAttributes, bytes32 txType) = abi.decode(
			data,
			(uint256[], Freak[], bytes32)
		);
		require(txType == CelestialPortalMessages.RETRIEVE_FREAKS, "Wrong tx type");
		txsCompleted[txId] = true;
		castleMainland.retrieveFreaks(msg.sender, freakIds, freaksAttributes);
		emit Retrieve(msg.sender, txId, signature, data, "freaks");
	}

	function retrieveCelestials(
		bytes memory data,
		uint256 txId,
		bytes memory signature
	) external {
		require(verify(data, txId, signature), "Invalid signature");
		require(!txsCompleted[txId], "This transaction has been executed already");
		(uint256[] memory celestialIds, CelestialV2[] memory celestialsAttributes, bytes32 txType) = abi.decode(
			data,
			(uint256[], CelestialV2[], bytes32)
		);
		require(txType == CelestialPortalMessages.RETRIEVE_CELESTIALS, "Wrong tx type");
		txsCompleted[txId] = true;
		castleMainland.retrieveCelestials(msg.sender, celestialIds, celestialsAttributes);
		emit Retrieve(msg.sender, txId, signature, data, "celestials");
	}

	function retrieveBucks(
		bytes memory data,
		uint256 txId,
		bytes memory signature
	) external {
		require(verify(data, txId, signature), "Invalid signature");
		require(!txsCompleted[txId], "This transaction has been executed already");
		(uint256 amount, bytes32 txType) = abi.decode(data, (uint256, bytes32));
		require(txType == CelestialPortalMessages.RETRIEVE_FBX, "Wrong tx type");
		txsCompleted[txId] = true;
		castleMainland.retrieveBucks(msg.sender, amount);
		emit Retrieve(msg.sender, txId, signature, data, "bucks");
	}

	function verify(
		bytes memory data,
		uint256 txId,
		bytes memory signature
	) public view returns (bool) {
		bytes32 messageHash = getMessageHash(msg.sender, data, txId);
		bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

		address signer = recoverSigner(ethSignedMessageHash, signature);
		return signer == portalWallet;
	}

	function getMessageHash(
		address receiver,
		bytes memory data,
		uint256 txId
	) public pure returns (bytes32) {
		return keccak256(abi.encode(receiver, data, txId));
	}

	function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", string(abi.encodePacked(_messageHash))));
	}

	function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
		(bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

		return ecrecover(_ethSignedMessageHash, v, r, s);
	}

	function splitSignature(bytes memory sig)
		public
		pure
		returns (
			bytes32 r,
			bytes32 s,
			uint8 v
		)
	{
		require(sig.length == 65, "invalid signature length");

		assembly {
			/*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

			// first 32 bytes, after the length prefix
			r := mload(add(sig, 32))
			// second 32 bytes
			s := mload(add(sig, 64))
			// final byte (first byte of the next 32 bytes)
			v := byte(0, mload(add(sig, 96)))
		}

		// implicitly return (r, s, v)
	}
}
