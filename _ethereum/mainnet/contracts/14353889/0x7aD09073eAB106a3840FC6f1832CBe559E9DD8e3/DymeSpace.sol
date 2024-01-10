// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./DymeSpaceUtils.sol";


/**
 * @title  Official DymeSpace contract
 * @author The DymeSpace crew
 * @notice The DymeSpace contract implements dynamic NFTs where a token URI is mutable and
 *         the date information is embedded in the token ID
 * @dev    The date information of a day is embedded in the token ID, so that each token
 *         represents a unique day without having to rely on the token URI.
 *         A date is encoded in the token ID with the following equation:
 *            year * 100000 + month * 1000 + day * 10 + era (0 for Before the Common Era (BCE) or 1 for Common Era (CE))
 *         For example, the release day of the Bitcoin white paper October 31, 2008
 *         would be converted into the token ID 200810311
 */
contract DymeSpace is ERC721Enumerable, ERC2981, Ownable {
    /**
     * @dev   Emitted when a token URI is updated
     * @param tokenId - the ID of the updated token
     * @param setter - the account that updated the token URI
     * @param uri - the new token URI
     */
    event TokenURIUpdate(uint256 indexed tokenId, address indexed setter, string uri);


    uint256 private _tokenPrice =    10000000000000000; // 0.01 ETH
    uint256 private _uriPriceLimit = 1000000000000000; // 0.001 ETH
    uint96 private _royaltyPercentage = 500; // 5.00%

    mapping(uint256 => string) private _customTokenURI;


    constructor() ERC721("DymeSpace", "DAY") {
        _setDefaultRoyalty(owner(), _royaltyPercentage);
    }


    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    /**
     * @notice Returns the token price in WEI
     * @return the token price
     */
    function tokenPrice() public view returns (uint256) {
        return _tokenPrice;
    }


    /**
     * @notice Returns the URI price limit in WEI
     * @dev    The URI price limit is the maximum amount
     *         that can be charged to update the token URI
     * @return the URI price limit
     */
    function uriPriceLimit() public view returns (uint256) {
        return _uriPriceLimit;
    }


    /**
     * @notice Withdraws the funds to an address
     * @dev    Only the contract owner is able to withdraw funds
     * @param  receiver - the receiver address
     * @param  amount - the amount in wei
     */
    function withdraw(address payable receiver, uint256 amount) public onlyOwner {
        Address.sendValue(receiver, amount);
    }


    /**
     * @notice Mints a new DAY token
     * @param  owner - the new token owner address
     * @param  date - the date of the to be minted DAY token
     */
    function mint(address owner, DymeSpaceUtils.Date memory date) public payable {
        require(msg.value == _tokenPrice, "DymeSpace: sent Ether mismatch token price");

        uint256 tokenId = DymeSpaceUtils.calcTokenId(date.era, date.year, date.month, date.day);
        require(DymeSpaceUtils.isTokenId(tokenId), "DymeSpace: invalid date");

        _safeMint(owner, tokenId);
    }


    /**
     * @notice Returns the token IDs of the first and last valid date
     * @return an array with the very first and the very last valid token ID
     */
    function tokenRange() public pure returns (uint256, uint256) {
        return (
            1380000000001010, // 1st january of year 13800000000 BCE (Big Bang)
            1380000000012311 // 31st december of year 13800000000 CE
        );
    }


    /**
     * @notice Updates the token URI of a DAY token
     * @param  tokenId - the token ID of the to be updated DAY token
     * @param  uri - the new token URI
     */
    function setTokenURI(uint256 tokenId, string memory uri) public payable {
        require(msg.value <= _uriPriceLimit, "DymeSpace: sent Ether greater URI price limit");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "DymeSpace: not permitted");

        _customTokenURI[tokenId] = uri;
        emit TokenURIUpdate(tokenId, msg.sender, uri);
    }


    /**
     * @notice Returns the token URI of a DAY token
     * @dev    If no token URI is set, a default NFT image, conforming to the OpenSea metadata standard,
     *         is returned. See (https://docs.opensea.io/docs/metadata-standards)
     * @param  tokenId - the token ID of the DAY token
     * @return the token URI of the given token ID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "DymeSpace: operator query for nonexistent token");
        return bytes(_customTokenURI[tokenId]).length == 0 ? _defaultTokenURI(tokenId) : _customTokenURI[tokenId];
    }

    function _defaultTokenURI(uint256 tokenId) private pure returns (string memory) {
        DymeSpaceUtils.Date memory date = DymeSpaceUtils.tokenIdToDate(tokenId);

        bytes memory image = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 750">'
                '<style><![CDATA[.A{isolation:isolate}.C{mix-blend-mode:lighten}.D{mix-blend-mode:color-burn}.G{letter-spacing:3px}]]></style>'
                '<defs><radialGradient id="A" cx="15.33" cy="22.1" r="1327.72" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#2e004c"/><stop offset=".13" stop-color="#2c0250"/><stop offset=".27" stop-color="#26095e"/><stop offset=".42" stop-color="#1d1474"/><stop offset=".52" stop-color="#141e88"/><stop offset=".65" stop-color="#211882"/><stop offset=".88" stop-color="#420973"/><stop offset="1" stop-color="#57006a"/></radialGradient><radialGradient id="B" cx="729.79" cy="715.13" r="1123.35" gradientUnits="userSpaceOnUse"><stop offset=".17" stop-color="#fda291"/><stop offset=".23" stop-color="#f39c91" stop-opacity=".96"/><stop offset=".33" stop-color="#d98d91" stop-opacity=".86"/><stop offset=".46" stop-color="#af7492" stop-opacity=".69"/><stop offset=".61" stop-color="#745293" stop-opacity=".46"/><stop offset=".78" stop-color="#2a2693" stop-opacity=".17"/><stop offset=".87" stop-color="#000d94" stop-opacity="0"/></radialGradient><radialGradient id="C" cx="672.71" cy="24.79" fx="391.918" fy="91.935" r="800.57" gradientTransform="translate(0)" gradientUnits="userSpaceOnUse"><stop offset=".27" stop-color="#f07698"/><stop offset=".32" stop-color="#e9729a" stop-opacity=".97"/><stop offset=".41" stop-color="#d7689f" stop-opacity=".88"/><stop offset=".52" stop-color="#b958a7" stop-opacity=".74"/><stop offset=".64" stop-color="#8f41b3" stop-opacity=".55"/><stop offset=".77" stop-color="#5a23c2" stop-opacity=".3"/><stop offset=".91" stop-color="#1b00d4" stop-opacity="0"/></radialGradient></defs>'
                '<g class="A"><g><g><path d="M0,0H750V750H0Z" fill="url(#A)"/><path class="C" d="M0,0H750V750H0Z" fill="url(#B)"/><path class="D" d="M750 0v750H0V0" fill="url(#C)"/><path d="M430,354.71v-10h20v-10h10v-10h10v-10h10v-10h10v-10h10v-20h10v-70H500v-10H490v-10H480v-10H460v-10H440v-10H310v10H290v10H270v10H260v10H250v10H240v70h10v20h10v10h10v10h10v10h10v10h10v10h20v10h10v20H320v10H300v10H290v10H280v10H270v10H260v10H250v20H240v70h10v10h10v10h10v10h20v10h20v10H440v-10h20v-10h20v-10h10v-10h10v-10h10v-70H500v-20H490v-10H480v-10H470v-10H460v-10H450v-10H430v-10H420v-20Zm-29.93-120.1h40v-10h30v-10h19.86v-10h10v10h-10v10H470.07v10h-30v10h-40Zm-110.07,0H280v-10H260.14v-10h-10v-10h10v10H280v10h30v10h40v10h50v10H350v-10H310v-10H290ZM390.85,464.84v9.87H400v10h30v10h20v10h30v20H460v10H440v10H410v10H340v-10H310v-10H290v-10H270v-20h30v-10h20v-10h30v-10h10.85v-9.87h10V345.73h-10v-20h-20v-10h-10v-10h-10v-10h-10v-10h-10v-10h20v10h30v10h50v-10h30v-10h20v10h-10v10h-10v10h-10v10h-10v10h-20v20h-10V464.84Z" fill="#fff"/></g></g></g>'
                '<text x="50%" y="12%" class="G" fill="#fff" font-weight="bold" font-family="monospace" text-anchor="middle" font-size="70">',
                    Strings.toString(date.day), '. ', _monthToString(date.month),
                '</text><text x="50%" y="92%" class="G" fill="#fff" font-weight="bold" font-family="monospace" text-anchor="middle" font-size="70">',
                    Strings.toString(date.year), ' ', date.era == DymeSpaceUtils.Era.BCE ? "BCE" : "CE",
                '</text>'
            '</svg>'
        );

        string memory json = Base64.encode(abi.encodePacked(
            '{'
                '"name":' '"', _dateToName(date), '",',
                '"description":' '"This dynamic NFT represents a unique day on the blockchain with its content being customizable by the owner. Check out dyme.space",'
                '"image":' '"data:image/svg+xml;base64,', Base64.encode(image), '",'
                '"external_url":' '"https://dyme.space/?tokenId=', Strings.toString(tokenId), '"'
            '}'
        ));

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _monthToString(uint256 month) private pure returns (string memory) {
        return month == 1 ? "Jan" : month == 2 ? "Feb" : month == 3 ? "Mar" :
               month == 4 ? "Apr" : month == 5 ? "May" : month == 6 ? "Jun" :
               month == 7 ? "Jul" : month == 8 ? "Aug" : month == 9 ? "Sep" :
               month == 10 ? "Oct" : month == 11 ? "Nov" : "Dec";
    }

    function _dateToName(DymeSpaceUtils.Date memory date) private pure returns (string memory) {
        return string(abi.encodePacked(
            'DAY #', 
            Strings.toString(date.year),
            '-',
            date.month < 10 ? '0' : '', Strings.toString(date.month),
            '-',
            date.day < 10 ? '0' : '', Strings.toString(date.day),
            '-',
            Strings.toString(uint256(date.era))
        ));
    } 


    /**
     * @notice Returns the default token URI of a DAY token
     * @dev    An NFT image, conforming to the OpenSea metadata standard,
     *         is returned. See (https://docs.opensea.io/docs/metadata-standards)
     * @param  tokenId - the token ID of the DAY token
     * @return the default token URI of the given token ID
     */
    function defaultTokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "DymeSpace: operator query for nonexistent token");
        return _defaultTokenURI(tokenId);
    }


    /**
     * @notice Returns the token IDs of DAY tokens within the given year
     * @param  era - the era (0 = BCE, 1 = CE)
     * @param  year - the year (0 < year < 13800000000)
     * @return an array with the token IDs
     */
    function tokensInYear(DymeSpaceUtils.Era era, uint256 year) public view returns (uint256[] memory) {
        require(DymeSpaceUtils.isEra(era), "DymeSpace: invalid era");
        require(DymeSpaceUtils.isYear(year), "DymeSpace: invalid year");

        uint256[] memory tokenIds = new uint256[](DymeSpaceUtils.isLeapYear(year) ? 366 : 365);
        uint256 index = 0;

        for (uint256 month = 1; month <= 12; month++) {
            for (uint256 day = 1; day <= DymeSpaceUtils.daysInMonth(month, year); day++) {
                uint256 tokenId = DymeSpaceUtils.calcTokenId(era, year, month, day);
                if (_exists(tokenId)) {
                    tokenIds[index] = tokenId;
                }
                index++;
            }
        }

        return tokenIds;
    }


    /**
     * @notice Returns the token IDs of DAY tokens owned by the given address
     * @param  owner - the owner address
     * @return an array with the token IDs
     */
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 numOfTokenIds = this.balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](numOfTokenIds);

        for (uint256 index = 0; index < numOfTokenIds; index++) {
            tokenIds[index] = this.tokenOfOwnerByIndex(owner, index);
        }

        return tokenIds;
    }
}
