// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AccessControl.sol";
import "./Pausable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";

import "./IVaultKey.sol";

contract VaultKey is IVaultKey, ERC721Enumerable, Pausable, AccessControl, ERC721Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public vaultKeyMintLastBlock;
    uint256 public vaultKeyTransferLastBlock;
    string public baseUri;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _tokenIdCounter.increment(); // Skip TokenId 0
    }

    function lastMintedKeyId(address beneficiary) external view override returns (uint256) {
        uint256 balance = balanceOf(beneficiary);

        return tokenOfOwnerByIndex(beneficiary, balance - 1);
    }

    function mintKey(address to, address vault) external override onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        super._mint(to, tokenId);
        emit VaultKeyMinted(vaultKeyMintLastBlock, to, tokenId, vault);
        vaultKeyMintLastBlock = block.number;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._transfer(from, to, tokenId);
        emit VaultKeyTransfer(vaultKeyTransferLastBlock, from, to, tokenId);
        vaultKeyTransferLastBlock = block.number;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function updateBaseUri(string memory newBaseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseUri = newBaseUri;
    }
}
