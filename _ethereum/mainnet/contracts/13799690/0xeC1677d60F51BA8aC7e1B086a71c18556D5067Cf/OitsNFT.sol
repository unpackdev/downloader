// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

/*                                                                                
   ____  __  _     
  / __ \/ /_(_)____
 / / / / __/ / ___/
/ /_/ / /_/ (__  ) 
\____/\__/_/____/  
                   
*/

import "./ERC721Upgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./UUPSUpgradeable.sol";

/*
 * project: otis minting contracts
 *
 * org: zora
 * contract: github.com/iainnash
 */
contract OtisNFTContract is
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC721Upgradeable,
    IERC2981Upgradeable
{
    /// Event when royalty payout address is updated
    event RoyaltyUpdate(address indexed to, uint16 bps);

    /// Struct to store token info for each token id in contract
    struct TokenInfo {
        string metadataUri;
        address creator;
    }

    /// Struct to store global royalty payout information
    struct RoyaltyConfig {
        address payout;
        uint16 bps;
    }

    /// State variable for keeping royalty configuration
    RoyaltyConfig royaltyConfig;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    /// Counter to keep track of the currently minted token
    CountersUpgradeable.Counter private tokenIdTracker;

    /// Token info struct for rendering out each token in contact
    mapping(uint256 => TokenInfo) private tokenInfo;

    /// Allowed minters list
    mapping(address => bool) private allowedMinters;

    /// Royalty reciever address
    address public royaltyReceiver;

    /// Modifier to check if the token exists
    modifier tokenExists(uint256 tokenId) {
        require(_exists(tokenId), "Query for nonexistent token");
        _;
    }

    /// Modifier to only allow through allowed minters
    modifier onlyAllowedMinter() {
        require(allowedMinters[msg.sender] || msg.sender == owner(), "Minter not allowed");
        _;
    }

    /// @dev Sets up ERC721 Token
    /// @param _name name of token
    /// @param _symbol symbol of token
    function initialize(
        string memory _name,
        string memory _symbol,
        address payout,
        uint16 bps
    ) public initializer {
        // Setup ERC721 and ownable
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __UUPSUpgradeable_init();

        // Set royalty config
        royaltyConfig = RoyaltyConfig({payout: payout, bps: bps});
    }

    /// Set allowed minter addresses
    /// @param to Address to set allowed token minter status
    /// @param canMint Boolean to set status to for given address
    function updateAllowedMinter(address to, bool canMint) external {
        allowedMinters[to] = canMint;
    }

    // Only owner can upgrade
    function _authorizeUpgrade(address) internal override onlyOwner {

    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     *
     * Requirements:
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, string memory metadataUri)
        public
        onlyAllowedMinter
    {
        // Mints directly to specified account
        tokenIdTracker.increment();
        _mint(to, tokenIdTracker.current());
        tokenInfo[tokenIdTracker.current()] = TokenInfo({
            metadataUri: metadataUri,
            creator: msg.sender
        });
    }

    /// Burn token by token id
    /// @param tokenId id of token to burn
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not allowed");
        delete tokenInfo[tokenId];
        _burn(tokenId);
    }

    /// @param tokenId token id to get uri for
    function tokenURI(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        return tokenInfo[tokenId].metadataUri;
    }

    /// Updates the metadata uri to a new string for new schemas / adding licenses and metadata uri updates
    /// Only callable by the contract owner
    /// @param tokenId token id to update the metadata for
    /// @param newMetadataUri new metadata uri string
    function updateMetadataUri(uint256 tokenId, string memory newMetadataUri)
        external
        tokenExists(tokenId)
        onlyOwner
    {
        tokenInfo[tokenId].metadataUri = newMetadataUri;
    }

    /**
        Section: Royalties
     */

    /// Only callable by owner
    /// @param payout address for royalties payouts
    /// @param bps bps for royalties
    function setNewRoyaltyConfig(address payout, uint16 bps)
        external
        onlyOwner
    {
        royaltyConfig.payout = payout;
        royaltyConfig.bps = bps;

        emit RoyaltyUpdate(royaltyConfig.payout, royaltyConfig.bps);
    }

    /// ERC2981 royalty info getter fn
    /// ignored tokenId token id to get royalty info for
    /// @param salePrice sale price to get royalty percentage for
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override(IERC2981Upgradeable)
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyConfig.payout, (salePrice * royaltyConfig.bps) / 10000);
    }

    /// Interface ERC165 spec calls
    /// @param interfaceId interface id to see what is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981Upgradeable).interfaceId;
    }
}
