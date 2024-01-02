// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import "./OFTV2.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IUSTPController.sol";

/**
 * @title Peg USD token for TProtocol.
 *
 */

contract USTP_OFTV2 is OFTV2 {
	using SafeERC20 for ERC20;

	/// @dev Value is equal to keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
	bytes32 public immutable _PERMIT_TYPEHASH =
		0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;
	bytes32 private immutable _DOMAIN_TYPE_HASH =
		0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
	bytes32 internal immutable _DOMAIN_NAME_HASH = keccak256(bytes("USTP"));
	bytes32 internal immutable _DOMAIN_VERSION_HASH = keccak256(bytes("1"));
	bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
	uint256 private immutable _CACHED_CHAIN_ID;

	mapping(address => bool) private _minters;
	mapping(address => uint256) public _nonces;

	IUSTPController public controller;

	event NewController(address controller);

	constructor(address _endpoint) OFTV2("USTP", "USTP", 18, _endpoint) {
		_CACHED_CHAIN_ID = block.chainid;
		_CACHED_DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				_DOMAIN_TYPE_HASH,
				_DOMAIN_NAME_HASH,
				_DOMAIN_VERSION_HASH,
				block.chainid,
				address(this)
			)
		);
	}

	function setController(address _new) external onlyOwner {
		controller = IUSTPController(_new);
		emit NewController(_new);
	}

	function mint(address user, uint256 amount) external {
		require(amount != 0, "!Zero");
		require(controller.isUSTPVault(msg.sender), "!auth");
		require(totalSupply() + amount <= controller.getUSTPCap(), "can't mint more than CAP.");
		require(controller.checkMintRisk(msg.sender), "mint fail.");
		_mint(user, amount);
	}

	function burn(address user, uint256 amount) external {
		require(amount != 0, "!Zero");
		require(controller.isUSTPVault(msg.sender), "!auth");
		require(controller.checkBurnRisk(msg.sender), "burn fail.");
		_burn(user, amount);
	}

	function recoverERC20(
		address tokenAddress,
		address target,
		uint256 amountToRecover
	) external onlyOwner {
		ERC20(tokenAddress).safeTransfer(target, amountToRecover);
	}

	// EIP 2612
	function permit(
		address owner,
		address spender,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
		require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");
		bytes32 digest = keccak256(
			abi.encodePacked(
				"\x19\x01",
				DOMAIN_SEPARATOR(),
				keccak256(
					abi.encode(_PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner]++, deadline)
				)
			)
		);
		address recoveredAddress = ecrecover(digest, v, r, s);
		require(recoveredAddress == owner, "INVALID_SIGNER");
		_approve(owner, spender, amount);
	}

	function nonces(address owner) external view returns (uint256) {
		return _nonces[owner];
	}

	function DOMAIN_SEPARATOR() public view returns (bytes32) {
		if (block.chainid == _CACHED_CHAIN_ID) {
			return _CACHED_DOMAIN_SEPARATOR;
		} else {
			return
				_buildDomainSeparator(_DOMAIN_TYPE_HASH, _DOMAIN_NAME_HASH, _DOMAIN_VERSION_HASH);
		}
	}

	function _buildDomainSeparator(
		bytes32 typeHash,
		bytes32 name_,
		bytes32 version_
	) private view returns (bytes32) {
		return keccak256(abi.encode(typeHash, name_, version_, block.chainid, address(this)));
	}
}
