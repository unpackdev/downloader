// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ITimeNFT.sol";
contract TimeNFT is Ownable, ERC721, ERC721Enumerable, ITimeNFT  {

    using SafeERC20 for IERC20;

    /// @dev time address
    address public time;

    /// @dev token price that minter will send when claim
    uint256 public tokenPrice;

    /// @dev timebank address
    address public timebank;

    struct Metadata {
        uint16 year;
        uint8 month;
        uint8 day;
        uint256 color;
        string title;
    }

    mapping(uint256 => Metadata) id_to_date;

    string private _currentBaseURI;
    string private _currentSVGBaseURI;

    constructor(uint256 _tokenPrice, string memory _baseUri, string memory _SVGbaseUri, address _time, address _timebank) ERC721("TIMENFT", "TIMENFT") {
        require(_tokenPrice > 0, "TimeNFT: invalid token price");
        require(_timebank != address(0), "TimeNFT: invalid timebank");
        require(bytes(_baseUri).length > 0, "TimeNFT: invalid base uri");
        require(_time != address(0), "TimeNFT: invalid time");

        tokenPrice = _tokenPrice;
        time = _time;
        timebank = _timebank;

        setBaseURI(_baseUri);
        setSVGBaseURI(_SVGbaseUri);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _currentBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function setSVGBaseURI(string memory SVGbaseURI) public onlyOwner {
        _currentSVGBaseURI = SVGbaseURI;
    }

    function _SVGbaseURI() internal view virtual returns (string memory) {
        return _currentSVGBaseURI;
    }


    function mint(uint16 year, uint8 month, uint8 day, uint256 color, string memory title) internal {
        uint256 tokenId = id(year, month, day);
        
        id_to_date[tokenId] = Metadata(year, month, day, color, title);
        _safeMint(msg.sender, tokenId);
    }

    function claim(uint16 year, uint8 month, uint8 day,uint256 color, string calldata title) external {
        require(color >= 0, "color must be greater than 0");
        require(color <= 7, "there is only 7 possible colors");
        (uint16 now_year, uint8 now_month, uint8 now_day) = timestampToDate(block.timestamp);
        if ((year > now_year) || 
            (year == now_year && month > now_month) || 
            (year == now_year && month == now_month && day > now_day)) {
            revert("a date from the future can't be claimed");
        }
        uint256 cost =  tokenPrice* 10**18;

        if( color > 0 && color <= 7){
            cost = cost * color;
        }

        mint(year, month, day, color, title);
        IERC20(time).safeTransferFrom(msg.sender, timebank, cost);
    }

    function ownerOf(uint16 year, uint8 month, uint8 day) public view returns(address) {
        return ownerOf(id(year, month, day));
    }

    function id(uint16 year, uint8 month, uint8 day) pure internal returns(uint256) {
        require(1 <= day && day <= numDaysInMonth(month, year));
        return (uint256(year)-1)*372 + (uint256(month)-1)*31 + uint256(day)-1;
    }

    function get(uint256 tokenId) external view returns (uint16 year, uint8 month, uint8 day, uint256 color, string memory title) {
        require(_exists(tokenId), "token not minted");
        Metadata memory date = id_to_date[tokenId];
        year = date.year;
        month = date.month;
        day = date.day;
        color = date.color;
        title = date.title;
    }

    function titleOf(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "token not minted");
        Metadata memory date = id_to_date[tokenId];
        return date.title;
    }

    function titleOf(uint16 year, uint8 month, uint8 day) external view returns (string memory) {
        require(_exists(id(year, month, day)), "token not minted");
        Metadata memory date = id_to_date[id(year, month, day)];
        return date.title;
    }

    function changeTitleOf(uint16 year, uint8 month, uint8 day, string memory title) external {
        require(_exists(id(year, month, day)), "token not minted");
        changeTitleOf(id(year, month, day), title);
    }

    function changeTitleOf(uint256 tokenId, string memory title) public {
        require(_exists(tokenId), "token not minted");
        require(ownerOf(tokenId) == msg.sender, "only the owner of this date can change its title");
        id_to_date[tokenId].title = title;
    }

    function isLeapYear(uint16 year) public pure returns (bool) {
        require(1 <= year, "year must be bigger or equal 1");
        return (year % 4 == 0) 
            && (year % 100 == 0)
            && (year % 400 == 0);
    }

    function numDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
        require(1 <= month && month <= 12, "month must be between 1 and 12");
        require(1 <= year, "year must be bigger or equal 1");

        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        }
        else if (month == 2) {
            return isLeapYear(year) ? 29 : 28;
        }
        else {
            return 30;
        }
    }

    function timestampToDate(uint timestamp) public pure returns (uint16 year, uint8 month, uint8 day) {
        uint z = timestamp / 86400 + 719468;
        uint era = (z >= 0 ? z : z - 146096) / 146097;
        uint doe = z - era * 146097;
        uint yoe = (doe - doe/1460 + doe/36524 - doe/146096) / 365;
        uint doy = doe - (365*yoe + yoe/4 - yoe/100);
        uint mp = (5*doy + 2)/153;

        day = uint8(doy - (153*mp+2)/5 + 1);
        month = mp < 10 ? uint8(mp + 3) : uint8(mp - 9);
        year = uint16(yoe + era * 400 + (month <= 2 ? 1 : 0));
    }

    function pseudoRNG(uint16 year, uint8 month, uint8 day, string memory title) internal view returns (uint256) {
        return uint256(keccak256(abi.encode(block.timestamp, block.difficulty, year, month, day, title)));
    }

        function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

     /**
     * @dev sets time bank contract address and is callable by only contract owner
     * @param  _value new value
     */
    function setTimeBank(address _value) external onlyOwner {
        require(_value != address(0), "TimeNFT: invalid value");
        require(_value != timebank, "TimeNFT: the same value");

        timebank = _value;

        emit TimeBankUpdated(msg.sender, _value);
    }

         /**
     * @dev sets time  contract address and is callable by only contract owner
     * @param  _value new value
     */
    function setTime(address _value) external onlyOwner {
        require(_value != address(0), "tIME: invalid value");
        require(_value != time, "tIME: the same value");

        time = _value;

        emit TimeUpdated(msg.sender, _value);
    }



        /**
     * @dev sets token price and is callable by only contract owner
     * @param  _value new value
     */
    function setTokenPrice(uint256 _value) external onlyOwner {
        require(_value > 0, "TimeNFT: invalid value");
        require(_value != tokenPrice, "TimeNFT: the same value");

        tokenPrice = _value;

        emit TokenPriceUpdated(msg.sender, _value);
    }

}