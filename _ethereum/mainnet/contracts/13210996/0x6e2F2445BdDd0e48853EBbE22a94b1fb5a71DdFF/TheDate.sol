// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC165.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./base64.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./IWETH.sol";

contract TheDate is ERC721Enumerable, AccessControl, IERC2981, ReentrancyGuard {
    // ==== Roles ====
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    // ==== Parameters ====
    // == DAO controlled parameters ==
    uint256 public claimingPrice = 0.01 ether;
    uint256 public reservePrice = 0.01 ether;
    uint256 public minBidIncrementBps = 1000;
    uint256 public engravingPrice = 0.05 ether;
    uint256 public erasingPrice = 0.1 ether;
    uint256 public noteSizeLimit = 100;

    // == Admin controlled parameters ==
    uint256 public royaltyBps = 1000;
    string public tokenDescription = "The Date is a metadata-based NFT art project about time. " 
        "Each fleeting day would be imprinted into an NFT artwork immutably lasting forever. " 
        "The owner can engrave or erase a note on the artwork as an additional metadata. " 
        "The Date is metadata. Feel free to use The Date in any way you want.";
    string[] public svgImageTemplate = [''
        '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500">'
        '<rect width="100%" height="100%" fill="black" />'
        '<style>.base { fill: white; font-family: monospace; dominant-baseline: middle; text-anchor: middle; }</style>'
        '<text x="50%" y="50%" font-size="50px" class="base">',
        '{{date}}',
        '</text><text x="50%" y="90%" font-size="10px" class="base">',
        '{{note}}',
        '</text></svg>'];

    // == External contracts ==
    address payable private immutable _foundation;
    address private immutable _weth;
    address private immutable _loot;

    // ==== Events ====
    // == Parameter-related Events ==
    event ClaimingPriceChanged(uint256 claimingPrice);
    event AuctionReservePriceChanged(uint256 reservePrice);
    event AuctionMinBidIncrementBpsChanged(uint256 minBidIncrementBps);
    event EngravingPriceChanged(uint256 amount);
    event ErasingPriceChanged(uint256 amount);
    event NoteSizeLimitChanged(uint256 length);

    // == Auction-related events ==
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event AuctionSettled(uint256 indexed tokenId, address indexed winner, uint256 amount);
    event ArtworkClaimed(uint256 indexed tokenId, address indexed owner);
    event ArtworkAirdropped(uint256 indexed tokenId, address indexed owner);

    // == Note-related events ==
    event NoteEngraved(uint256 indexed tokenId, address indexed owner, string note);
    event NoteErased(uint256 indexed tokenId, address indexed owner);

    // ==== Storage ====
    // == Note ==
    mapping(uint256 => string) private _notes;

    // == Auction ==
    mapping(uint256 => address) private _highestBidder;
    mapping(uint256 => uint256) private _highestBid;

    // There is at most one unchaimed and auctioned token.
    uint256 private _lastUnchaimedAuctionedTokenId = 0;

    // ==== Parameter Related Functions ==== 
    // == DAO controlled parameters ==
    function setClaimingPrice(uint256 claimingPrice_) external onlyRole(DAO_ROLE) {
        claimingPrice = claimingPrice_;
        emit ClaimingPriceChanged(claimingPrice);
    }

    function setAuctionReservePrice(uint256 reservePrice_) external onlyRole(DAO_ROLE) {
        reservePrice = reservePrice_;
        emit AuctionReservePriceChanged(reservePrice);
    }

    function setAuctionMinBidIncrementBps(uint256 minBidIncrementBps_) external onlyRole(DAO_ROLE) {
        minBidIncrementBps = minBidIncrementBps_;
        emit AuctionMinBidIncrementBpsChanged(minBidIncrementBps);
    }

    function setEngravingPrice(uint256 engravingPrice_) external onlyRole(DAO_ROLE) {
        engravingPrice = engravingPrice_;
        emit EngravingPriceChanged(engravingPrice);
    }

    function setErasingPrice(uint256 erasingPrice_) external onlyRole(DAO_ROLE) {
        erasingPrice = erasingPrice_;
        emit ErasingPriceChanged(erasingPrice);
    }
    
    function setNoteSizeLimit(uint256 noteSizeLimit_) external onlyRole(DAO_ROLE) {
        noteSizeLimit = noteSizeLimit_;
        emit NoteSizeLimitChanged(noteSizeLimit);
    }

    // == Admin controlled parameters ==
    function setRoyaltyBps(uint256 royaltyBps_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(royaltyBps_ <= 10000, "royaltyBps should be within [0, 10000]");
        royaltyBps = royaltyBps_;
    }

    function setTokenDescription(string memory tokenDescription_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenDescription = tokenDescription_;
    }

    function setSVGImageTemplate(string[] memory svgImageTemplate_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        svgImageTemplate = svgImageTemplate_;
    }

    // ==== Owner related functions ==== 
    // == Owner related modifiers ==
    modifier onlyOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Caller should be the owner of the artwork");
        _;
    }

    // == Note related operations ==
    modifier validNote(string memory note) {
        require(bytes(note).length < noteSizeLimit, "Note should be shorter than noteSizeLimit");
        _;
    }

    function engraveNote(uint256 tokenId, string memory note) external payable onlyOwner(tokenId) validNote(note) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || msg.value >= engravingPrice, "Should pay engravingPrice");
        require(bytes(_notes[tokenId]).length == 0, "Note should be empty before engraving");

        _notes[tokenId] = note;
        _foundation.transfer(msg.value);
        emit NoteEngraved(tokenId, ownerOf(tokenId), note);
    }

    function eraseNote(uint256 tokenId) external payable onlyOwner(tokenId) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || msg.value >= erasingPrice, "Should pay erasingPrice");
        require(bytes(_notes[tokenId]).length > 0, "Note should be nonempty before erasing");

        _notes[tokenId] = "";
        _foundation.transfer(msg.value);
        emit NoteErased(tokenId, ownerOf(tokenId));
    }

    // ==== Metadata functions ====
    function getDate(uint256 tokenId) public pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day) = daysToDate(tokenId);
        string memory yearStr = Strings.toString(year);
        string memory monthStr = Strings.toString(month);
        if (bytes(monthStr).length == 1) {
            monthStr = string(abi.encodePacked("0", monthStr));
        }
        string memory dayStr = Strings.toString(day);
        if (bytes(dayStr).length == 1) {
            dayStr = string(abi.encodePacked("0", dayStr));
        }
        return string(abi.encodePacked(yearStr, "-", monthStr, "-", dayStr));
    }

    function getNote(uint256 tokenId) public view returns (string memory) {
        return _notes[tokenId];
    }
    
    function _stringEquals(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function escapeHTML(string memory s) public pure returns (string memory) {
        bytes memory b = bytes(s);
        string memory output = ""; 
        for (uint i = 0; i < b.length; i++) {
            if (b[i] == '<') {
                output = string(abi.encodePacked(output, "&lt;"));
            } else if (b[i] == '>') {
                output = string(abi.encodePacked(output, "&gt;"));
            } else if (b[i] == '&') {
                output = string(abi.encodePacked(output, "&amp;"));
            } else if (b[i] == '"') {
                output = string(abi.encodePacked(output, "&quot;"));
            } else if (b[i] == "'") {
                output = string(abi.encodePacked(output, "&apos;"));
            } else {
                output = string(abi.encodePacked(output, b[i]));
            }
        }
        return output;
    }

    function escapeQuotes(string memory symbol) public pure returns (string memory) {
        bytes memory symbolBytes = bytes(symbol);
        uint quotesCount = 0;
        for (uint i = 0; i < symbolBytes.length; i++) {
            if (symbolBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes = new bytes(symbolBytes.length + (quotesCount));
            uint256 index;
            for (uint i = 0; i < symbolBytes.length; i++) {
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = '\\';
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
    }

    function generateSVGImage(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "tokenId is non-existent");
        string memory date = getDate(tokenId);
        string memory note = getNote(tokenId);
        
        string memory output = "";
        for (uint i = 0; i < svgImageTemplate.length; ++i) {
            string memory part;
            if (_stringEquals(svgImageTemplate[i], "{{date}}")) {
                part = date;
            } else if (_stringEquals(svgImageTemplate[i], "{{note}}")) {
                part = escapeHTML(note);
            } else {
                part = svgImageTemplate[i];
            }
            output = string(abi.encodePacked(output, part));
        }

        return output;
    }

    function generateMetadata(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "tokenId is non-existent");
        string memory image = Base64.encode(
            bytes(generateSVGImage(tokenId))
        );

        string memory json = string(abi.encodePacked(
            '{"name": "The Date #', 
            Strings.toString(tokenId),
            ': ', 
            getDate(tokenId), 
            '", "description": "',
            escapeQuotes(tokenDescription),
            '", "image": "data:image/svg+xml;base64,', 
            image, 
            '"}'
        ));

        return json;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "tokenId is nonexistent");
        string memory output = string(abi.encodePacked(
            'data:application/json;base64,', 
            Base64.encode(bytes(generateMetadata(tokenId)))
        ));

        return output;
    }
    
    // ==== Claiming related functions ====
    modifier enoughFund() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || 
            IERC721(_loot).balanceOf(msg.sender) > 0 || 
            msg.value >= claimingPrice, "Should pay claimingPrice or own a Loot NFT");
        _;
    }

    function _mintUnclaimedAndUnauctioned(address to, uint256 tokenId) internal {
        require(tokenId < block.timestamp / 1 days, "Only past tokenId is claimable");
        require(_highestBidder[tokenId] == address(0) && _highestBid[tokenId] == 0, "tokenId should not be auctioned");
        require(!_exists(tokenId), "tokenId should not be claimed");

        _mint(to, tokenId);
    }
    
    function available(uint256 tokenId) external view returns (bool) {
        return (tokenId < block.timestamp / 1 days) && 
            (_highestBidder[tokenId] == address(0) && _highestBid[tokenId] == 0) &&
            (!_exists(tokenId));
    }

    function claim(uint256 tokenId) external payable nonReentrant enoughFund {
        settleLastAuction();

        _mintUnclaimedAndUnauctioned(msg.sender, tokenId);

        if (msg.value > 0) {
            _foundation.transfer(msg.value);
        }
        emit ArtworkClaimed(tokenId, msg.sender);
    }

    function airdrop(address[] memory addresses, uint256[] memory tokenIds) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        settleLastAuction();
        
        for (uint i = 0; i < tokenIds.length; ++i) {
            address to = addresses[i];
            uint256 tokenId = tokenIds[i];
            _mintUnclaimedAndUnauctioned(to, tokenId);

            emit ArtworkAirdropped(tokenId, to);
        }
    }

    // ==== Auction related functions ==== 
    function getHighestBid(uint256 tokenId) external view returns (address bidder, uint256 amount) {
        return (_highestBidder[tokenId], _highestBid[tokenId]);
    }

    function settleLastAuction() public {
        uint256 tokenId = _lastUnchaimedAuctionedTokenId;

        if (block.timestamp / 1 days > tokenId &&  _highestBidder[tokenId] != address(0) && _highestBid[tokenId] > 0 
            && !_exists(tokenId)) {
            _settleAuction(tokenId);
        }
    }

    function getCurrentAuctionTokenId() public view returns (uint256) {
        return block.timestamp / 1 days;
    }

    function getCurrentMinimumBid() public view returns (uint256 amount) {
        uint256 tokenId = block.timestamp / 1 days;
        uint256 minimumBid = _highestBid[tokenId] * (10000 + minBidIncrementBps) / 10000;
        if (reservePrice > minimumBid) {
            minimumBid = reservePrice;
        }
        return minimumBid;
    }

    function placeBid() public payable nonReentrant {
        uint256 tokenId = block.timestamp / 1 days;
        uint256 amount = msg.value;

        require(amount >= reservePrice, "Must send more than reservePrice");
        require(amount >= getCurrentMinimumBid(), "Must send more than last bid by minBidIncrementBps");

        if (_highestBidder[tokenId] == address(0)) {
            settleLastAuction();
            _lastUnchaimedAuctionedTokenId = tokenId;
        } else {
            _safeTransferETHWithFallback(_highestBidder[tokenId], _highestBid[tokenId]);
        }

        _highestBidder[tokenId] = msg.sender;
        _highestBid[tokenId] = amount;

        emit BidPlaced(tokenId, msg.sender, amount);
    }

    /// @notice Settle the auction and send the highest bid to the beneficiary.
    function _settleAuction(uint256 tokenId) internal {
        require(block.timestamp / 1 days > tokenId, "Auction not yet ended");
        require(_highestBidder[tokenId] != address(0) && _highestBid[tokenId] > 0, "There should be at least a bid for the date");
        require(!_exists(tokenId), "Should not reclaim the auction");

        // It cannot be a safeMint. The Auction will never ends.
        _mint(_highestBidder[tokenId], tokenId);
        _foundation.transfer(_highestBid[tokenId]);

        emit AuctionSettled(tokenId, _highestBidder[tokenId], _highestBid[tokenId]);
    }

    /// @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(_weth).deposit{ value: amount }();
            IERC20(_weth).transfer(to, amount);
        }
    }

    /// @notice Transfer ETH and return the success status.
    /// @dev This function only forwards 30,000 gas to the callee.
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    // ==== Constructor ====
    constructor(address foundation_,
                address weth_,
                address loot_) 
        ERC721("The Date", "DATE")
    {
        _foundation = payable(foundation_);
        _weth = weth_;
        _loot = loot_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DAO_ROLE, msg.sender);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) 
        public view override(ERC721Enumerable, AccessControl, IERC165) returns (bool) 
    {
        return ERC721Enumerable.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) || 
            type(IERC2981).interfaceId == interfaceId ||
            type(IERC165).interfaceId == interfaceId;
    }

    // ==== Royalty Functions ====
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external view override returns (address receiver, uint256 royaltyAmount)
    {
        return (_foundation, (salePrice * royaltyBps) / 10000);
    }

    // ==== Day =====
        // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    int256 constant OFFSET19700101 = 2440588;

    function daysToDate(uint256 _days)
        public
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    // Default functions
    receive() external payable {
        placeBid();
    }

    fallback() external payable {

    }
}
