// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @creator: The Shilladel
/// @author: Wizard

/*

    $$$$$$\  $$\       $$\ $$\ $$\                 $$\           $$\ 
   $$  __$$\ $$ |      \__|$$ |$$ |                $$ |          $$ |
   $$ /  \__|$$$$$$$\  $$\ $$ |$$ | $$$$$$\   $$$$$$$ | $$$$$$\  $$ |
   \$$$$$$\  $$  __$$\ $$ |$$ |$$ | \____$$\ $$  __$$ |$$  __$$\ $$ |
    \____$$\ $$ |  $$ |$$ |$$ |$$ | $$$$$$$ |$$ /  $$ |$$$$$$$$ |$$ |
   $$\   $$ |$$ |  $$ |$$ |$$ |$$ |$$  __$$ |$$ |  $$ |$$   ____|$$ |
   \$$$$$$  |$$ |  $$ |$$ |$$ |$$ |\$$$$$$$ |\$$$$$$$ |\$$$$$$$\ $$ |
    \______/ \__|  \__|\__|\__|\__| \_______| \_______| \_______|\__|

*/

import "./ERC721A.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./Ownable.sol";

error SpendCallerNotOwnerNorApproved();
error SpendFromIncorrectOwner();

contract ShilladelPass is
    ERC721A,
    ERC2981ContractWideRoyalties,
    AccessControl,
    Ownable
{
    using Strings for uint256;
    using SafeMath for uint256;

    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant EARN_RATE = 11574074074000;

    // URI tags and data
    string private constant _NAME_TAG = "<NAME>";
    string private constant _DESCRIPTION_TAG = "<DESCRIPTION>";
    string private constant _TIER_TAG = "<TIER>";
    string private constant _TOKENID_TAG = "<TOKENID>";
    string private constant _IMAGE_TAG = "<IMAGE>";
    string[] private _uriParts;

    struct NFT {
        string name;
        string description;
        string imageURI;
    }

    uint256 public maxIssuance;
    uint256 public maxAllowed;

    // Mapping from token ID to tier
    mapping(uint256 => uint256) private _tier;

    // Mapping of token ID to spent points
    mapping(uint256 => uint256) private _spent;

    // Mapping of token ID to commnuity issued points
    mapping(uint256 => uint256) private _issued;

    // Array of tier point requirements
    uint256[] private tiers;

    NFT[] private _metadata;

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "caller is not a spender"
        );
        _;
    }

    modifier onlySpender() {
        require(hasRole(SPENDER_ROLE, _msgSender()), "caller is not a spender");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "caller is not a minter");
        _;
    }

    constructor(
        address shillAdmin,
        address[] memory shilladel,
        NFT memory metadata
    ) ERC721A("Shilladel Pass", "SHILL") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SPENDER_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, shillAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, shillAdmin);
        transferOwnership(shillAdmin);

        addTier(0, metadata);

        _uriParts = [
            'data:application/json;utf8,{"name":"',
            _NAME_TAG,
            " #",
            _TOKENID_TAG,
            '", "description":"',
            _DESCRIPTION_TAG,
            '", "created_by":"The Shilladel"',
            ', "image":"',
            _IMAGE_TAG,
            '", "attributes":[{"trait_type":"Tier","value":"',
            _TIER_TAG,
            '"}]}'
        ];

        for (uint256 i; i < shilladel.length; i++) {
            _mint(shilladel[i], 1, "", false);
        }
    }

    function earned(uint256 tokenId) public view virtual returns (uint256) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 startTime = _ownershipOf(tokenId).startTimestamp;
        uint256 base = _blockTime().sub(startTime).mul(EARN_RATE).div(1e18);

        return base.add(_issued[tokenId]).sub(_spent[tokenId]);
    }

    function tier(uint256 tokenId) public view virtual returns (uint256) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 tierCount = tiers.length;
        uint256 index = tierCount.sub(1);
        uint256 points = earned(tokenId);

        do {
            if (points >= tiers[index]) return index;
            index == index--;
        } while (index >= 0);

        return 0;
    }

    function spent(uint256 tokenId) public view virtual returns (uint256) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return _spent[tokenId];
    }

    function spendFrom(
        address from,
        uint256 tokenId,
        uint256 amount
    ) public virtual onlySpender returns (bool) {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert SpendFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert SpendCallerNotOwnerNorApproved();

        uint256 earned_ = earned(tokenId);
        require(earned_ >= amount, "not enough to spend");

        _spent[tokenId] = _spent[tokenId].add(amount);

        // Update tier if needed
        uint256 tier_ = tier(tokenId);
        _tier[tokenId] = tier_;

        emit Spent(from, tokenId, amount);

        return true;
    }

    function mint(address to, uint256 quantity) public virtual onlyMinter {
        require(
            maxIssuance == 0 || maxIssuance <= _totalMinted().add(quantity),
            "max issuance reached"
        );

        _mint(to, quantity, "", false);
    }

    function issuePoints(uint256 tokenId, uint256 amount)
        public
        virtual
        onlyAdmin
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        require(
            maxAllowed == 0 || amount <= maxAllowed,
            "must be below maxAllowed"
        );

        uint256 currIssued = _issued[tokenId];
        _issued[tokenId] = currIssued.add(amount);

        emit Issued(tokenId, amount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 tokenTier = tier(tokenId);
        NFT memory metadata = _metadata[tokenTier];

        bytes memory byteString;
        for (uint256 i; i < _uriParts.length; i++) {
            if (_checkTag(_uriParts[i], _NAME_TAG)) {
                byteString = abi.encodePacked(byteString, metadata.name);
            } else if (_checkTag(_uriParts[i], _TOKENID_TAG)) {
                byteString = abi.encodePacked(byteString, tokenId.toString());
            } else if (_checkTag(_uriParts[i], _DESCRIPTION_TAG)) {
                byteString = abi.encodePacked(byteString, metadata.description);
            } else if (_checkTag(_uriParts[i], _IMAGE_TAG)) {
                byteString = abi.encodePacked(byteString, metadata.imageURI);
            } else if (_checkTag(_uriParts[i], _TIER_TAG)) {
                byteString = abi.encodePacked(byteString, tokenTier.toString());
            } else {
                byteString = abi.encodePacked(byteString, _uriParts[i]);
            }
        }
        return string(byteString);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981Base, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(ERC2981Base).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function updateMetadata(uint256 tier_, NFT memory metadata)
        public
        virtual
        onlyAdmin
    {
        require(tiers[tier_] > 0, "tier must exists");
        _metadata[tier_] = metadata;
    }

    function addTier(uint256 points, NFT memory metadata)
        public
        virtual
        onlyAdmin
    {
        tiers.push(points);
        _metadata.push(metadata);
    }

    function setRoyalties(address recipient, uint256 value) public onlyAdmin {
        _setRoyalties(recipient, value);
    }

    function setMaxIssuance(uint256 _masIssuance) public virtual onlyAdmin {
        require(maxIssuance == 0, "max issuance already set");
        maxIssuance = _masIssuance;
    }

    function setMaxAllowed(uint256 _maxAllowd) public virtual onlyAdmin {
        maxAllowed = _maxAllowd;
    }

    function setUriParts(string[] memory uriParts_) public virtual onlyAdmin {
        _uriParts = uriParts_;
    }

    function _checkTag(string storage a, string memory b)
        private
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function _beforeTokenTransfers(
        address from,
        address,
        uint256 startTokenId,
        uint256
    ) internal virtual override {
        if (from == address(0)) return;

        uint256 currTier = _tier[startTokenId];
        uint256 index = tiers.length.sub(1);

        // Update tier if required
        if (currTier != index) {
            currTier = tier(startTokenId);
            _tier[startTokenId] = currTier;
        }

        // Reset spent AFTER locking current tier
        _spent[startTokenId] = 0;

        // if the pass has a tier, issue the tier's base points
        _issued[startTokenId] = currTier > 0 ? tiers[currTier] : 0;

        return;
    }

    function _blockTime() internal view returns (uint256) {
        return block.timestamp;
    }

    event Spent(
        address indexed account,
        uint256 indexed tokenId,
        uint256 amount
    );

    event Issued(uint256 indexed tokenId, uint256 amount);
}
