// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";

contract SquareeV1 is ERC721, ReentrancyGuard {
    // SquareeV1 is the contract for collective digital artmaking project Squaree.
    // Visit squaree.io or squaree.crypto for more information.

    address payable private creator;

    struct squaree {
        address minter;
        bytes4 colour;
        uint256 mintedAt;
        address[] authors;
    }

    struct marketData {
        address payable currentOwner;
        uint256 soldAt;
        uint256 lastPrice;
        uint256 currentAsk;
        uint256 currentBid;
        address payable currentBidder;
    }

    bytes4[][11] private colours; // list of colours of all squarees

    uint256[][11] private mintedSquarees; // squarees, available on market place
    uint256[][11] private mintableSquarees; // squarees, availabe for minting
    mapping(uint256 => mapping(uint256 => bool)) private isMintable;
    mapping(uint256 => mapping(uint256 => bool)) private isTradeable;

    mapping(uint256 => mapping(uint256 => squaree)) private squarees; // inidividual squaree in [layer][region]
    mapping(uint256 => mapping(uint256 => marketData))
        private squareeMarketData; // market data about squaree in [layer][region]

    mapping(uint256 => mapping(uint256 => uint256)) private locked; // locked funds

    ////// INITIALIZATION //////

    constructor() public ERC721("Squaree", "SQRE") {
        creator = msg.sender;

        for (uint256 i = 0; i < 5; i++) {
            // initializing all 11 layers hits block gas limit. Next layers can be initialized by calling `initLayer`
            colours[i] = new bytes4[](2**i);
        }

        makeMintable(0, 0, new address[](0));
    }

    function initLayer(uint256 layer) external {
        require(colours[layer].length == 0, "layer initialized");
        colours[layer] = new bytes4[](2**layer);
    }

    ////// VARIOUS GETTERS //////

    function getColours() external view returns (bytes4[][11] memory) {
        return colours;
    }

    function getSquaree(uint256 layer, uint256 region)
        external
        view
        returns (squaree memory)
    {
        return squarees[layer][region];
    }

    function getLayer(uint256 layer) external view returns (squaree[] memory) {
        uint256 len = 2**layer;
        squaree[] memory sq = new squaree[](len);

        for (uint256 i = 0; i < len; i++) {
            sq[i] = squarees[layer][i];
        }
        return sq;
    }

    function mintableSquareeCount()
        external
        view
        returns (uint256[11] memory mintable)
    {
        for (uint256 i = 0; i < 11; i++) {
            mintable[i] = mintableSquarees[i].length;
        }
    }

    function getMintableSquarees()
        external
        view
        returns (uint256[][11] memory mintableSquareesList)
    {
        return mintableSquarees;
    }

    function getMintableSquarees(uint256 layer)
        external
        view
        returns (uint256[] memory regions)
    {
        return mintableSquarees[layer];
    }

    function mintedSquareeCount()
        external
        view
        returns (uint256[11] memory minted)
    {
        for (uint256 i = 0; i < 11; i++) {
            minted[i] = mintedSquarees[i].length;
        }
    }

    function getMintedSquarees()
        external
        view
        returns (uint256[][11] memory mintedSquareesList)
    {
        return mintedSquarees;
    }

    function getMintedSquarees(uint256 layer)
        external
        view
        returns (uint256[] memory regions)
    {
        return mintedSquarees[layer];
    }

    function getSquareeMarketData(uint256 layer, uint256 region)
        external
        view
        returns (marketData memory)
    {
        return squareeMarketData[layer][region];
    }

    function getLayerMarketData(uint256 layer)
        external
        view
        returns (marketData[] memory)
    {
        uint256[] storage ms = mintedSquarees[layer];
        uint256 len = ms.length;
        marketData[] memory md = new marketData[](len);

        for (uint256 i = 0; i < len; i++) {
            md[i] = squareeMarketData[layer][ms[i]];
        }
        return md;
    }

    function mintedTotal() external view returns (uint256) {
        return totalSupply();
    }

    ////// MINTING //////
    event squareeMinted(
        address minter,
        uint256 layer,
        uint256 region,
        uint256 number
    );

    // makes squaree ready to be minted
    function makeMintable(
        uint256 layer,
        uint256 region,
        address[] memory authors
    ) internal {
        isMintable[layer][region] = true;
        mintableSquarees[layer].push(region);
        squarees[layer][region].authors = authors;
    }

    function mintSquaree(
        uint256 layer,
        uint256 region,
        bytes4 colour
    ) external payable {
        require(isMintable[layer][region], "Squaree is not mintable");
        require(
            msg.value == (((2**(10 - layer)) * 1 ether)),
            "Wrong price for this layer"
        );
        require(
            validateColour(layer, region, colour),
            "Sibling colour should be different"
        );

        removeFromMintableList(layer, region);
        addToTradeableList(layer, region);

        uint256 uniqueID = getUniqueID(layer, region);

        _safeMint(msg.sender, uniqueID);

        emit squareeMinted(msg.sender, layer, region, totalSupply());

        squaree storage sq = squarees[layer][region];
        sq.minter = msg.sender;
        sq.colour = colour;
        sq.mintedAt = block.timestamp;
        sq.authors.push(msg.sender);

        colours[layer][region] = colour;

        address payable parentSquareeOwner =
            payable(squarees[layer - 1][parent(layer, region)].minter);

        if (parentSquareeOwner == address(0)) {
            parentSquareeOwner = creator;
        }

        safeTransfer(parentSquareeOwner, (msg.value * 9) / 10);
        locked[layer][region] = msg.value / 10;

        if (layer < 10) {
            uint256 region1;
            uint256 region2;
            (region1, region2) = children(layer, region);
            makeMintable(layer + 1, region1, sq.authors);
            makeMintable(layer + 1, region2, sq.authors);
        }

        if (totalSupply() == 2047) {
            squareeFinishedAt = block.timestamp;
        }
    }

    // prevent two squarees of same region to have the same colour
    function validateColour(
        uint256 layer,
        uint256 region,
        bytes4 colour
    ) internal view returns (bool) {
        if (layer == 0) {
            return true;
        }

        uint256 region1;
        uint256 region2;
        (region1, region2) = children(layer - 1, (parent(layer, region)));
        return
            region == region1
                ? squarees[layer][region2].colour != colour
                : squarees[layer][region1].colour != colour;
    }

    ////// MARKETPLACE //////

    event squareeForSale(
        uint256 indexed layer,
        uint256 indexed region,
        uint256 price
    );

    event squareeOffer(
        uint256 indexed layer,
        uint256 indexed region,
        uint256 price,
        address bidder
    );

    function setSquareeMarketPrice(
        uint256 layer,
        uint256 region,
        uint256 newPrice
    ) public {
        marketData storage md = squareeMarketData[layer][region];
        require(
            md.currentOwner == msg.sender,
            "Only squaree owner can set the price"
        );

        if (newPrice <= md.currentBid) {
            transferSquaree(layer, region);
        } else {
            md.currentAsk = newPrice;
            emit squareeForSale(layer, region, newPrice);
        }
    }

    function setSquareeMaxPrice(uint256 layer, uint256 region) external {
        setSquareeMarketPrice(layer, region, uint256(-1));
    }

    function makeSquareeOffer(uint256 layer, uint256 region)
        external
        payable
        nonReentrant
    {
        require(isTradeable[layer][region], "Squaree is not yet tradeable");
        marketData storage md = squareeMarketData[layer][region];
        require(md.currentBid < msg.value, "Current bid not increased");

        safeTransfer(md.currentBidder, md.currentBid);
        md.currentBidder = msg.sender;
        md.currentBid = msg.value;

        emit squareeOffer(layer, region, msg.value, msg.sender);
        if (msg.value >= md.currentAsk) {
            transferSquaree(layer, region);
        }
    }

    function increaseSquareeOffer(uint256 layer, uint256 region)
        external
        payable
        nonReentrant
    {
        marketData storage md = squareeMarketData[layer][region];
        require(
            md.currentBidder == msg.sender,
            "Only current bidder can increase the offer"
        );

        md.currentBid += msg.value;
        emit squareeOffer(layer, region, md.currentBid, msg.sender);
        if (md.currentBid >= md.currentAsk) {
            transferSquaree(layer, region);
        }
    }

    function withdrawSquareeOffer(uint256 layer, uint256 region)
        external
        nonReentrant
    {
        marketData storage md = squareeMarketData[layer][region];
        require(
            md.currentBidder == msg.sender,
            "Only current bidder can withdraw the offer"
        );

        md.currentBidder.transfer((md.currentBid * 9) / 10);
        creator.transfer(md.currentBid / 10);

        delete md.currentBid;
        delete md.currentBidder;

        emit squareeOffer(layer, region, 0, address(0));
    }

    function transferSquaree(uint256 layer, uint256 region) internal {
        marketData storage md = squareeMarketData[layer][region];

        safeTransfer(md.currentOwner, (md.currentBid * 97) / 100);
        creator.transfer((md.currentBid * 3) / 100);

        _transfer(
            md.currentOwner,
            md.currentBidder,
            getUniqueID(layer, region)
        );

        md.lastPrice = md.currentBid;
        md.currentBid = 0;

        delete md.currentBidder;
    }


    ////// AFTER FINISH //////
    uint256 squareeFinishedAt;

    function withdrawLocked(uint256 layer, uint256 region)
        external
        nonReentrant
    {
        withdrawLockedInternal(layer, region);
    }

    function withdrawLockedInternal(uint256 layer, uint256 region) internal {
        require(squareeFinishedAt > 0, "Squaree not finished yet");
        uint256 lockedAmount = locked[layer][region];
        require(lockedAmount > 0, "Already withdrawn");
        delete locked[layer][region]; // delete immediately to prevent reentrancy

        uint256 squareePeriod =
            squareeFinishedAt - squarees[layer][region].mintedAt;

        uint256 withdrawable;
        if (squareePeriod != 0) {
            uint256 holdingPeriod =
                squareeFinishedAt - squareeMarketData[layer][region].soldAt; // overflow is not an issue here
            if (holdingPeriod <= squareePeriod) {
                withdrawable = (lockedAmount * holdingPeriod) / squareePeriod;
                safeTransfer(
                    squareeMarketData[layer][region].currentOwner,
                    withdrawable
                );
            }
        } else {
            withdrawable = lockedAmount;
            squareeMarketData[layer][region].currentOwner.transfer(
                withdrawable
            );
        }

        if (lockedAmount > withdrawable) {
            creator.transfer(lockedAmount - withdrawable);
        }
    }

    // to withdraw multiple, specify unique IDs instead od layers and regions
    function withdrawLockedMultiple(uint256[] calldata uniqueIDs)
        external
        nonReentrant
    {
        for (uint256 i = 0; i < uniqueIDs.length; i++) {
            withdrawLockedInternal(
                uniqueIDs[i] / 10000 - 1,
                (uniqueIDs[i] % 10000) - 1
            );
        }
    }

    ////// HELPERS //////

    function safeTransfer(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount, gas: 2300}("");
        // require(success, "Transfer failed.");
        if (!success) {
            creator.transfer(amount);
        }
    }

    // convert layer and region to NFT unique ID
    function getUniqueID(uint256 layer, uint256 region)
        internal
        pure
        returns (uint256)
    {
        return 10000 * (layer + 1) + region + 1;
    }

    // returns regions of squarees above chosen region of certain layer
    function children(uint256 layer, uint256 region)
        internal
        pure
        returns (uint256 region1, uint256 region2)
    {
        if (layer % 2 == 0) {
            return (2 * region, 2 * region + 1);
        }
        uint256 rowLength = 2**((layer + 1) / 2);
        return (
            2 * region - (region % rowLength),
            2 * region + rowLength - (region % rowLength)
        );
    }

    // returns region of squaree below chosen region of certain layer
    function parent(uint256 layer, uint256 region)
        internal
        pure
        returns (uint256)
    {
        if (layer % 2 == 1) {
            return region % 2 == 0 ? region / 2 : (region - 1) / 2;
        }
        uint256 rowLength = 2**((layer + 1) / 2);
        return (region % rowLength) + rowLength * (region / rowLength / 2);
    }

    function removeFromMintableList(uint256 layer, uint256 region) internal {
        isMintable[layer][region] = false;

        uint256 len = mintableSquarees[layer].length;
        for (uint256 i = 0; i < len - 1; i++) {
            if (mintableSquarees[layer][i] == region) {
                mintableSquarees[layer][i] = mintableSquarees[layer][len - 1];
                break;
            }
        }
        mintableSquarees[layer].pop();
    }

    function addToTradeableList(uint256 layer, uint256 region) internal {
        isTradeable[layer][region] = true;
        mintedSquarees[layer].push(region);

        squareeMarketData[layer][region] = marketData(
            msg.sender,
            block.timestamp,
            msg.value,
            uint256(-1),
            0,
            address(0)
        );
    }

    ////// ERC721 OVERRRIDES //////

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        // must be here, if transfer happens outside
        super._transfer(from, to, tokenId);

        marketData storage md =
            squareeMarketData[tokenId / 10000 - 1][(tokenId % 10000) - 1];

        emit squareeForSale(
            tokenId / 10000 - 1,
            (tokenId % 10000) - 1,
            uint256(-1)
        );

        md.currentOwner = payable(to);
        md.currentAsk = uint256(-1);
        md.soldAt = block.timestamp;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(
            isTradeable[tokenId / 10000 - 1][(tokenId % 10000) - 1],
            "Squaree can not be sold"
        );
    }
}
