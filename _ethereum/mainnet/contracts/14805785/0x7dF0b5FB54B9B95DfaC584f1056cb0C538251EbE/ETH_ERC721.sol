// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC2981Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./IReserveAuctionFindersEth.sol";

contract ETH_ERC721 is
    OwnableUpgradeable,
    ERC721URIStorageUpgradeable,
    IERC2981Upgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Count of Tokens.
    CountersUpgradeable.Counter internal currentTokenId;

    // Mapping from tokenId to the royalty recipient's address.
    mapping(uint256 => address) internal tokenRoyaltyRecipient;

    bytes32 public whitelistRoot;

    address public zoraERC721TransferHelper;
    address public zoraReserveAuctionFindersEth;

    // Mapping from tokenId to the creators address.
    mapping(uint256 => address) public tokenCreator;

    function initialize(
        string memory _name,
        string memory _symbol,
        bytes32 _whitelistRoot,
        address _zoraERC721TransferHelper,
        address _zoraReserveAuctionFindersEth
    ) public initializer {
        __Ownable_init();
        __ERC721URIStorage_init();
        __ERC721_init(_name, _symbol);
        whitelistRoot = _whitelistRoot;
        zoraERC721TransferHelper = _zoraERC721TransferHelper;
        zoraReserveAuctionFindersEth = _zoraReserveAuctionFindersEth;
    }

    /**
     * @dev Mints One NFT to sender.
     */
    function mintToSender(
        uint256 _duration,
        uint256 _reserve_price,
        address _seller_funds_recipient,
        uint256 _start_time,
        string memory _uri,
        bytes32[] memory proof
    ) public returns (uint256) {
        require(
            isWhitelisted(whitelistRoot, msg.sender, proof),
            "Not whitelisted"
        );

        currentTokenId.increment();

        uint256 newTokenId = currentTokenId.current();
        _mint(_msgSender(), newTokenId);
        _setTokenURI(newTokenId, _uri);

        // Approve Zora V3 Transfer Helper
        approveMarketplace(zoraERC721TransferHelper);

        // Approve Mint Songs Marketplace
        approveMarketplace(address(this));

        address erc721Contract = address(this);
        uint256 duration = _duration;
        uint256 reserve_price = _reserve_price;
        address seller_funds_recipient = _seller_funds_recipient;
        uint256 start_time = _start_time;
        uint256 finders_fee_bps = 0;
        IReserveAuctionFindersEth findersEth = IReserveAuctionFindersEth(
            zoraReserveAuctionFindersEth
        );
        findersEth.createAuction(
            erc721Contract,
            newTokenId,
            duration,
            reserve_price,
            seller_funds_recipient,
            start_time,
            finders_fee_bps
        );

        tokenRoyaltyRecipient[newTokenId] = _seller_funds_recipient;
        tokenCreator[newTokenId] = _msgSender();

        return newTokenId;
    }

    /**
     * @dev Approves all MintSongs NFTs to be sold on approvedMarketplace.
     */
    function approveMarketplace(address _approvedMarketplace) internal {
        if (!isApprovedForAll(_msgSender(), _approvedMarketplace)) {
            setApprovalForAll(_approvedMarketplace, true);
        }
    }

    modifier onlyCreator(uint256 _tokenId) {
        require(
            _msgSender() == tokenCreator[_tokenId],
            "Only token creator can call this function"
        );
        _;
    }

    function updateTokenURI(uint256 _tokenId, string memory _uri)
        public
        onlyCreator(_tokenId)
    {
        _setTokenURI(_tokenId, _uri);
    }

    // TODO: Remove this function on next deployment
    function backfillTokenCreator() public onlyOwner {
        uint256 tokenId = currentTokenId.current();
        while (tokenId > 0) {
            tokenCreator[tokenId] = tokenRoyaltyRecipient[tokenId];
            tokenId--;
        }
    }

    function updateWhitelistRoot(bytes32 _whitelistRoot) public onlyOwner {
        whitelistRoot = _whitelistRoot;
    }

    function isWhitelisted(
        bytes32 root,
        address receiver,
        bytes32[] memory proof
    ) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(receiver));

        return MerkleProofUpgradeable.verify(proof, root, leaf);
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        uint256 royaltyFee = 100;
        uint256 royaltyPayment = (salePrice * royaltyFee) / 1000;

        return (tokenRoyaltyRecipient[tokenId], royaltyPayment);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
