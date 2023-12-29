// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Errors.sol";
import "./PaymentSplitter.sol";

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./MerkleProof.sol";
import "./Math.sol";
import "./AccessControl.sol";
import "./Address.sol";
import "./Ownable.sol";

contract WithinWithout is Context, PaymentSplitter, ERC721, ReentrancyGuard, AccessControl, Ownable {
    using Address for address;

    struct Collection {
        uint256 priceInWei;
        uint256 maxPresaleMints;
        uint256 maxReservedMints;
        uint256 maxSupply;
        uint256 maxMintsPerPurchase;
    }

    struct TokenData {
        uint256 printsCount;
        bytes32 tokenHash;
    }

    Collection public collection;

    string public script;

    event Mint(uint256 indexed tokenId, address indexed minter, bytes32 tokenHash, uint256 fingerprintsBalance);

    mapping(uint256 => TokenData) public tokenIdToTokenData;

    uint256 private presaleMintCount = 0;
    uint256 private reservedMintCount = 0;
    uint256 public totalSupply = 0;

    bool public presaleStarted;

    uint256 public publicSaleStartingBlock;

    mapping(address => bool) public presaleMints;

    bytes32 public merkleRootSingleMint;
    bytes32 public merkleRootDoubleMint;

    address public prints;

    string private baseURI_ = "https://www.withinwithout.xyz/api/token/metadata/";

    constructor(
        address[] memory payees_,
        uint256[] memory shares_,
        address[] memory admins_,
        Collection memory collection_,
        address prints_
    ) ERC721("Within/Without", "WW") PaymentSplitter(payees_, shares_) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        for (uint256 i = 0; i < admins_.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, admins_[i]);
        }
        collection = collection_;
        prints = prints_;
    }

    function publicSupplyRemaining() public view returns (uint256) {
        return collection.maxSupply - totalSupply - (collection.maxReservedMints - reservedMintCount);
    }

    function publicSaleStarted() public view returns (bool) {
        return presaleStarted && block.number >= publicSaleStartingBlock;
    }

    function startPresale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicSaleStartingBlock = block.number + 720; // ~ Three hours after presale starts
        presaleStarted = true;
    }

    function updatePublicSaleStartBlock(uint256 startingBlock) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicSaleStartingBlock = startingBlock;
    }

    function setMerkleRoots(bytes32 merkleRootSingleMint_, bytes32 merkleRootDoubleMint_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        merkleRootSingleMint = merkleRootSingleMint_;
        merkleRootDoubleMint = merkleRootDoubleMint_;
    }

    function mintReserved(uint256 count) public nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        if (count == 0) revert CountCannotBeZero();
        if (reservedMintCount >= collection.maxReservedMints) revert ReserveMintCountExceeded();

        // Edge case: minter wants to buy multiple but we have less supply than their count,
        //            but don't want them to get nothing
        uint256 remaining = collection.maxReservedMints - reservedMintCount;
        count = uint256(Math.min(count, remaining));

        reservedMintCount += count;
        handleMint(_msgSender(), count);
    }

    function purchasePresale(uint256 count, bytes32[] calldata _merkleProof) external payable nonReentrant {
        if (!presaleStarted) revert PresaleNotOpen();
        if (publicSaleStarted()) revert PublicSaleAlreadyOpen();
        if (presaleMintCount >= collection.maxPresaleMints) revert PresaleSoldOut();
        if (publicSupplyRemaining() == 0) revert CollectionSoldOut();
        if (presaleMints[_msgSender()] == true) revert AlreadyMintedInPresale();
        if (count == 0) revert CountCannotBeZero();
        if (count > 2) revert CountExceedsMaxMints();

        address minter = _msgSender();
        bytes32 leaf = keccak256(abi.encodePacked(minter));

        if (count == 1) {
            // @dev: note, everyone in the double mint merkle tree is also in the single mint tree, so people
            // eligible for 2 mints can mint only 1 if they want
            if (!MerkleProof.verify(_merkleProof, merkleRootSingleMint, leaf)) revert NotEligible();
        }
        if (count == 2) {
            if (!MerkleProof.verify(_merkleProof, merkleRootDoubleMint, leaf)) revert NotEligible();
        }

        // Edge case: minter wants to buy multiple but we have less supply than their count,
        //            but don't want them to get nothing
        uint256 remaining = collection.maxPresaleMints - presaleMintCount;
        count = uint256(Math.min(count, remaining));

        presaleMints[minter] = true;
        presaleMintCount += count;
        mint(minter, collection.priceInWei, count);
    }

    function purchase(uint256 count) external payable nonReentrant {
        if (!publicSaleStarted()) revert PublicSaleNotOpen();
        if (count == 0) revert CountCannotBeZero();
        if (publicSupplyRemaining() == 0) revert CollectionSoldOut();
        address minter = _msgSender();

        if (count > collection.maxMintsPerPurchase) revert CountExceedsMaxMints();

        // Edge case: minter wants to buy multiple but we have less supply than their count,
        //            but don't want them to get nothing
        count = uint256(Math.min(count, publicSupplyRemaining()));

        mint(minter, collection.priceInWei, count);
    }

    function mint(
        address minter,
        uint256 priceInWei,
        uint256 count
    ) private {
        if (minter.isContract()) revert CannotPurchaseFromContract();
        uint256 cost = priceInWei * count;
        if (msg.value < cost) revert InsufficientFundsForPurchase();
        if (msg.value > cost) {
            // Refund any excess
            payable(minter).transfer(msg.value - cost);
        }
        handleMint(minter, count);
    }

    function handleMint(address minter, uint256 count) private {
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = totalSupply;
            bytes32 tokenHash = keccak256(
                abi.encodePacked(blockhash(block.number - 1), block.number, block.timestamp, minter, tokenId)
            );
            uint256 fingerprintsBalance = IERC20(prints).balanceOf(minter);

            tokenIdToTokenData[tokenId] = TokenData(fingerprintsBalance, tokenHash);
            totalSupply++;

            _safeMint(minter, tokenId);
            emit Mint(tokenId, minter, tokenHash, fingerprintsBalance);
        }
    }

    function getTokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 seen = 0;
        for (uint256 i; i < totalSupply; i++) {
            if (ownerOf(i) == _owner) {
                tokenIds[seen] = i;
                seen++;
            }
        }
        return tokenIds;
    }

    function setBaseURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI_ = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function setScript(string memory script_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        script = script_;
    }

    function updateCollection(Collection memory collection_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!presaleStarted, "The sale has already started");
        collection = collection_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
