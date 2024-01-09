// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./base64.sol";

contract CoolDatesClub is Ownable, ERC721Enumerable, ReentrancyGuard {    
        
    struct MetaData {
        string title;
        string subtitle;
        uint24 date;
        uint32 [6] colors;
    }

    string private _imgTemplate;
    string private _contractURI;
    uint256 public limitPerWallet = type(uint128).max;
    uint8 public maximumNameLength = 32;
    uint256 public minimumPrice = 0.01 ether;    
    uint256 public nextTokenId = 1;    
    
    mapping(uint256 => MetaData) private _tokenId_to_data;  
    mapping(uint24 => uint256) private _date_to_tokenId;          

    event Minted(address indexed sender, address indexed recipient, uint tokenId, uint24 tokenDate);    

    constructor(string memory imgTemplate_, string memory contractURI_) ERC721("CoolDatesClub", "CDC") {
        _imgTemplate = imgTemplate_;
        _contractURI = contractURI_;        
    }

    function setLimitPerWallet(uint256 limit_per_wallet_) external onlyOwner returns (bool) {
        limitPerWallet = limit_per_wallet_;
        return true;
    }

    function setMinimumPrice(uint256 price_) external onlyOwner returns (bool) {
        minimumPrice = price_;        
        return true;
    }

    function setMaximumNameLength(uint8 length_) external onlyOwner returns (bool) {
        maximumNameLength = length_;
        return true;
    }

    function setContractURI(string memory data_) external onlyOwner returns (bool) {
        _contractURI = data_;
        return true;
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function withdraw(address payable _to) external payable onlyOwner returns (bool) {
        (bool sent, ) = _to.call{value: msg.value}("");
        require(sent, "WITHDRAWAL_FAILED");
        return true;
    }

    function withdraw() external onlyOwner returns (bool) {        
        return payable(msg.sender).send(address(this).balance);
    }
    
    function _dateToUint24(uint8 day_, uint8 month_, uint16 year_) internal pure returns (uint24) {            
        return ((uint24(year_) & 0x7FFF) << 9) + ((uint24(month_) & 0xF) << 5) + (uint24(day_) & 0x1F);
    }
    
    function _uint24ToDate(uint24 date_) internal pure returns (uint8, uint8, uint16) {        
        return (uint8(date_ & 0x1F), uint8((date_ >>= 5) & 0xF), uint16((date_ >>= 4) & 0x7FFF));
    }

    function _uint32ToColor(uint32 i_) internal pure returns (string memory) {
        bytes memory h = "0123456789abcdef";
        bytes memory o = new bytes(8);        
        uint k = 8;
        do {                        
            o[--k] = bytes1(h[uint8(i_ & 0x00000f)]);            
            i_ >>= 4;
        } while (k > 0);
        return string(o);
    }

    function setImageTemplate(string memory template_) external onlyOwner returns (bool) {
        _imgTemplate = template_;
        return true;
    }

    function setTitlesAndColors(uint8 day_, uint8 month_, uint16 year_, string memory title_, string memory subtitle_, uint32[6] memory colors_) external nonReentrant returns (bool) {
        uint24 tokenDate = _dateToUint24(day_, month_, year_);
        uint256 tokenId = _date_to_tokenId[tokenDate];
        require(_exists(tokenId), "NONEXISTENT_TOKEN");  
        require(ownerOf(tokenId) == msg.sender, "NOT_OWNER");
        require(bytes(title_).length <= maximumNameLength, "INVALID_TITLE");                
        require(bytes(subtitle_).length <= maximumNameLength, "INVALID_SUBTITLE");                
        _tokenId_to_data[tokenId].title = title_;
        _tokenId_to_data[tokenId].subtitle = subtitle_;
        _tokenId_to_data[tokenId].colors = colors_;
        return true;
    }

    function setTitles(uint8 day_, uint8 month_, uint16 year_, string memory title_, string memory subtitle_) external nonReentrant returns (bool) {
        uint24 tokenDate = _dateToUint24(day_, month_, year_);
        uint256 tokenId = _date_to_tokenId[tokenDate];
        require(_exists(tokenId), "NONEXISTENT_TOKEN");  
        require(ownerOf(tokenId) == msg.sender, "NOT_OWNER");
        require(bytes(title_).length <= maximumNameLength, "INVALID_TITLE");                
        require(bytes(subtitle_).length <= maximumNameLength, "INVALID_SUBTITLE");                
        _tokenId_to_data[tokenId].title = title_;
        _tokenId_to_data[tokenId].subtitle = subtitle_;
        return true;
    }

    function titles(uint8 day_, uint8 month_, uint16 year_) external view returns (string memory, string memory) {
        uint24 tokenDate = _dateToUint24(day_, month_, year_);
        uint256 tokenId = _date_to_tokenId[tokenDate];
        require(_exists(tokenId), "NONEXISTENT_TOKEN");        
        return (_tokenId_to_data[tokenId].title, _tokenId_to_data[tokenId].subtitle);
    }
    
    function dateToTokenId(uint8 day_, uint8 month_, uint16 year_) external view returns (uint256) {
        uint24 tokenDate = _dateToUint24(day_, month_, year_);
        return _date_to_tokenId[tokenDate];
    }

    function date(uint256 tokenId_) external view returns (uint8, uint8, uint16) {
        require(_exists(tokenId_), "NONEXISTENT_TOKEN");        
        return _uint24ToDate(_tokenId_to_data[tokenId_].date);
    }

    function tokenData(uint256 tokenId_) external view returns (string memory, string memory, uint24, uint32[6] memory) {
        require(_exists(tokenId_), "NONEXISTENT_TOKEN");               
        MetaData memory td = _tokenId_to_data[tokenId_];
        return (td.title, td.subtitle, td.date, td.colors);
    }

    function airDrop(
        address[] memory recipients_,
        uint8[] memory days_, 
        uint8[] memory months_, 
        uint16[] memory years_, 
        string[] memory titles_, 
        string[] memory subtitles_, 
        uint32[6][] memory colors_
        ) external onlyOwner returns (bool) {        
        for (uint i = 0; i < recipients_.length; i++)
            __mint(recipients_[i], days_[i], months_[i], years_[i], titles_[i], subtitles_[i], colors_[i]);
        return true;
    }

    function mintMulti(
        address[] memory recipients_,
        uint8[] memory days_, 
        uint8[] memory months_, 
        uint16[] memory years_, 
        string[] memory titles_, 
        string[] memory subtitles_, 
        uint32[6][] memory colors_
        ) external payable nonReentrant returns (bool) {
        require(msg.value >= minimumPrice * recipients_.length, "NOT_ENOUGH_ETHER");
        for (uint i = 0; i < recipients_.length; i++) {
            require(balanceOf(recipients_[i]) < limitPerWallet, "WALLET_LIMIT_REACHED");
            __mint(recipients_[i], days_[i], months_[i], years_[i], titles_[i], subtitles_[i], colors_[i]);
        }
        return true;
    }

    function mint(
        address recipient_, 
        uint8 day_, 
        uint8 month_, 
        uint16 year_, 
        string memory title_, 
        string memory subtitle_, 
        uint32[6] memory colors_
        ) external payable nonReentrant returns (uint256) {  
        /* colors: header, body, text, day, month, year*/        
        require(msg.value >= minimumPrice, "NOT_ENOUGH_ETHER");
        require(balanceOf(recipient_) < limitPerWallet, "WALLET_LIMIT_REACHED");
        return __mint(recipient_, day_, month_, year_, title_, subtitle_, colors_);
    }

    function __mint(
        address recipient_, 
        uint8 day_, 
        uint8 month_, 
        uint16 year_, 
        string memory title_, 
        string memory subtitle_,          
        uint32[6] memory colors_
        ) internal returns (uint256) {                  
        require(day_ <= 31 && day_ > 0, "INVALID_DAY");
        require(month_ <= 12 && month_ >= 1, "INVALID_MONTH");
        require(bytes(title_).length <= maximumNameLength, "INVALID_TITLE");                
        require(bytes(subtitle_).length <= maximumNameLength, "INVALID_SUBTITLE");                        
        uint24 tokenDate = uint24(_dateToUint24(day_, month_, year_));
        require(_date_to_tokenId[tokenDate] == 0, "DATE_ALREADY_EXISTS");        
        uint256 newTokenId = nextTokenId;        
        _mint(recipient_, newTokenId);        
        nextTokenId += 1;
        _date_to_tokenId[tokenDate] = newTokenId;        
        _tokenId_to_data[newTokenId] = MetaData({
            title: title_,
            subtitle: subtitle_,
            date: tokenDate,
            colors: colors_
        });
        emit Minted(msg.sender, recipient_, newTokenId, tokenDate);
        return newTokenId;        
    }    
    
    function _monthString(uint8 month_) internal pure returns (string memory) {
        string[12] memory m = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
        return m[month_];
    }

    function _substring(bytes memory str_, uint16 startIndex_, uint16 endIndex_) internal pure returns (bytes memory) {        
        bytes memory result = new bytes(endIndex_-startIndex_);
        for(uint i = startIndex_; i < endIndex_; i++)
            result[i-startIndex_] = str_[i];
        return result;
    }    

    function _replaceString(bytes memory orig_, bytes memory rep_, string memory with_, bool repeat_) internal pure returns (bytes memory) {        
        uint16 origLen = uint16(orig_.length);
        for(uint16 i = 0; i < origLen - 3; i++)
            if (orig_[i] == rep_[0] && orig_[i+1] == rep_[1] && orig_[i+2] == rep_[2]) {
                bytes memory tmp = abi.encodePacked(_substring(orig_, 0, i), with_, _substring(orig_, i+3, origLen));
                return repeat_ ? _replaceString(tmp, rep_, with_, repeat_): tmp;
            }
        return orig_;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {            
            require(_exists(tokenId_), "NONEXISTENT_TOKEN");  
            (uint8 day, uint8 month, uint16 year) = _uint24ToDate(_tokenId_to_data[tokenId_].date);            
            MetaData memory data = _tokenId_to_data[tokenId_];  
            string memory day_string = Strings.toString(day);
            string memory month_string = _monthString(month-1);            
            string memory year_string = year == 0x7FFF ? "" : Strings.toString(year);
            bytes memory svg = bytes(_imgTemplate);        
            svg = _replaceString(svg,"{0}",_uint32ToColor(data.colors[0]), false);
            svg = _replaceString(svg,"{1}",_uint32ToColor(data.colors[1]), false);
            svg = _replaceString(svg,"{2}",_uint32ToColor(data.colors[2]), false);
            svg = _replaceString(svg,"{3}",_uint32ToColor(data.colors[3]), true);
            svg = _replaceString(svg,"{4}",_uint32ToColor(data.colors[4]), false);
            svg = _replaceString(svg,"{5}",_uint32ToColor(data.colors[5]), true);            
            svg = _replaceString(svg,"{D}",day_string, false);            
            svg = _replaceString(svg,"{M}",month_string, false);
            svg = _replaceString(svg,"{Y}",year_string, false);
            svg = _replaceString(svg,"{T}",data.title, false);            
            svg = _replaceString(svg,"{S}",data.subtitle, false);                        
            string memory token_id_str = Strings.toString(tokenId_);            
            string memory image = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(abi.encodePacked(svg))));
            string memory name = string(abi.encodePacked("Date: ", day_string, " ", month_string, " ", year_string));            
            string memory description = string(abi.encodePacked(data.title, " ", data.subtitle, " - Token #", token_id_str));
            string memory metadata = string(abi.encodePacked('{"name":"',name,'","description":"', description, '","image_data":"', image, '"}'));
            return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadata))));
        }

}
