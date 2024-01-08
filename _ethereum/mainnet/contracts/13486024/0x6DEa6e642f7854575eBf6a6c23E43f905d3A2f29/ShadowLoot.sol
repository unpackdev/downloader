// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC721URIStorage.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ILoot.sol";
import "./ShadowLib.sol";


contract ShadowLoot is ERC721URIStorage, ReentrancyGuard, Ownable {

    bool public activeStatus = false;
    bool public isPub = false;

    uint256 public privPrice = 0.008e18; 
    uint256 public pubPrice = 0.015e18; 
    uint256 constant public size = 50;
    
    ILoot public lootContract;
    
    event Withdraw(address withdrawer, uint256 _value);
    event PublicSaleStart(uint timestamp);
    event SaleStatusChange(bool newStatus);

    constructor(address lootAddress) ERC721("ShadowLoot", "SHL") {
        lootContract = ILoot(lootAddress);
    }

    function startPublicSale() external onlyOwner {
        isPub = true;
        emit PublicSaleStart(block.timestamp);
    }

    function flipSaleState() external onlyOwner {
        activeStatus = !activeStatus;
        emit SaleStatusChange(activeStatus);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit Withdraw(msg.sender, balance);
    }

    function mintPrivate(uint256 lootID) external payable nonReentrant {
        require(activeStatus, "Sale is not active.");
        require(!isPub, "Private sale is over.");
        require(msg.value >= privPrice, "Eth value too less.");
        require(msg.sender == lootContract.ownerOf(lootID), "Only loot holder can take part in private sale.");

        _safeMint(msg.sender, lootID);
    }

    function mintPublic(uint256 lootID) external payable nonReentrant {
        require(activeStatus, "Sale is not active.");
        require(isPub, "Public sale has not started yet.");
        require(msg.value >= pubPrice, "Eth value too less.");

        _safeMint(msg.sender, lootID);
    }

    function getCoordinates(uint256 lootID) internal view returns (uint8[] memory) {
        uint8[] memory values = new uint8[](16);
        uint num = 0;
        num = (Converter.stringToUint(lootContract.getWeapon(lootID))) % (size*size);
        values[0] = uint8(num/size);
        values[1] = uint8(num%size);

        num = (Converter.stringToUint(lootContract.getChest(lootID))) % (size*size) ;
        values[2] = uint8(num/size);
        values[3] = uint8(num%size);
        
        num = (Converter.stringToUint(lootContract.getHead(lootID))) % (size*size);
        values[4] = uint8(num/size);
        values[5] = uint8(num%size);

        num = (Converter.stringToUint(lootContract.getWaist(lootID))) % (size*size);
        values[6] = uint8(num/size);
        values[7] = uint8(num%size);

        num = (Converter.stringToUint(lootContract.getFoot(lootID))) % (size*size);
        values[8] = uint8(num/size);
        values[9] = uint8(num%size);

        num = (Converter.stringToUint(lootContract.getHand(lootID))) % (size*size);
        values[10] = uint8(num/size);
        values[11] = uint8(num%size);

        num = (Converter.stringToUint(lootContract.getNeck(lootID))) % (size*size);
        values[12] = uint8(num/size);
        values[13] = uint8(num%size);

        num = (Converter.stringToUint(lootContract.getRing(lootID))) % (size*size);
        values[14] = uint8(num/size);
        values[15] = uint8(num%size);

        return values;
    }

    function tokenURI(uint256 lootID) public override view returns (string memory) {
        string[41] memory parts;
        uint8[] memory coords = getCoordinates(lootID);

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 50 50" style="border:10px solid Whiteresmoke;background-color:Whitesmoke">';

        for(uint i=0; i<8; i++) {
            parts[(5*i)+1] = '<circle cx="';
            parts[(5*i)+2] = Converter.uintToString(coords[2*i]); 
            parts[(5*i)+3] = '.5" cy="';
            parts[(5*i)+4] = Converter.uintToString(coords[(2*i)+1]);
            if (i!=7)
                parts[(5*i)+5] = '.5" r="0.5" fill="black" />';
            else
                parts[(5*i)+5] = '.5" r="0.5" fill="black" /> </svg>';
        }

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
        );
        output = string(
            abi.encodePacked(output,parts[9],parts[10],parts[11],parts[12],parts[13],parts[14],parts[15],parts[16])
        );
        output = string(
            abi.encodePacked(output,parts[17],parts[18],parts[19],parts[20],parts[21],parts[22],parts[23],parts[24])
        );
        output = string(
            abi.encodePacked(output,parts[25],parts[26],parts[27],parts[28],parts[29],parts[30],parts[31],parts[32])
        );
        output = string(
            abi.encodePacked(output,parts[33],parts[34],parts[35],parts[36],parts[37],parts[38],parts[39],parts[40])
        );
        
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(output));

        string memory imageURI = string(abi.encodePacked(baseURL, svgBase64Encoded)); 

        string memory json = Base64.encode(
            bytes(
                abi.encodePacked(
                    '{"name":"Shadow Loot #',
                    Converter.uintToString(lootID),  
                    '","description": "ShadowLoot is a 8k generative collection from the metadata of the Loot Project. Each ShadowLoot NFT is derived from a Loot Box and shows the items of a Loot Box as shadows on a canvas.", "attributes":"", "image":"',imageURI,'"}'
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }
}
