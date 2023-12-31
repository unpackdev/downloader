// SPDX-License-Identifier: MIT

/*
                                                 .
        .-=-:    ..:  .:::::::  ::::::---:     -##++*+*.::----:  -==-   ---.--::---=.
      =#=-=+=+#=@+=+%##=#@=--%+##=@*-=##==#=-*#==*#= :%@*-:**+=#*@-=@%-+@:@@+-:+**=#=
     =%..%@@@--@@+.-@=+@@@@=.:%%-@@*::@@+.+@@::*@@@#=.#@#::@@%..@@=.:*@@@.@@#. %=-+=
     =@-..*@@@@@@*:::.*@@@@@+..-@@@#:.#*-:*@@.-@@@@%=:=@#:.*=:+%@@=+=.:%@:@@#..%*++:
      *@*-..-+@@@+.-@=.-%@@@@.:#@@@*:-@@@=.*@-.+*@@@:.+@#.:@%::#@@=*@#:.*:@@#..=+=%-
     -#*@@%=-:.%@*.-@@#-.:=#%==++@@*..#%#:=%@%-.:--.:#@@*..@@@-.-#+*@@@-..@@%..#+:.
     +*.@@@@#..#@=::@@@@%*+=--=+%@@@@@@@@@@@@@@@%##%@@@@@%%@@@@%=-::--#@*.@@%..*+..:
      %*=+*+:=*@@@@@@@@%#%##****##**+++*###+##*###**+++**#*****#%##@@@@@@@@@@#*+**+%+
       -#@@@@@@@@@@%%%%%%#*++**%%#++++*#%*******#%#*+++*#%%#*++*#%%%#%%@@@@@@@@@@@%#
     :+***+++***@@@%###*****#@@#**#@@@@%**#@@#***#****#@@@@%**+**#%@@###%@@@@%#******%+
   .#*-:::---:::%@@@-:--====:@@@-::=@@@@=:#@@@-:=+++++-@@%-:=+++--=@@#::@@@#=::----::-@
  :@+::=#@@@@@%*+@@@-:*@@@@@@%@@--=--%@@=-+@@@-:#@@@@%@@@+--%@@@@@+@@%::@@%-:=@@@@@%#=%-
  %*::+@@@@%%%%%#%@@=--====-@@@@--##-:#@=-*@@%--:::::=@@@@+-::-=+#@@@#-:@@%--:=+*#%@@@%*
 .@+--*@@@@------%@@=-+**#**@@@@=-%@%=-+=-*@@@=-#%%%%#@@@#@@%##*=--%@#-:@@@@*+=---::-+@-
 .@#---@@@%%@@+--@@@=-*@@@@@%%@%=-%@@@+-==*@@@==+*###**#@*-*#%@@%=-+@#--@@*%@@@@@%#+---@
  +@+--=#@@@@%+=-@@@==------=%@%==*@@@@*+++@@%+*+++++++@@@++=---==*@@#=-@@%-=*#%@%%*=-=@:
   *@#+==----====%@%##%%%%%@@@@@@%%%#*#####**##*#########%##@@@@@@#%@%#*#@@*===---===*@*
    :*@%##**##%@%#=+==--::..                                  ..    :-==+=%@@@%%%%%@%*-
       :-=++=-:                                                            .  .:--:.
*/

pragma solidity 0.8.17;

import "./AccessControlEnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC165.sol";

import "./ITriggerableMetadata.sol";
import "./IVRFKeeper.sol";
import "./LockableUpgradeableV3.sol";

import "./IERC4906.sol";
import "./ERC721AUpgradeable.sol";
import "./ERC721ContractMetadataUpgradeable.sol";
import "./WLRoleConstants.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

import "./IERC721ASafeMintable.sol";

contract ImmortalsV3 is
	Initializable,
	ERC721ContractMetadataUpgradeable,
	AccessControlEnumerableUpgradeable,
	UUPSUpgradeable,
	IERC721ASafeMintable,
	DefaultOperatorFiltererUpgradeable,
	LockableUpgradeableV3
{
	// ====================================================
	// ERRORS
	// ====================================================
	error Unauthorized();
	error AlreadyRevealed();
	error NotFullyMinted();
	error InvalidToken();
	error MintQuantityExceedsMaxSupply(uint256 total, uint256 maxSupply);

	// ====================================================
	// EVENTS
	// ====================================================
	event BatchLocked(uint256[] tokenIds, uint256 duration, address owner);
	event BatchUnlocked(uint256[] tokenIds);

	// ====================================================
	// STATE V1: this block MUST NOT be modified
	// ====================================================
	IVRFKeeper public vrfKeeperContract;

	/// @notice See {ERC721SeaDropRandomOffset}
	uint256 public constant _FALSE = 1;
	uint256 public constant _TRUE = 2;

	uint256 public revealed;
	uint256 public randomOffset;

	// ====================================================
	// STATE V2: this block MUST NOT be modified
	// ====================================================
	address private _trustedForwarder;

	// ====================================================
	// STATE V3
	// ====================================================

	// ====================================================
	// CONSTRUCTOR
	// ====================================================
	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	function initialize() external reinitializer(3) {}

	// ====================================================
	// OVERRIDES
	// ====================================================
	/**
	 * @dev See {IERC721-setApprovalForAll}.
	 */
	function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
		super.setApprovalForAll(operator, approved);
	}

	/**
	 * @dev See {IERC721-approve}.
	 */
	function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
		super.approve(operator, tokenId);
	}

	/**
	 * @dev See {IERC721-transferFrom}.
	 */
	function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId);
	}

	/**
	 * @dev  {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	) public override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId, data);
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	function supportsInterface(
		bytes4 interfaceId
	)
		public
		view
		override(AccessControlEnumerableUpgradeable, ERC721ContractMetadataUpgradeable, LockableUpgradeableV3)
		returns (bool)
	{
		return
			AccessControlEnumerableUpgradeable.supportsInterface(interfaceId) ||
			ERC721ContractMetadataUpgradeable.supportsInterface(interfaceId) ||
			LockableUpgradeableV3.supportsInterface(interfaceId) ||
			super.supportsInterface(interfaceId);
	}

	/// @dev UUPSUpgradeable override
	function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(COLLECTION_ADMIN_ROLE) {}

	/// @dev Enable transfers only when token is unlocked (not being used in game)
	/// 	 _quantity Equals 1 during transfers but can be more than one for mint
	function _beforeTokenTransfers(
		address _from,
		address _to,
		uint256 _startToken,
		uint256 _quantity
	) internal virtual override(ERC721AUpgradeable) onlyWhenUnlocked(_startToken) {
		super._beforeTokenTransfers(_from, _to, _startToken, _quantity);
	}

	function enableTokenLocking() public override onlyRole(COLLECTION_ADMIN_ROLE) {
		super.enableTokenLocking();
	}

	function disableTokenLocking() public override onlyRole(COLLECTION_ADMIN_ROLE) {
		super.disableTokenLocking();
	}

	// ====================================================
	// ROLE GATED
	// ====================================================
	function triggerBatchMetadataUpdate(
		uint256 _fromTokenId,
		uint256 _toTokenId
	) public onlyRole(COLLECTION_ADMIN_ROLE) {
		emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
	}

	function safeMint(address to, uint256 quantity) public onlyRole(MINTER_ROLE) {
		if (_totalMinted() + quantity > maxSupply()) {
			revert MintQuantityExceedsMaxSupply(_totalMinted() + quantity, maxSupply());
		}
		_safeMint(to, quantity);
	}

	function adminUnlockTokens(uint256[] calldata tokenIds) public onlyRole(COLLECTION_ADMIN_ROLE) {
		for (uint i = 0; i < tokenIds.length; i++) {
			super.unlockToken(tokenIds[i]);
		}
		emit BatchUnlocked(tokenIds);
	}

	// ====================================================
	// ERC2771
	// ====================================================
	function getTrustedForwarder() public view virtual returns (address forwarder) {
		return _trustedForwarder;
	}

	function setTrustedForwarder(address _forwarder) public onlyRole(COLLECTION_ADMIN_ROLE) {
		_trustedForwarder = _forwarder;
	}

	function isTrustedForwarder(address forwarder) public view returns (bool) {
		return forwarder == _trustedForwarder;
	}

	function _msgSender() internal view override(ContextUpgradeable) returns (address ret) {
		if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
			// At this point we know that the sender is a trusted forwarder,
			// so we trust that the last bytes of msg.data are the verified sender address.
			// extract sender address from the end of msg.data
			assembly {
				ret := shr(96, calldataload(sub(calldatasize(), 20)))
			}
		} else {
			ret = msg.sender;
		}
	}

	/// @notice ERC721 uses _msgSenderERC721A to determine sender
	function _msgSenderERC721A() internal view virtual override(ERC721AUpgradeable) returns (address) {
		return _msgSender();
	}

	function _msgData() internal view override(ContextUpgradeable) returns (bytes calldata ret) {
		if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
			return msg.data[0:msg.data.length - 20];
		} else {
			return msg.data;
		}
	}

	// ====================================================
	// PUBLIC API - READ
	// ====================================================
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		if (!_exists(tokenId)) {
			revert InvalidToken();
		}

		if (revealed == _FALSE) {
			string memory baseURI = _baseURI();

			if (bytes(baseURI)[bytes(baseURI).length - 1] != bytes("/")[0]) {
				return baseURI;
			}
			return super.tokenURI(tokenId);
		}
		uint256 id = ((tokenId + randomOffset) % maxSupply()) + _startTokenId();
		return super.tokenURI(id);
	}

	function startTokenId() public view returns (uint256) {
		return _startTokenId();
	}

	function batchLocked(uint256[] calldata tokenIds) public view returns (bool[] memory) {
		bool[] memory states = new bool[](tokenIds.length);
		for (uint256 i = 0; i < tokenIds.length; i++) {
			states[i] = locked(tokenIds[i]);
		}
		return states;
	}

	// ====================================================
	// PUBLIC API - WRITE
	// ====================================================
	function lockTokens(uint256[] calldata tokenIds, uint256 lockDuration) public {
		address sender = _msgSender();

		for (uint i = 0; i < tokenIds.length; i++) {
			if (sender != ownerOf(tokenIds[i])) {
				revert Unauthorized();
			}
			super.lockToken(tokenIds[i], lockDuration);
		}

		emit BatchLocked(tokenIds, lockDuration, sender);
	}

	function unlockTokens(uint256[] calldata tokenIds) public {
		address sender = _msgSender();

		for (uint i = 0; i < tokenIds.length; i++) {
			if (sender != ownerOf(tokenIds[i])) {
				revert Unauthorized();
			}
			super.unlockToken(tokenIds[i]);
		}

		emit BatchUnlocked(tokenIds);
	}
}
