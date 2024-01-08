// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Base64.sol";

//    ____           _____  _             _         ____   _               _         
//   / __ \         / ____|| |           (_)       |  _ \ | |             | |        
//  | |  | | _ __  | |     | |__    __ _  _  _ __  | |_) || |  ___    ___ | | __ ___ 
//  | |  | || '_ \ | |     | '_ \  / _` || || '_ \ |  _ < | | / _ \  / __|| |/ // __|
//  | |__| || | | || |____ | | | || (_| || || | | || |_) || || (_) || (__ |   < \__ \
//   \____/ |_| |_| \_____||_| |_| \__,_||_||_| |_||____/ |_| \___/  \___||_|\_\|___/
// 

contract OnChainBlocks is ERC721, ERC721Enumerable, ERC721Burnable, Ownable  {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    
    struct BlockData  { uint color; }
    
    // data structures
    mapping(uint256 => BlockData[]) private stackData;
    mapping(uint256 => address) private owners;
    
    // mint information
    uint256 public price = 0.03 ether;
    uint256 public mintCount;
    
    // withdraw addresses
    address public t1 = 0x1D8fA2D05544cBF0b2fb58A7C1f83947AaD89dE5;
    address public t2 = 0x533A8D39231Ac2fa36c4018BFf893Ffb4878BC1b;
    address public t3 = 0x4b2Baea92cE23Ff46aD11F9a5B83e152e8Fa88d7;
    
    // supply information
    uint256 private initialSupply = 10000;
    uint256 private reservedSupply = 100;
    
    // for randomness
    bytes32 internal salt;
    
    // ROY G BIV <3
    string[] colors = [
        "red",
        "orange",
        "yellow",
        "green",
        "blue",
        "indigo",
        "violet",
        "white",
        "black"
    ];

    constructor() ERC721("OnChainBlocks", "OCB") {}
        
    modifier Secure() 
    {
        require(tx.origin == msg.sender, "No interacting from external contracts");
        _;
        salt = keccak256(abi.encodePacked(salt, block.coinbase));
    }
    
    function mintBlocks(uint256 quantity) Secure public payable
    {
        require(quantity > 0 && quantity <= 10, "You can only mint up to 10 blocks per transaction");
        require(msg.value >= price * quantity, "Payment amount invalid. Cost = Price * Quantity");
        require(_tokenIdCounter.current() + quantity <= initialSupply - reservedSupply, "Exceeds maximum supply" );
        
        for (uint256 i=0; i<quantity; i++)
        {
            uint256 colorId = random(colors.length, _tokenIdCounter.current());
        
            stackData[_tokenIdCounter.current()].push(BlockData(colorId));
            owners[_tokenIdCounter.current()] = msg.sender;
            
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            mintCount++;
        }
    }
    
    function stackBlocks(uint256[] memory blockIds) public
    {
        require(blockIds.length > 1 && blockIds.length < 8, "You must provide 2 to 7 tokenIds to stack");
        
        // Make sure the message sender owns all these blocks and that the total height is less than 8
        uint totalHeight = 0;
        for (uint index=0; index<blockIds.length; index++)
        {
            for (uint j=0; j<blockIds.length; j++) {
                if (index != j) {
                    require(blockIds[j] != blockIds[index], "No duplicates allowed!");
                }
            }
            
            require(owners[blockIds[index]] == msg.sender, "You don't own this block");
            
            totalHeight += getHeight(blockIds[index]);
        }
        
        require(totalHeight <= 7, "Cannot stack over 7 blocks tall");
        
        uint256 bottomId = blockIds[0];
        
        // Iterate through each stack being stacked on top of bottom stack
        for (uint i=1; i<blockIds.length; i++)
        {
            uint256 selectedId = blockIds[i];
            
            // Iterate through each block in the selected stack
            for (uint j=0; j<stackData[selectedId].length; j++)
            {
                // Add block to bottom stack
                stackData[bottomId].push(stackData[selectedId][j]);
            }
            
            // Burn top stack once done stacking it
            delete stackData[selectedId];
            _burn(selectedId);
        }
    }
    
    function giftBlocks(address recipient, uint256 quantity) Secure public onlyOwner
    {
        require(quantity > 0, "Quantity must be greater than zero");
        require(quantity <= reservedSupply, "Exceeds reserved supply");
        
        for (uint256 i=0; i<quantity; i++)
        {
            uint256 colorId = random(colors.length, _tokenIdCounter.current());
        
            stackData[_tokenIdCounter.current()].push(BlockData(colorId));
            owners[_tokenIdCounter.current()] = recipient;
            
            _safeMint(recipient, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
        
        reservedSupply -= quantity;
    }
    
    function generateSvg(uint256 tokenId) public view returns (string memory)
    {
        uint height = stackData[tokenId].length;

        string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 420 420" width="420" height="420" shape-rendering="crispEdges">';
        string memory currentBlockSvg = "";
        for (uint256 i=0; i<height; i++)
        {
            currentBlockSvg = string(abi.encodePacked('<svg y="-',  Utils.uint2str(i * 50), '"><rect x="120" y="360" width="180" height="60" style="fill:', colors[stackData[tokenId][i].color], '"/><rect x="290" y="360" width="10" height="60"/><rect x="140" y="350" width="20" height="10"/><rect x="180" y="350" width="20" height="10"/><rect x="220" y="350" width="20" height="10"/><rect x="260" y="350" width="20" height="10"/><rect x="280" y="360" width="20" height="10"/><rect x="240" y="360" width="20" height="10"/><rect x="200" y="360" width="20" height="10"/><rect x="160" y="360" width="20" height="10"/><rect x="120" y="360" width="20" height="10"/><rect x="120" y="360" width="10.11" height="60"/></svg>'));
            svg = string(abi.encodePacked(svg, currentBlockSvg));
        }
        svg = string(abi.encodePacked(svg, '</svg>'));
        
        return svg;
    }

    function getHeight(uint256 tokenId) public view returns (uint)
    {
        return stackData[tokenId].length;
    }
    
    function getStackString(uint id) public view returns (string memory)
    {
        string memory result = "";
        
        for (uint i=0; i<stackData[id].length; i++)
        {
            result = string(abi.encodePacked(result, Utils.uint2str(stackData[id][i].color)));
        }
        
        return result;
    }
    
    function getMultiStackString(uint[] memory ids) public view returns (string memory)
    {
        string memory result = "";
        
        for (uint i=0; i<ids.length; i++)
        {
            for (uint j=0; j<stackData[ids[i]].length; j++)
            {
                result = string(abi.encodePacked(result, Utils.uint2str(stackData[ids[i]][j].color)));
            }
        }
        
        return result;
    }
    
    function getAttributes(uint256 tokenId) public view returns (string memory)
    {
        // Keep track of each color in this block so we can add a trait for each color
        string[9] memory colorStrings;
        bool[9] memory alreadyAdded;
        uint pointer;
        for (uint i=0; i<stackData[tokenId].length; i++)
        {
            uint color = stackData[tokenId][i].color;
            
            // Check if color has already been detected
            if (alreadyAdded[color] == false)
            {
                alreadyAdded[color] = true;
                
                colorStrings[pointer] = colors[color];
                pointer++;
            }
        }
        
        // Determine color traits
        string[9] memory parts;
        parts[0] = '"attributes": [';
        for (uint j=0; j<pointer; j++)
        {
            parts[j] = string(abi.encodePacked(
            '{',
            string(abi.encodePacked('"trait_type": "', "Color", '",')),
            string(abi.encodePacked('"value": "', colorStrings[j], '"')),
            '},'
            ));
        }
        
        // Determine height trait
        string memory height = string(abi.encodePacked(
            '{',
            string(abi.encodePacked('"trait_type": "', "Height", '",')),
            string(abi.encodePacked('"value": "', Utils.uint2str(stackData[tokenId].length), '"')),
            '}'
            ));
        
        // Return attributes json text
        string memory attributeString = string(abi.encodePacked('"attributes": [', parts[0], parts[1], parts[2], parts[3], parts[4]));
        attributeString = string(abi.encodePacked(attributeString, parts[5], parts[6], parts[7], parts[8], height, ']'));
        return attributeString;
    }
    
    function tokenURI(uint256 tokenId) override public view returns (string memory) 
    {
        string memory svg = generateSvg(tokenId);
        string memory attributes = getAttributes(tokenId);
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "OnChainBlock #',
            Utils.uint2str(tokenId),
            '", "description": "100% on-chain, stackable blocks. No IPFS, no API, all images and metadata exist on the blockchain",',
            '"image_data": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '", ',
            attributes,
            '}'))));
            
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function setPrice(uint256 newPrice) public onlyOwner
    {
        price = newPrice;
    }

    function setAddresses(address[] memory _t) public onlyOwner 
    {
        t1 = _t[0];
        t2 = _t[1];
        t3 = _t[2];
    }

    function withdrawBalance(bool areYouSure) public payable onlyOwner {
        require(areYouSure == true);
        
        uint256 _onePerc = address(this).balance.div(100);
        uint256 _t1Amt = _onePerc.mul(45);
        uint256 _t2Amt = _onePerc.mul(45);
        uint256 _t3Amt = _onePerc.mul(10);

        require(payable(t1).send(_t1Amt));
        require(payable(t2).send(_t2Amt));
        require(payable(t3).send(_t3Amt));
    }

    function random(uint mod, uint256 moreSalt) view private returns (uint256) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty, salt, moreSalt)))) % mod;
    }

    // The following functions are overrides required by Solidity.
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
}

library Utils 
{
    function uint2str(uint256 _i) internal pure returns (string memory str)
    {
        if (_i == 0)
        {
            return "0";
        }
        
        uint256 j = _i;
        uint256 length;
        
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        
        str = string(bstr);
        
        return str;
    }
}