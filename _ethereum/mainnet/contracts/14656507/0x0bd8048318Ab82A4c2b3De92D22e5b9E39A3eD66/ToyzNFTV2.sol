// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721A.sol";
import "./MultiSigOwnable.sol";
import "./IProxyRegistry.sol";
import "./Pausable.sol";
import "./ECDSA.sol";

error ZeroAddressTeamMultiSig();

/// @title ToyzNFT ERC721 token
/// @author ToyzNFT Team
contract ToyzNFTV2 is ERC721A, MultiSigOwnable, Pausable {
    // Base URL for the token
    string private baseTokenURI;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    /// @dev constructor of the contract
    /// @param baseURI_ base URI of the contract
    /// @param teamMultiSig_ address of the team multisig wallet to manage the contract and withdraw funds
    /// @param proxyRegistry_ OpenSea proxy registry address to make exchanges easier
    constructor(
        string memory baseURI_,
        address teamMultiSig_,
        address proxyRegistry_
    ) ERC721A("Toyz NFT", "TOYZ") {
        if (teamMultiSig_ == address(0)) {
            revert ZeroAddressTeamMultiSig();
        }

        baseTokenURI = baseURI_;
        proxyRegistry = IProxyRegistry(proxyRegistry_);

        // Transfer ownership to the team multisig
        // Zero address is checked in transferMultiSigOwnership()
        transferMultiSigOwnership(teamMultiSig_);
    }

    /// @dev change the starting index to 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @dev set base URI for token metadata
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice change the base URI for token metadata
    /// @param url new base URI
    function updateBaseURI(string memory url) external onlyMultiSigOwner {
        baseTokenURI = url;
    }

    /// @dev pause the contract, preventing any actions from being taken
    function pause() public onlyMultiSigOwner {
        _pause();
    }

    /// @dev unpause the contract, allowing actions to be taken
    function unpause() public onlyMultiSigOwner {
        _unpause();
    }

    /// @dev airdrop tokens to snapshoted holders
    /// only owner/deployer can airdrop tokens
    /// airdrop will not be callable when owner renounces ownership
    function airdrop(address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], amounts[i], "", false);
        }
    }

    /// @dev override _beforeTokenTransfers to add `whenNotPaused` check before token transfers
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /// @dev override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
}
