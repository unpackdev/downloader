//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./AccessControlUpgradeable.sol";
import "./ERC1155PausableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./WhiteListSaleAccessControlUpgradeable.sol";
import "./OrbsSupply.sol";

/**
 * @notice
 */
contract OwnableDelegateProxy {

}

/**
 * @notice Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 * @dev used to whitelist OpenSea so the user does not have to pay fees when listing
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Orbs is
    ERC1155PausableUpgradeable,
    ERC1155SupplyUpgradeable,
    AccessControlUpgradeable,
    WhiteListSaleAccessControlUpgradeable,
    OrbsSupply
{
    string public constant VERSION = "1.0";
    address private _openSeaRegistryAddress;
    address private _raribleRegistryAddress;
    uint256 public totalSupplyCount;
    uint256 public maxSupply;
    bool public isMinting;
    bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /*
     * @dev Replaces the constructor for upgradeable contracts
     */
    function initialize(
        address openSeaRegistryAddress,
        address raribleRegistryAddress,
        string memory uri
    ) public initializer {
        __Pausable_init_unchained();
        __ERC1155_init(uri);
        __WhiteListSaleAccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _openSeaRegistryAddress = openSeaRegistryAddress;
        _raribleRegistryAddress = raribleRegistryAddress;
        maxSupply = 1077;
        isMinting = false;
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmeKaGoMom9rpD2ttTMK7ji1EUxhTsL3mHNvwwwb1d6bxp";
    }

    function name() public pure returns (string memory) {
        return "Mysterious Orbs";
    }

    function symbol() public pure returns (string memory) {
        return "PXORBS";
    }

    /**
     * @notice Sets the burner contract address
     * @dev This should be the Creatures contract
     */
    function setBurner(address burnerAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setupRole(BURNER_ROLE, burnerAddress);
    }

    /**
     * @notice Set the URI
     * @dev only the owner can do this, and to use if the URI changed after the contract was deployed
     */
    function setURI(string calldata _newuri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setURI(_newuri);
    }

    /**
     * @notice Sets the isMinting status
     * @dev only the owner can do this
     */
    function setIsMinting(bool _isMinting)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isMinting = _isMinting;
    }

    /**
     * @notice Pause contract
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause contract
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Whitelist mint
     * @param maxMintCount Max number of tokens the user can mint and numbers to mint
     * @param proof Proof to verify that the caller is allowed to mint
     */
    function mintWhitelist(uint256 maxMintCount, bytes32[] calldata proof)
        external
        payable
        whenNotPaused
        canMintWhiteList(maxMintCount, 0, proof, maxMintCount)
    {
        require(
            totalSupplyCount + maxMintCount < maxSupply + 1,
            "No more supply"
        );
        require(isMinting, "Minting complete");
        if (maxMintCount == 1) {
            uint256 orbType = getOrbType(0);
            _mint(msg.sender, orbType, 1, "");
            afterMint(1);
        } else {
            // Get all counts for token types
            uint256[] memory counts = new uint256[](10);
            uint256 counter = 0;
            for (counter; counter < maxMintCount; counter++) {
                counts[getOrbType(counter)]++;
            }
            // Count how many index we really have
            uint256 totalIndexCount = 0;
            for (counter = 0; counter < 10; counter++) {
                if (counts[counter] > 0) {
                    totalIndexCount++;
                }
            }
            // Create final mint data
            uint256[] memory finalCounts = new uint256[](totalIndexCount);
            uint256[] memory orbTypes = new uint256[](totalIndexCount);
            uint256 finalIndex = 0;
            for (counter = 0; counter < 10; counter++) {
                if (counts[counter] > 0) {
                    finalCounts[finalIndex] = counts[counter];
                    orbTypes[finalIndex] = counter;
                    finalIndex++;
                }
            }
            _mintBatch(msg.sender, orbTypes, finalCounts, "");
            afterMint(maxMintCount);
        }
        totalSupplyCount += maxMintCount;
    }

    /**
     * @notice Burns an orb for ascension.
     * @dev Can only be called from the Creatures contract
     * @param from The address to burn the item from
     * @param id the ID of the token to burn
     */
    function burnForAscension(address from, uint256 id)
        external
        onlyRole(BURNER_ROLE)
    {
        require(totalSupplyCount > 0, "Nothing to burn");
        require(balanceOf(from, id) > 0, "Nothing to burn");
        totalSupplyCount--;
        maxSupply--;
        _burn(from, id, 1);
    }

    /**
     * Withdraw balance from the contract
     */
    function withdrawAll() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    /**
     * @dev See {ERC1155PausableUpgradeable-_beforeTokenTransfer}.
     * @dev See {ERC1155SupplyUpgradeable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155SupplyUpgradeable, ERC1155PausableUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Override isApprovedForAll to whitelist user's ProxyRegistry proxy accounts to
     * enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea and Rarible proxy contract for easy trading.
        ProxyRegistry openSeaProxyRegistry = ProxyRegistry(
            _openSeaRegistryAddress
        );
        ProxyRegistry raribleProxyRegistry = ProxyRegistry(
            _raribleRegistryAddress
        );
        if (
            address(openSeaProxyRegistry.proxies(owner)) == operator ||
            address(raribleProxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev We have to override supportsInterface since two contracts have the same function
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
