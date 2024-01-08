// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.2;

// @title: BoundlessGenesis
// @author: NFTeez_Nutz
//
// Tokens which allow users to write arbitray text to the chain.
// Tokens are 1 time use, after which they become a reciept of the written text.

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

contract BoundlessGenesis is 
    ERC721,
    ERC2981ContractWideRoyalties,
    Ownable {

    // Structure of onchain data
    struct chainData {
        address author; // Address of the caller of writePage()
        uint256 date; // Unix time, default UTC
        string text; // User input text
        uint256 prevId; // Optional reference to another token ID
    }

    // Structure for storing datetime data (used for destructuring assignment)
    struct datetimeStruct {
        uint year;
        uint month;
        uint day;
        uint hour;
        uint minute;
        uint second;
        
        string syear;
        string smonth;
        string sday;
        string shour;
        string sminute;
        string ssecond;
    }

    address payable private _owner;
    mapping (uint256 => chainData) private data;
    mapping (uint256 => bool) private written;
    uint256 public tokenCounter;
    uint256 public constant maxSupply = 5000; // Genesis set
    uint256 private newItemId;
    bool public enabled;

    constructor () public ERC721 ("BoundlessGenesis", "JIP6") {
        tokenCounter = 1;
        setRoyalties(address(this), 750);
        enabled = true;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981ContractWideRoyalties)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981ContractWideRoyalties.supportsInterface(interfaceId);
    }

    // Only useful for platforms that support EIP-2981
    function setRoyalties(address recipient, uint256 value) public onlyOwner{
        _setRoyalties(recipient, value);
    }

    function mint(uint56 mints) public payable returns (uint256[] memory) {
        require(enabled, "Contract not enabled");
        require(mints > 0, "Must mint >0");
        require(mints <= 5, "Max mint 5 at a time");
        require(tokenCounter-1 <= maxSupply, "SOLD OUT");
        require(tokenCounter-1 + mints <= maxSupply, "Mints > remaining supply");

        uint256 price = mints * 0.01 ether;
        if (msg.sender != owner()) {  
            require(msg.value == price, "0.01 per mint");
        }
        uint256[] memory newItemIds = new uint256[](mints);
        for (uint256 i = 0; i < mints; i++) {
            newItemId = tokenCounter;
            written[newItemId] = false;
            _safeMint(msg.sender, newItemId);
            tokenCounter += 1;
            newItemIds[i] = newItemId;
        }
        return newItemIds;
    }

    // Public mint, token sent to caller after transaction completes
    function mint() public payable returns (uint256[] memory) {
        return mint(1);
    }

    // Writes input text onto the chain
    function writePage(uint256 tokenId, string memory text) public returns (uint256) {
        return writePage(tokenId, 0, text);
    }

    // Writes input text onto the chain with a reference to a previous message
    function writePage(uint256 tokenId, uint256 prevId, string memory text) public returns (uint256) { // TODO: TEST
        require(enabled, "Contract not enabled");
        require(ownerOf(tokenId) == msg.sender, "NOT OWNER");
        require(!written[tokenId], "Message already written!");
        chainData storage newData = data[tokenId];
        newData.prevId = prevId;
        newData.author = msg.sender;
        newData.date = block.timestamp;
        newData.text = text;
        written[tokenId] = true;
        return tokenId;
    }

    // Pull data written to chain
    function getData(uint256 tokenId) public view returns (uint256, address, uint256, string memory) {
        require(tokenId <= tokenCounter, "Token doesnt exist");
        require(written[tokenId], "Message not yet written!");
        string memory text = data[tokenId].text;
        return (
            data[tokenId].prevId,
            data[tokenId].author,
            data[tokenId].date,
            text
        );
    }

    // Pull just the text that was written to chain
    function getPrevId(uint256 tokenId) public view returns (uint256) {
        (uint256 prevId, address author, uint256 date, string memory text) = getData(tokenId);
        return(prevId);
    }

    // Pull just the text that was written to chain
    function getAuthor(uint256 tokenId) public view returns (address) {
        (uint256 prevId, address author, uint256 date, string memory text) = getData(tokenId);
        return(author);
    }

    // Pull just the text that was written to chain
    function getDate(uint256 tokenId) public view returns (uint256) {
        (uint256 prevId, address author, uint256 date, string memory text) = getData(tokenId);
        return(date);
    }

    // Pull just the text that was written to chain
    function getText(uint256 tokenId) public view returns (string memory) {
        (uint256 prevId, address author, uint256 date, string memory text) = getData(tokenId);
        return(text);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        // Generate an image by default
        return generateMetadata(tokenId, true);
    }

    // Called in tokenURI
    function generateMetadata(uint256 tokenId, bool image) public view returns (string memory) {
        if (!written[tokenId]) {
            return string("[]");
        }
        string memory author = toString(abi.encodePacked(data[tokenId].author));
        string memory date = uint2str(data[tokenId].date);
        string memory text = data[tokenId].text;
        string memory id = uint2str(tokenId);
        if (!image) {
            string memory metadata = string(abi.encodePacked(fname,id,fauthor,author,fdate,date,ftext,text,fend));
            return string(abi.encodePacked(start,Base64.encode(bytes(string(abi.encodePacked(metadata))))));
        }
        
        datetimeStruct memory dt;
        (dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(data[tokenId].date);
        datetimeStructStrings(dt);
        string memory max = string(abi.encodePacked("/",uint2str(maxSupply)));
        string memory time = string(abi.encodePacked(dt.shour,":",dt.sminute));
        string memory mdy = string(abi.encodePacked(dt.smonth,"/",dt.sday,"/",dt.syear));
        string memory datetime = string(abi.encodePacked(time," ",mdy));
        string memory metadata = string(abi.encodePacked(fname,id,fauthor,author,fdate,date,ftext,text,svgstart));
        string memory svg_string = string(abi.encodePacked(svgformat,text,svgid,id,max,svgdate,datetime,svgend));
        string memory svg = string(svg_string);
        return string(abi.encodePacked(start,Base64.encode(bytes(string(abi.encodePacked(metadata,Base64.encode(bytes(svg)),'\"}'))))));
    }

    function withdrawTo(address _address) public payable onlyOwner {
        require(payable(_address).send(address(this).balance), "Withdraw error");
    }
    function withdraw() public payable onlyOwner {
        withdrawTo(msg.sender);
    }

    function setEnabled(bool _enabled) public onlyOwner {
        enabled = _enabled;
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    // Convert uint times to string, pad as needed
    function datetimeStructStrings(datetimeStruct memory dts) internal view {
        dts.syear = uint2str(dts.year);
        dts.smonth = uint2str(dts.month);
        dts.sday = uint2str(dts.day);
        dts.shour = dts.hour == 0 ?  "00" : uint2str(dts.hour);
        dts.sminute = dts.minute == 0 ?  "00" : uint2str(dts.minute);
        dts.ssecond = uint2str(dts.second);
    }

    // Convert uint to string
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    string private start='data:application/json;base64,';
    string private fname='{\"name\": \"Boundless #';
    string private fauthor='\", \"attributes\": [{\"trait_type\": \"author\",\"value\": \"';
    string private fdate='\"},{\"display_type\": \"date\",\"trait_type\": \"date written\",\"value\": \"';
    string private ftext='\"},{\"trait_type\": \"text\",\"value\": \"';
    string private fend='\"}]}';
    
    string private svgstart = '\"}],\"image\": \"data:image/svg+xml;base64,';
    string private svgformat ='<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>p { color: white; font-family: serif; font-size: 14px; line-height: 2; }text { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><foreignObject x="10" y="0" width="330" height="288"><p xmlns="http://www.w3.org/1999/xhtml">';
    string private svgid = '</p></foreignObject><text x="340" y="320" class="base" text-anchor="end">ID# ';
    string private svgdate = '</text><text x="340" y="340" class="base" text-anchor="end">';
    string private svgend = '</text></svg>';
}