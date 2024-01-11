// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IStayDAONFTRoyaltyVault.sol";
import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IERC2981Upgradeable.sol";

contract StayDAONFT is
    ERC721AUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IERC2981Upgradeable
{
    using StringsUpgradeable for uint256;

    uint8 public constant MAX_MINT_FOR_PUBLIC = 5;
    uint8 public constant MAX_MINT_FOR_WL = 10;
    uint8 public constant DISCOUNT_DECIMALS = 100;
    uint16 public constant MAX_MINT_TOTAL = 10000;
    uint256 public constant MINT_PRICE = 0.3 ether;
    // solhint-disable-next-line var-name-mixedcase
    uint8[3] public WL_MINT_TIER_DISCOUNTS;

    uint8 public t1Remaining;
    uint8 public t2Remaining;
    bool public isPublicSaleOpen;
    bool public isTransferAllowed;
    IStayDAONFTRoyaltyVault public royaltyVault;
    uint256 public mintProceeds;
    bytes32[3] public merkleRoots;
    string private _baseUri;

    function initialize(string memory name_, string memory symbol_)
        external
        initializer
    {
        __Ownable_init();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __UUPSUpgradeable_init_unchained();
        __ERC721A_init_unchained(name_, symbol_);
        t1Remaining = 250;
        t2Remaining = 250;
        WL_MINT_TIER_DISCOUNTS = [100, 50, 0];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // solhint-disable-next-line ordering
    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function setIsPublicSaleOpen(bool status) external onlyOwner {
        isPublicSaleOpen = status;
    }

    function setIsTransferAllowed(bool allowed) external onlyOwner {
        isTransferAllowed = allowed;
    }

    function setWhitelistMerkleRoots(bytes32[3] calldata roots)
        external
        onlyOwner
    {
        merkleRoots = roots;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _baseUri = uri;
    }

    function setRoyaltyVault(IStayDAONFTRoyaltyVault vault) external onlyOwner {
        royaltyVault = vault;
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function mint(address to, uint256 quantity) external payable whenNotPaused {
        require(isPublicSaleOpen, "Not open");
        require(
            _numberMinted(to) + quantity <= MAX_MINT_FOR_PUBLIC,
            "Over max"
        );
        require(msg.value == quantity * MINT_PRICE, "Bad value");
        _wrappedSafeMint(to, quantity);
    }

    function mintWhitelist(
        address to,
        uint256 quantity,
        bytes32[] calldata proof,
        uint256 tier
    ) external payable whenNotPaused {
        require(verifyWhitelistStatus(to, proof, tier), "Not WL'd");
        require(_numberMinted(to) + quantity <= MAX_MINT_FOR_WL, "Over max");
        if (_numberMinted(to) == 0) {
            require(
                msg.value ==
                    quantity *
                        MINT_PRICE -
                        (MINT_PRICE * WL_MINT_TIER_DISCOUNTS[tier - 1]) /
                        DISCOUNT_DECIMALS,
                "Bad value"
            );
            if (tier == 1) {
                --t1Remaining;
            } else if (tier == 2) {
                --t2Remaining;
            }
        } else {
            require(msg.value == quantity * MINT_PRICE, "Bad value");
        }
        _wrappedSafeMint(to, quantity);
    }

    function mintSpecial(address to, uint256 quantity)
        external
        payable
        onlyOwner
    {
        _wrappedSafeMint(to, quantity);
    }

    function withdrawRoyaltyToVault() external onlyOwner nonReentrant {
        require(address(royaltyVault) != address(0), "No vault set");
        uint256 amount = mintProceeds;
        mintProceeds = 0;
        royaltyVault.receiveMintFunds{value: amount}();
    }

    function numberMinted(address owner_) external view returns (uint256) {
        return _numberMinted(owner_);
    }

    // solhint-disable-next-line no-unused-vars
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(royaltyVault), (salePrice * 75) / 1000);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(_baseUri, tokenId.toString(), ".json"));
    }

    function verifyWhitelistStatus(
        address owner_,
        bytes32[] calldata proof,
        uint256 tier
    ) public view returns (bool) {
        return
            MerkleProofUpgradeable.verify(
                proof,
                merkleRoots[tier - 1],
                keccak256(abi.encodePacked(owner_))
            );
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function _wrappedSafeMint(address to, uint256 quantity) internal {
        require(_totalMinted() + quantity <= MAX_MINT_TOTAL, "Over total cap");
        mintProceeds += msg.value;
        _safeMint(to, quantity);
    }

    function _beforeTokenTransfers(
        address from,
        // solhint-disable-next-line no-unused-vars
        address to,
        // solhint-disable-next-line no-unused-vars
        uint256 startTokenId,
        // solhint-disable-next-line no-unused-vars
        uint256 quantity
    ) internal view override whenNotPaused {
        require(from == address(0) || isTransferAllowed, "Transfer disabled");
    }
}
