// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BetterHooksUpgradeable.sol";
import "./ExtensionUpgradeable.sol";

contract ERC721MaxSupplyExtension is Initializable, ExtensionUpgradeable, AccessControlEnumerableUpgradeable, ERC721BetterHooksUpgradeable, ERC721EnumerableUpgradeable {

    bytes32 public constant ERC721_MAX_SUPPLY_EXTENSION = keccak256('ERC721MaxSupplyExtension');
    bytes32 private constant DEPLOYER_ROLE = keccak256('DEPLOYER_ROLE');
    bytes32 public constant SUPPLIER_ROLE = keccak256('SUPPLIER_ROLE');

    bool public maxSupplyLocked;
    uint256 public maxSupply;

    function __ERC721MaxSupplyExtension_init(address supplier) internal onlyInitializing {
        __ERC721MaxSupplyExtension_init_unchained(supplier);
    }

    function __ERC721MaxSupplyExtension_init_unchained(address supplier) internal onlyInitializing {
        _grantRole(SUPPLIER_ROLE, supplier);
    }

    function initializeERC721MaxSupplyExtension(uint256 _maxSupply, bool _maxSupplyLocked) public onlyRole(DEPLOYER_ROLE) {
        initializeExtension(ERC721_MAX_SUPPLY_EXTENSION);
        maxSupplyLocked = _maxSupplyLocked;
        maxSupply = _maxSupply;
    }

    function increaseMaxSupply(uint256 increase) public virtual onlyRole(SUPPLIER_ROLE) {
        require(!maxSupplyLocked, "ERC721MaxSupplyExtension: Supply is locked.");
        maxSupply += increase;
    }

    function lockMaxSupply() public virtual onlyRole(SUPPLIER_ROLE) {
        maxSupplyLocked = true;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControlEnumerableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override (ERC721BetterHooksUpgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _beforeTokenMint(address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
        require(totalSupply() < maxSupply, "ERC721MaxSupplyExtension: No more supply.");
        super._beforeTokenMint(to, firstTokenId, batchSize);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[10] private __gap;

}