// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IQuestry.sol";
import "./IERC165.sol";
import "./IERC2981.sol";
import "./ContentManageable.sol";

contract Questry is IQuestry, IERC2981, ERC721, ERC721Enumerable, Ownable, ContentManageable {
    using Strings for uint256;

    uint256 public constant TOKEN_ID_OFFSET = 100000;

    event AddContent(
        uint256 indexed contentId,
        uint256 price,
        uint256 maxSupply,
        string contentCID,
        uint32 startAuctionTime,
        uint32 endAuctionTime,
        uint96 royaltyBasisPoint
    );

    event BuyContent(
        uint256 indexed contentId,
        uint256 tokenIdForContent,
        uint256 remain,
        address indexed buyer
    );

    event UpdateContentCID(
        uint256 indexed contentId,
        string contentCID
    );

    event UpdateStartAuctionTime(
        uint256 indexed contentId,
        uint32 startAuctionTime
    );

    event UpdateEndAuctionTime(
        uint256 indexed contentId,
        uint32 endAuctionTime
    );

    event UpdateRoyaltyBasisPoint(
        uint256 indexed contentId,
        uint96 royaltyBasisPoint
    );

    /* ----------------- Fields ----------------- */

    uint256 public nextContentId = 1;

    mapping (uint256 => Content) private _contents;
    mapping (uint256 => uint256) private _lastTokenIdForContent;

    /* --------------- Constructor --------------- */

    constructor(
        string memory name,
        string memory symbol,
        address newOwner,
        address contentManager
    )
        ERC721(name, symbol)
        Ownable()
        ContentManageable(contentManager)
    {
        transferOwnership(newOwner);
    }

    /* ------------- Content Manager ------------- */

    function addContent(
        uint256 price,
        uint256 maxSupply,
        string memory contentCID,
        uint32 startAuctionTime,
        uint32 endAuctionTime,
        uint96 royaltyBasisPoint
    )
        external
        onlyContentManager
        override
    {
        require (maxSupply > 0, "maxSupply must be greater than 0");
        require (bytes(contentCID).length > 0, "no contentCID");

        uint256 contentId = nextContentId++;
        _contents[contentId] = Content({
            id: contentId,
            price: price,
            remain: maxSupply,
            maxSupply: maxSupply,
            contentCID: contentCID,
            startAuctionTime: startAuctionTime,
            endAuctionTime: endAuctionTime,
            royaltyBasisPoint: royaltyBasisPoint
        });

        emit AddContent(
            contentId,
            price,
            maxSupply,
            contentCID,
            startAuctionTime,
            endAuctionTime,
            royaltyBasisPoint
        );
    }

    function updateContentCID(
        uint256 contentId,
        string memory contentCID
    )
        external
        onlyContentManager
        override
    {
        require (validExistingContent(contentId), "invalid contentId");
        require (bytes(contentCID).length > 0, "no contentCID");
        _contents[contentId].contentCID = contentCID;

        emit UpdateContentCID(
            contentId,
            contentCID
        );
    }

    function updateStartAuctionTime(
        uint256 contentId,
        uint32 startAuctionTime
    )
        external
        onlyContentManager
        override
    {
        require (validExistingContent(contentId), "invalid contentId");
        _contents[contentId].startAuctionTime = startAuctionTime;

        emit UpdateStartAuctionTime(
            contentId,
            startAuctionTime
        );
    }

    function updateEndAuctionTime(
        uint256 contentId,
        uint32 endAuctionTime
    )
        external
        onlyContentManager
        override
    {
        require (validExistingContent(contentId), "invalid contentId");
        _contents[contentId].endAuctionTime = endAuctionTime;

        emit UpdateEndAuctionTime(
            contentId,
            endAuctionTime
        );
    }

    function updateRoyaltyBasisPoint(
        uint256 contentId,
        uint96 royaltyBasisPoint
    )
        external
        onlyContentManager
        override
    {
        require (validExistingContent(contentId), "invalid contentId");
        require (royaltyBasisPoint <= 10000, "royaltyBasisPoint <= 10000");
        _contents[contentId].royaltyBasisPoint = royaltyBasisPoint;

        emit UpdateRoyaltyBasisPoint(
            contentId,
            royaltyBasisPoint
        );
    }

    /* ----------------- Owner ----------------- */

    function withdraw()
        external
        onlyOwner
        override
    {
        payable(msg.sender).transfer(address(this).balance);
    }

    /* ----------------- Buyer ----------------- */

    function buyContent(
        uint256 contentId
    )
        external
        payable
        override
    {
        require (validExistingContent(contentId), "invalid contentId");

        Content storage content = _contents[contentId];
        require (content.price == msg.value, "invalid msg.value");
        require (content.remain > 0, "sold out");
        require (content.startAuctionTime < block.timestamp, "auction hasn't started");
        require (block.timestamp < content.endAuctionTime, "auction has ended");

        content.remain--;
        uint256 tokenIdForContent = ++_lastTokenIdForContent[contentId];
        uint256 tokenId = getTokenId(TokenIds({
            contentId: contentId,
            tokenIdForContent: tokenIdForContent
        }));

        _mint(msg.sender, tokenId);

        emit BuyContent(contentId, tokenIdForContent, content.remain, msg.sender);
    }

    /* ----------------- ERC721 ----------------- */

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override
        returns (string memory)
    {
        TokenIds memory ids = getIdsFromTokenId(tokenId);
        string storage contentCID = _contents[ids.contentId].contentCID;
        return string(abi.encodePacked(
            baseURI(),
            contentCID, "/",
            ids.tokenIdForContent.toString(), ".json"
        ));
    }

    /* ----------------- ERC2981 ----------------- */

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    )
        external
        view
        override
        returns (address recipient, uint256 royaltyAmount)
    {
        TokenIds memory ids = getIdsFromTokenId(tokenId);
        uint96 basisPoint = _contents[ids.contentId].royaltyBasisPoint;
        return (owner(), (salePrice * basisPoint) / 10000);
    }

    /* ----------------- Utility ----------------- */

    function getContent(
        uint256 contentId
    )
        external
        view
        override
        returns (Content memory)
    {
        require (validExistingContent(contentId), "invalid contentId");
        return _contents[contentId];
    }

    function getTokenId(
        TokenIds memory ids
    )
        public
        view
        returns (uint256)
    {
        require (validExistingContent(ids.contentId), "invalid contentId");
        require (ids.tokenIdForContent > 0, "invalid tokenIdForContent");
        return ids.contentId * TOKEN_ID_OFFSET + ids.tokenIdForContent;
    }

    function getIdsFromTokenId(
        uint256 tokenId
    )
        public
        view
        returns (TokenIds memory ids)
    {
        uint256 contentId = tokenId / TOKEN_ID_OFFSET;
        require (validExistingContent(contentId), "invalid contentId");

        uint256 tokenIdForContent = tokenId % TOKEN_ID_OFFSET;
        require (tokenIdForContent > 0, "invalid tokenIdForContent");

        return TokenIds({
            contentId: contentId,
            tokenIdForContent: tokenIdForContent
        });
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /* ----------------- Private ----------------- */

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function baseURI()
        private
        pure
        returns (string memory)
    {
        return "ipfs://";
    }

    function validExistingContent(
        uint256 contentId
    )
        private
        view
        returns (bool)
    {
        return contentId > 0 && _contents[contentId].id > 0;
    }
}
