// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.9;

import "./ERC721ACommon.sol";
import "./BaseTokenURI.sol";
import "./FixedPriceSeller.sol";
import "./ERC2981.sol";
import "./Strings.sol";
import "./Counters.sol";

/// @title Viking Art Collective NFT
/// @author @odentorp
contract VikingArtCollective is ERC721ACommon, BaseTokenURI, ERC2981, FixedPriceSeller {
    using Strings for uint256;

    mapping(address => bool) Whitelist;
    mapping(address => bool) AlreadyMinted;
    
    /**
    @notice Flag indicating that public minting is open.
     */
    bool public publicMinting;
    
    /**
    @notice Flag indicating that whitelist minting is open.
     */
    bool public whitelistMinting;

    /** 
    @notice internal struct used for whitelist list info for a specific address
     */
    struct WhitelistInfo {
        bool onList;
        bool alreadyMinted;
    }

    event AddedMemberToWhitelist(address indexed member);
    event RemovedMemberFromWhitelist(address indexed member);

    constructor(
        string memory name,
        string memory symbol,
        address payable beneficiary,
        address payable royaltyReceiver
    )
    ERC721ACommon(name, symbol)
    BaseTokenURI("")
    FixedPriceSeller(
        1 ether,
        Seller.SellerConfig({
            totalInventory: 1000,
            maxPerAddress: 0,
            maxPerTx: 0,
            freeQuota: 75,
            lockFreeQuota: false,
            reserveFreeQuota: true,
            lockTotalInventory: true
        }),
        beneficiary
    )
    {
        _setDefaultRoyalty(royaltyReceiver, 750);
    }

    /**
    @notice Internal override of Seller function for handling purchase (i.e. minting).
     */
    function _handlePurchase(
        address to,
        uint256 num,
        bool
    ) internal override {
        _safeMint(to, num);
    }

    /**
    @notice public method for whitelist minting
     */
    function mint(
        address to
    ) external payable {
        require(whitelistMinting, "Whitelist minting is not enabled");
        require(Whitelist[to], "Address is not on the whitelist");
        delete Whitelist[to];
        AlreadyMinted[to] = true;
        _purchase(to, 1);
    }

    /**
    @notice Set the `publicMinting` flag.
     */
    function setPublicMinting(bool _publicMinting) external onlyOwner {
        publicMinting = _publicMinting;
    }

    /**
    @notice Set the `publicMinting` flag.
     */
    function setWhitelistMinting(bool _whitelistMinting) external onlyOwner {
        whitelistMinting = _whitelistMinting;
    }

    /**
    @dev Public minting method only available when public minting is enabled
    */
    function mintPublic(
        address to
    ) external payable {
        require(publicMinting, "Public minting closed");
        _purchase(to, 1);
    }

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721A)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    /**
    @notice If renderingContract is set then returns its tokenURI(tokenId)
    return value, otherwise returns the standard baseTokenURI + tokenId.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    /**
    @notice standard method for verify interface implementations
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721ACommon, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
    @notice Add an address to be whitelisted for minting before public mint is enabled
    */
    function addMemberToWhitelist(address member) external onlyOwner {
        Whitelist[member] = true;
        emit AddedMemberToWhitelist(member);
    }

    /**
    @notice Add addresses in buld to be whitelisted
    */
    function batchAddMembersToWhitelist(address[] memory members) external onlyOwner {
        for (uint256 i = 0; i < members.length; i++) {
            Whitelist[members[i]] = true;
            emit AddedMemberToWhitelist(members[i]);
        }
    }

    /**
    @notice Remove a single address in from the whitelisted
    */
    function removeMemberFromWhitelist(address member) external onlyOwner {
        delete Whitelist[member];
        emit RemovedMemberFromWhitelist(member);
    }

    /**
    @notice Remove addresses in bulk from the whitelisted
    */
    function batchRemoveMembersFromWhitelist(address[] memory members) external onlyOwner {
        for (uint256 i = 0; i < members.length; i++) {
            delete Whitelist[members[i]];
            emit RemovedMemberFromWhitelist(members[i]);
        }
    }

    /**
    @notice Check to see if an address is on the whitelist
    */
    function isMemberOnWhitelist(address member) external view returns (bool) {
        return Whitelist[member];
    }

    /**
    @notice Check to see if an address has already minted from the whitelist
    */
    function hasAlreadyMinted(address member) external view returns (bool) {
        return AlreadyMinted[member];
    }

    /**
    @notice Get whitelist info for an address will return both if they are on the list and if 
    they have already minted.
    */
    function getWhitelistInfo(address member) external view returns (WhitelistInfo memory) {
        return WhitelistInfo({ onList: Whitelist[member], alreadyMinted: AlreadyMinted[member] });
    }
}
