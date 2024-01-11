// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./DateTime.sol";
import "./TokenURI.sol";

error DesImages__InvalidDate();
error DesImages__FutureDate();
error DesImages__NotEnoughETHSent();
error DesImages__TokenNotForSale();
error DesImages__TokenNotOwned();
error DesImages__CreatorTransferFail();
error DesImages__OwnerTransferFail();

/// @title DesImages
/// @author yyyk
contract DesImages is ERC2981, ERC721, Ownable, ReentrancyGuard {
    enum Status {
        FOR_SALE,
        MINTED,
        BURNED
    }

    struct TokenValue {
        Status status;
        uint128 ciphertext;
        uint32 date;
    }

    uint256 private constant INITIAL_PRICE = 0.01 ether;
    uint256 private constant LINEAR_COEFFICIENT = 0.001 ether;
    uint256 private constant RESERVE_CUT_OVER_10000 = 9950; // 99.5%
    uint96 private constant ROYALTY_OVER_10000 = 500; // 5%

    mapping(uint256 => TokenValue) private _tokenValues;

    uint256 public totalSupply;
    uint256 public totalEverMinted;
    bool public paused;

    event Paused();
    event UnPaused();

    event Minted(
        address indexed to,
        uint256 indexed tokenId,
        uint256 mintPrice,
        uint256 totalSupply,
        uint256 totalEverMinted
    );

    event Burned(
        address indexed from,
        uint256 indexed tokenId,
        uint256 burnReward,
        uint256 totalSupply
    );

    modifier whenPaused() {
        require(paused);
        _;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @notice validity of 2020-01-01~9999-12-31
    /// @param date_ uint32 0xYYYYMDD
    modifier validDate(uint32 date_) {
        uint8 day = uint8(date_ & 0xff);
        uint8 month = uint8((date_ >> 8) & 0xf);
        uint16 year = uint16((date_ >> 12) & 0xffff);
        if (
            year < 2020 ||
            year > 9999 ||
            !DateTime.isValidDate(year, month, day)
        ) {
            revert DesImages__InvalidDate();
        }
        if (DateTime.timestampFromDate(year, month, day) > block.timestamp) {
            revert DesImages__FutureDate();
        }
        _;
    }

    constructor() ERC721("desImages", "DESIMGS") {
        _setDefaultRoyalty(msg.sender, ROYALTY_OVER_10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit UnPaused();
    }

    function getTokenStatus(uint256 tokenId_) external view returns (Status) {
        return _tokenValues[tokenId_].status;
    }

    /// @notice maths is done based on linear bonding curve
    function currentMintPrice() public view returns (uint256) {
        uint256 _totalSupply = totalSupply;
        return INITIAL_PRICE + _totalSupply * LINEAR_COEFFICIENT;
    }

    /// @notice reserve cut of last mint price
    function currentBurnReward() public view returns (uint256) {
        uint256 _currentMintPrice = currentMintPrice();
        return _getReserveCut(_currentMintPrice - LINEAR_COEFFICIENT);
    }

    function _getReserveCut(uint256 mintPrice_) private pure returns (uint256) {
        return (mintPrice_ * RESERVE_CUT_OVER_10000) / 10000; // 99.5%
    }

    function _getTokenId(uint32 date_, uint128 ciphertext_)
        private
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(date_, ciphertext_)));
    }

    /// @notice base64 encoded json + base64 encoded svg for image value
    /// @param tokenId_ token id
    /// @return string base64 encoded json string
    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        require(
            ERC721._exists(tokenId_),
            "ERC721: URI query for nonexistent token"
        );

        TokenValue storage tokenValue = _tokenValues[tokenId_];
        return
            TokenURI.generateTokenURI(tokenValue.date, tokenValue.ciphertext);
    }

    /// @notice ciphertext_ can be any value as long as it's in uint128. This is intended
    ///         to allow mods with various plaintexts other than the official 'i am still alive'.
    /// @param date_ date key as 0xYYYYMDD
    /// @param ciphertext_ ciphertext as 0xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    /// @return uint256 token id
    function mint(uint32 date_, uint128 ciphertext_)
        external
        payable
        nonReentrant
        whenNotPaused
        validDate(date_)
        returns (uint256)
    {
        uint256 mintPrice = currentMintPrice();
        if (msg.value < mintPrice) {
            revert DesImages__NotEnoughETHSent();
        }
        uint256 tokenId = _getTokenId(date_, ciphertext_);
        if (_tokenValues[tokenId].status != Status.FOR_SALE) {
            revert DesImages__TokenNotForSale();
        }
        ERC721._safeMint(msg.sender, tokenId);
        _tokenValues[tokenId] = TokenValue(Status.MINTED, ciphertext_, date_);
        totalEverMinted += 1;
        totalSupply += 1;

        (bool success, ) = payable(owner()).call{
            value: mintPrice - _getReserveCut(mintPrice)
        }("");
        if (!success) {
            revert DesImages__CreatorTransferFail();
        }

        // send back ETH if more than mintPrice is sent
        if (msg.value > mintPrice) {
            (success, ) = payable(msg.sender).call{
                value: msg.value - mintPrice
            }("");
            if (!success) {
                revert DesImages__OwnerTransferFail();
            }
        }

        emit Minted(
            msg.sender,
            tokenId,
            mintPrice,
            totalSupply,
            totalEverMinted
        );

        return tokenId;
    }

    function burn(uint256 tokenId_) external nonReentrant {
        if (msg.sender != ERC721.ownerOf(tokenId_)) {
            revert DesImages__TokenNotOwned();
        }
        uint256 burnReward = currentBurnReward();
        ERC721._burn(tokenId_);
        _tokenValues[tokenId_].status = Status.BURNED;
        totalSupply -= 1;

        (bool success, ) = payable(msg.sender).call{value: burnReward}("");
        if (!success) {
            revert DesImages__OwnerTransferFail();
        }
        emit Burned(msg.sender, tokenId_, burnReward, totalSupply);
    }
}
