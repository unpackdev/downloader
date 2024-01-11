// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./Initializable.sol";

import "./BitMapsUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./IParallelID.sol";
import "./OrderedStringSet.sol";

/*
 * @title The Parallel Identity Token (PID)
 * @author Parallel Markets Engineering Team
 * @dev See https://developer.parallelmarkets.com/docs/token for detailed documentation
 */

contract ParallelID is ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, IParallelID {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    using OrderedStringSets for OrderedStringSets.OrderedStringSet;
    OrderedStringSets.OrderedStringSet private _traitsIndex;

    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    uint16 public constant SUBJECT_INDIVIDUAL = 0;
    uint16 public constant SUBJECT_BUSINESS = 1;

    struct Metadata {
        uint256 _mintedAt;
        uint16 _subjectType;
        bool _anySanctions;
        BitMapsUpgradeable.BitMap _traits;
        BitMapsUpgradeable.BitMap _sanctions;
    }

    mapping(uint256 => Metadata) private _metas;

    mapping(address => uint256) public nonces;

    uint256 public mintCost;

    function initialize() public initializer {
        mintCost = 8500000 gwei;
        __ERC721_init("ParallelID", "PID");
        __ERC721URIStorage_init();
        __ERC721Enumerable_init();
        __Ownable_init();
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override(IERC721Upgradeable, ERC721Upgradeable) {
        noop();
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual override(IERC721Upgradeable, ERC721Upgradeable) {
        noop();
    }

    function approve(address, uint256) public virtual override(IERC721Upgradeable, ERC721Upgradeable) {
        noop();
    }

    function getApproved(uint256) public view virtual override(IERC721Upgradeable, ERC721Upgradeable) returns (address) {
        noop();
    }

    function setApprovalForAll(address, bool) public virtual override(IERC721Upgradeable, ERC721Upgradeable) {
        noop();
    }

    function setMintCost(uint256 newCost) external virtual onlyOwner {
        mintCost = newCost;
    }

    function mint(
        address recipient,
        string memory tokenDataURI,
        string[] memory _traits,
        uint16 _subjectType
    ) external virtual onlyOwner returns (uint256) {
        return _mint(recipient, tokenDataURI, _traits, _subjectType);
    }

    function hashStrings(string[] memory words) public pure returns (bytes32) {
        bytes memory result;

        for (uint256 i = 0; i < words.length; i++) {
            result = abi.encodePacked(result, words[i], "\x00");
        }

        return keccak256(result);
    }

    function recipientMint(
        string memory tokenDataURI,
        string[] memory _traits,
        uint16 _subjectType,
        uint256 expiresAt,
        bytes calldata signature
    ) external payable virtual returns (uint256) {
        require(block.timestamp < expiresAt, "Signature has expired");
        require(msg.value >= mintCost, "Sufficient payment required");

        bytes32 hashedTraits = hashStrings(_traits);
        address account = _msgSender();
        nonces[account] += 1;

        bytes32 hash = keccak256(abi.encodePacked(account, tokenDataURI, hashedTraits, _subjectType, expiresAt, address(this), nonces[account], block.chainid));
        bytes32 ethSignedMessage = ECDSAUpgradeable.toEthSignedMessageHash(hash);

        require(owner() == ECDSAUpgradeable.recover(ethSignedMessage, signature), "Invalid signature");
        return _mint(account, tokenDataURI, _traits, _subjectType);
    }

    function _mint(
        address recipient,
        string memory tokenDataURI,
        string[] memory _traits,
        uint16 _subjectType
    ) internal virtual returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, tokenDataURI);

        Metadata storage meta = _metas[newItemId];
        meta._mintedAt = block.timestamp;
        meta._subjectType = _subjectType;

        for (uint256 i = 0; i < _traits.length; i++) {
            uint256 index = _traitsIndex.add(_traits[i]);
            meta._traits.set(index);
        }

        return newItemId;
    }

    function withdraw() external virtual onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function addSanctions(uint256 tokenId, uint256 countryId) external virtual onlyOwner exists(tokenId) {
        if (!_metas[tokenId]._sanctions.get(countryId)) {
            Metadata storage meta = _metas[tokenId];
            meta._sanctions.set(countryId);
            meta._anySanctions = true;
            emit SanctionsMatch(tokenId, countryId);
        }
    }

    function isSanctionsMonitored(uint256 tokenId) public view virtual exists(tokenId) returns (bool) {
        return mintedAt(tokenId) >= block.timestamp - 365 days;
    }

    function isSanctionsSafe(uint256 tokenId) external view virtual exists(tokenId) returns (bool) {
        return (isSanctionsMonitored(tokenId) && !_metas[tokenId]._anySanctions);
    }

    function isSanctionsSafeIn(uint256 tokenId, uint256 countryId) external view virtual exists(tokenId) returns (bool) {
        return (isSanctionsMonitored(tokenId) && !_metas[tokenId]._sanctions.get(countryId));
    }

    function subjectType(uint256 tokenId) external view virtual exists(tokenId) returns (uint16) {
        return _metas[tokenId]._subjectType;
    }

    function mintedAt(uint256 tokenId) public view virtual exists(tokenId) returns (uint256) {
        return _metas[tokenId]._mintedAt;
    }

    function addTrait(uint256 tokenId, string memory trait) external virtual onlyOwner exists(tokenId) {
        Metadata storage meta = _metas[tokenId];
        uint256 index = _traitsIndex.add(trait);
        meta._traits.set(index);

        emit TraitAdded(tokenId, trait);
    }

    function removeTrait(uint256 tokenId, string memory trait) external virtual onlyOwner exists(tokenId) {
        Metadata storage meta = _metas[tokenId];
        (bool found, uint256 index) = _traitsIndex.indexOf(trait);

        // if the trait has been seen before and is set
        if (found && meta._traits.get(index)) {
            meta._traits.unset(index);
            emit TraitRemoved(tokenId, trait);
        }
    }

    function hasTrait(uint256 tokenId, string memory trait) external view virtual exists(tokenId) returns (bool) {
        (bool found, uint256 index) = _traitsIndex.indexOf(trait);
        return found ? _metas[tokenId]._traits.get(index) : false;
    }

    function traits(uint256 tokenId) external view virtual exists(tokenId) returns (string[] memory) {
        // The following logic is nice and fun, but is necessary so we always allocate a set
        // amount of memory necessary at each stage.

        // this will be the token traits bitmap
        BitMapsUpgradeable.BitMap storage tokenTraits = _metas[tokenId]._traits;

        // this makes a variable to hold a list of all indexes in the _traitsIndex that
        // are set in the tokenTraits bitmap.  We initialize it to be the size of the whole
        // _traitsIndex in case every single trait we've ever known about is true. Then,
        // we keep running track of the length of the indexes, so we know how much of the
        // allocated space is used.
        uint256[] memory indexes = new uint256[](_traitsIndex.length());
        uint256 indexLength = 0;

        // For all possible traits, see if the trait is set in the token, and if so, add
        // the index of the trait to our list of indexes.
        for (uint256 i = 0; i < _traitsIndex.length(); i++) {
            if (tokenTraits.get(i)) {
                indexes[indexLength] = i;
                indexLength += 1;
            }
        }

        // now make a result that's exactly as big as it needs to be,
        // and fill it w/ the actual strings from our _traitsIndex
        string[] memory result = new string[](indexLength);
        for (uint256 i = 0; i < indexLength; i++) {
            result[i] = _traitsIndex.at(indexes[i]);
        }

        return result;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable, IERC721MetadataUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external virtual onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
        delete _metas[tokenId];
    }

    function burn(uint256 tokenId) external virtual exists(tokenId) {
        // if the message sender is the token owner or the contract owner, allow burning
        address tokenOwner = ERC721Upgradeable.ownerOf(tokenId);
        require(_msgSender() == tokenOwner || _msgSender() == owner(), "Caller cannot burn");

        _burn(tokenId);
    }

    modifier exists(uint256 tokenId) {
        require(_exists(tokenId), "Nonexistent token");
        _;
    }

    function noop() internal pure virtual {
        revert("PID Tokens cannot be transferred");
    }
}
