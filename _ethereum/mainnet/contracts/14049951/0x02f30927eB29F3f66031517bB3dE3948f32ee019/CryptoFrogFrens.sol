// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract PIXELFROG is ERC721, ERC721Enumerable, Ownable {
    bool public mainSaleActive = false;
    bool public picsRevealed = false;

    bool public whitelistSaleActive = false;

    bool public finalized = false;

    mapping(address => uint) public whitelist;
    mapping(address => uint) public whitelist_og;
    mapping(address => uint) public claimed;
    mapping(address => uint) public claimed_og;
    mapping(uint => string) public traits;
    mapping(uint => string) public texts;
    mapping(uint => uint256) public xdone;
    mapping(uint => string) public gif;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint private constant maxTokensPerTransaction = 10;
    uint256 private tokenPrice = 90000000000000000; //0.09 ETH
    uint256 private tokenPriceWhite = 70000000000000000; //0.07 ETH
    uint256 private constant nftsNumber = 10802;

    
    constructor() ERC721("PIXELFROG", "PFRG") {
        _tokenIdCounter.increment();
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
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


    function getSuperGIF(uint256 num) public view returns (string memory) {
        uint256 index;
        index = (num >> 10) % 23;
        return string(abi.encodePacked(
                    'data:application/json;base64,', 
                    Base64.encode(bytes(string(abi.encodePacked('{"name": "Crypto Frog Frens", "description": "Crypto Frog Frens", "image": "ipfs://',gif[index],'"}'))))
                    ));
    }



    function getSuperSVG(uint256 num) public view returns (string memory) {
        uint256 index;
        string memory res;
        index = 1000 + (num >> 5) % 55;
    
        res = '<?xml version="1.0" encoding="utf-8"?> <svg id="fr" xmlns="http://www.w3.org/2000/svg"  x="0px" y="0px" width="1000px" height="1000px" xmlns:xlink="http://www.w3.org/1999/xlink">';
            res = string(abi.encodePacked(
                    res, 
                    '<image x="1" y="1" width="1000" height="1000" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGQAAABk',
                    traits[index],
                    '"/>'
                ));
        
        res =  string(abi.encodePacked(res, '<style>#fr{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>'));
    
        res = Base64.encode(bytes(res));
        string memory json = Base64.encode(
            bytes(string(abi.encodePacked(
                '{"name": "Crypto Frog Frens", "description": "Crypto Frog Frens - beautiful frogs, completely generated OnChain","attributes":', 
                '[{ "trait_type": "Super", "value": texts[index]}]', 
                ', "image": "data:image/svg+xml;base64,', 
                res, 
                '"}'
                ))));
       return string(abi.encodePacked('data:application/json;base64,', json));
       }


    function getSVG(uint256 num) public view returns (string memory) {
        uint256 i;
        uint256 chance;
        uint256 start;
        uint256 amount;
        string[7]memory tname = [
            'Body',
            'Miscellaneous',
            'Clothes',
            'Mouth',
            'Headwear',
            'Eyes',
            'Accessory'
        ];
        string[20]memory backs =[
            'e5bf1f',
            '89ccb6',
            '8f61ff',
            'cdf0f1',
            '8addda',
            'da5e66',
            'cddf6c',
            'ffe1c6',
            'ff9fd9',
            'c4bceb',
            '7ee799',
            'fd7c90',
            'e69488',
            '699392',
            '4d9186',
            'ba8ca8',
            'b2ba90',
            '008080',
            '5671f4',
            'ffae1a'
                ];


        string memory res;
        string memory traits_str;
        i=num;
        res = '<?xml version="1.0" encoding="utf-8"?> <svg id="fr" xmlns="http://www.w3.org/2000/svg"  x="0px" y="0px" width="1000px" height="1000px" xmlns:xlink="http://www.w3.org/1999/xlink">';
        res = string(abi.encodePacked(
                res, 
               '<rect x="1" y="1" width="1000" height="1000" fill="#',
                backs[(num >> 20)%20],
                '" />'
            ));

        traits_str = string(abi.encodePacked(
            '{ "trait_type": " Background", "value": "',
                texts[2000+(num >> 20)%20],
            '"}'
        ));
        
        for(i = 0; i<7;i++) {
            chance = i==0?100:(i==1?19:(i==2?100:(i==3?100:(i==4?100:(i==5?100:19)))));
            amount = i==0?17:(i==1?6:(i==2?87:(i==3?89:(i==4?115:(i==5?58:8)))));
		    if (((num >> (i*7))%100) <= chance) {
                res = string(abi.encodePacked(
                    res, 
                    '<image x="1" y="1" width="1000" height="1000" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGQAAABk',
                    traits[start + (num>>i)%amount],
                    '"/>'
                ));

                traits_str = string(abi.encodePacked(
                        traits_str,
                        ',{ "trait_type": "',
                        tname[i]
                        ,'", "value": "',
                        texts[start + (num>>i)%amount]
                        ,'"}'


                ));


            }
            start += amount;
        }
        
        res =  string(abi.encodePacked(res, '<style>#fr{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>'));
    
        res = Base64.encode(bytes(res));
        string memory json = Base64.encode(
            bytes(string(abi.encodePacked(
                '{"name": "Crypto Frog Frens", "description": "Crypto Frog Frens - beautiful frogs, completely generated OnChain","attributes":', 
                '[',traits_str,']', 
                ', "image": "data:image/svg+xml;base64,', 
                res, 
                '"}'
                ))));
       return string(abi.encodePacked('data:application/json;base64,', json));
    }
    
    
    function tokenURI(uint256 tokenId) public view override(ERC721)  returns (string memory) {
        if (!picsRevealed || (xdone[tokenId] == 0 || xdone[tokenId+10] == 0 || xdone[tokenId+20]==0)) {
                return string(abi.encodePacked(
                    'data:application/json;base64,', 
                    Base64.encode(bytes(string(abi.encodePacked('{"name": "Crypto Frog Frens", "description": "Crypto Frog Frens", "image": "ipfs://QmPg79RqdyQzfD52N67L1V4cEAvPPaeyEmT81S2pREGvk8"}'))))
                    ));
        }

        uint256 rand = (xdone[tokenId] ^ xdone[tokenId+10]) ^ xdone[tokenId+20];
        uint rarity = (rand >> 10) % 1000;
        string memory output;

        if (rarity < 2) {
            output = getSuperGIF(rand);
        } else if (rarity < 10) {
            output = getSuperSVG(rand);
        } else {
            output = getSVG(rand);
        }

       
        return output;
    }
    
    function flipWhitelistSale() public onlyOwner {
        whitelistSaleActive = !whitelistSaleActive;
    }
    
    function flipMainSale() public onlyOwner {
        mainSaleActive = !mainSaleActive;
    }
    
    function revealAll() public onlyOwner {
        picsRevealed = true;
    }

    function finalizeAll() public onlyOwner {
        finalized = true;
    }

    function setXDone(uint num) private  {
        xdone[num] = uint(keccak256(abi.encodePacked(num, block.difficulty, block.timestamp, block.coinbase)));
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function addToWhitelist(address[] memory _address, uint32[] memory _amount)public onlyOwner {
        for (uint i = 0; i < _address.length; i++) {
            whitelist[_address[i]] = _amount[i];
        }
    }

    function addToWhitelistOG(address[] memory _address, uint32[] memory _amount)public onlyOwner {
        for (uint i = 0; i < _address.length; i++) {
            whitelist_og[_address[i]] = _amount[i];
        }
    }

    function setTraits(uint32[] memory _num, string[] memory _base) public onlyOwner {
        for (uint i = 0; i < _base.length; i++) {
            traits[_num[i]] = _base[i];
        }
    }

    function setTexts(uint32[] memory _num, string[] memory _txt) public onlyOwner {
        for (uint i = 0; i < _txt.length; i++) {
            texts[_num[i]] = _txt[i];
        }
    }

    function setGifs(uint32[] memory _num, string[] memory _file) public onlyOwner {
        for (uint i = 0; i < _num.length; i++) {
            gif[_num[i]] = _file[i];
        }
    }

    function buyFrogs(uint tokensNumber) public payable {
        require(tokensNumber > 0, "Wrong amount");
        require(!finalized, "Finalized!");
        require(mainSaleActive, "Sale must be active to mint tokens");
        require(tokensNumber <= maxTokensPerTransaction, "Max tokens per transaction number exceeded");
        require(_tokenIdCounter.current() + tokensNumber <= nftsNumber, "Tokens number to mint exceeds number of public tokens");
        require(tokenPrice*tokensNumber <= msg.value, "Ether value sent is too low");
        for (uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            setXDone(_tokenIdCounter.current());
            _tokenIdCounter.increment();
        }

    }

    function buyWhite(uint tokensNumber) public payable {
        require(tokensNumber > 0, "Wrong amount");
        require(!finalized, "Finalized!");

        require(_tokenIdCounter.current() + tokensNumber <= nftsNumber, "Tokens number to mint exceeds number of public tokens");
        require(tokenPriceWhite * tokensNumber <= msg.value, "Ether value sent is too low");
        
        require(whitelistSaleActive, "Maybe later");
        require(tokensNumber <= whitelist[msg.sender], "You can't claim more than your allotment");

        for (uint i = 0; i < tokensNumber; i++) {
            require(whitelist[msg.sender] >= 1, "You don't have any more to claim");
            require(tokensNumber - i <= whitelist[msg.sender], "You can't claim more than your allotment");
            require(_tokenIdCounter.current()<= nftsNumber + 1, "Sry I dont have enough left ;(");
            claimed[msg.sender] += 1;
            whitelist[msg.sender] =whitelist[msg.sender] - 1;
            _safeMint(msg.sender, _tokenIdCounter.current());
            setXDone(_tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
        
    }

    function freeClaim(uint tokensNumber) public {
        require(tokensNumber > 0, "Wrong amount");
        require(!finalized, "Finalized!");

        require(_tokenIdCounter.current() + tokensNumber <= nftsNumber, "Tokens number to mint exceeds number of public tokens");
        
        require(whitelistSaleActive, "Maybe later");
        require(tokensNumber <= whitelist_og[msg.sender], "You can't claim more than your allotment");

        for (uint i = 0; i < tokensNumber; i++) {
            require(whitelist_og[msg.sender] >= 1, "You don't have any more to claim");
            require(tokensNumber - i <= whitelist_og[msg.sender], "You can't claim more than your allotment");
            require(_tokenIdCounter.current()<= nftsNumber + 1, "Sry I dont have enough left ;(");
            claimed_og[msg.sender] += 1;
            whitelist_og[msg.sender] =whitelist_og[msg.sender] - 1;
            _safeMint(msg.sender, _tokenIdCounter.current());
            setXDone(_tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
        
    }
   
    function mintMany(uint tokensNumber) public onlyOwner {
        require(tokensNumber > 0, "Wrong amount");
        require(!finalized, "Finalized!");

        for (uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            setXDone(_tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

        
    function directMint(address to) public onlyOwner {
        require(!finalized, "Finalized!");
        _safeMint(to, _tokenIdCounter.current());
        setXDone(_tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
}




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