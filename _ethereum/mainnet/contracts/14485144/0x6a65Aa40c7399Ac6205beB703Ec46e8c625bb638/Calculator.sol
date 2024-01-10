//      _____       _            _       _                    
//     |  __ \     | |          | |     | |            
//     | /  \/ __ _| | ___ _   _| | __ _| |_ ___  _ __ 
//     | |    / _` | |/ __| | | | |/ _` | __/ _ \| '__|
//     | \__/| (_| | | (__| |_| | | (_| | || (_) | |  _
//      \____/\__,_|_|\___|\__,_|_|\__,_|\__\___/|_| |_|
//                                             
//       Fully working, completely on chain calculators.
//      
//               █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
//               █░█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█░█
//               █░█░░░░░░░░░░░░░░░░░░░█░█
//               █░█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█░█
//               █░▄▄▄▄░▄▄▄▄░▄▄▄▄░▄▄▄▄▄▄░█
//               █░█░░█░█░░█░█░░█░█░░░░█░█
//               █░▀▀▀▀░▀▀▀▀░▀▀▀▀░▀▀▀▀▀▀░█
//               █░█▀▀█░█▀▀█░█▀▀█░█▀▀▀▀█░█
//               █░█▄▄█░█▄▄█░█▄▄█░█▄▄▄▄█░█
//               █░▄▄▄▄░▄▄▄▄░▄▄▄▄░▄▄▄▄▄▄░█
//               █░█░░█░█░░█░█░░█░█░░░░█░█
//               █░▀▀▀▀░▀▀▀▀░▀▀▀▀░▀▀▀▀▀▀░█
//               █░█▀▀█░█▀▀█░█▀▀█░█▀▀▀▀█░█
//               █░█▄▄█░█▄▄█░█▄▄█░█▄▄▄▄█░█
//               █░▄▄▄▄░▄▄▄▄░▄▄▄▄▄▄▄▄▄▄▄░█
//               █░█░░█░█░░█░█░░░░░░░░░█░█
//               █░▀▀▀▀░▀▀▀▀░▀▀▀▀▀▀▀▀▀▀▀░█
//               ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
//          





// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


import "./ERC721Enumerable.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./CalcLib.sol";

contract Calculator is ERC721Enumerable, ERC2981, Ownable {
    
    uint public price;
    uint public maxSupply;

    
    uint96 public royaltyPercentage = 400; // 4% in basis points


    string public officialFrontEnd;

    CalcLib.ColorScheme[] internal colorSchemes;

    mapping(uint => uint) internal idToSchemeIndex;


    

    event TokenMint(address purchaser);


    constructor() ERC721("Calculator", "CALC") {
        maxSupply = 10_000;
        price = 0.04 ether;
        _setDefaultRoyalty(address(this), royaltyPercentage);
        

        colorSchemes.push(CalcLib.ColorScheme(
            ["f07167", "ff8b6d"],
            ["0081a7", "00afb9"],
            ["f07167", "ff8b6d"],
            ["fdfcdc", "fbffdd"],
            "fed9b7",
            "7b323a",
            "d8e1e0",
            "1e1e1e",
            "fdfcdc",
            "303133"
            ));

        colorSchemes.push(CalcLib.ColorScheme(
            ["353226","817a5c"],
            ["2c2c2c","525252"],
            ["e98151","ffaf5c"],
            ["292929","373737"],
            "beb087",
            "7b323a",
            "d8e1e0",
            "d8e1e0",
            "88897b",
            "d8e1e0"
            ));
        colorSchemes.push(CalcLib.ColorScheme(
            ["22333b","4e7587"],
            ["0a0908","564d44"],
            ["22333b","4e7587"],
            ["5e503f","847058"],
            "c6ac8f",
            "c6ac8f",
            "eae0d5",
            "2b241c",
            "eae0d5",
            "eae0d5"
            ));
        colorSchemes.push(CalcLib.ColorScheme(
            ["9e2a2b","9e2a2b"],
            ["9e2a2b","9e2a2b"],
            ["9e2a2b","9e2a2b"],
            ["fff3b0","fff3b0"],
            "fff3b0",
            "7b323a",
            "f0f0c9",
            "3c241c",
            "f0f0c9",
            "3c241c"
            ));





        colorSchemes.push(CalcLib.ColorScheme(
            ["ffadad","ffadad"],
            ["fdffb6","fdffb6"],
            ["ffd6a5","ffd6a5"],
            ["caffbf","caffbf"],
            "9bf6ff",
            "f5cac3",
            "bdb2ff",
            "bdb2ff",
            "fffffc",
            "bdb2ff"
            ));

        

    }

    function setFrontEnd(string memory url) public onlyOwner {
        officialFrontEnd = url;
    }

    function mint(uint[] memory schemeIds) public payable { //takes an array of numbers from 0-4
        require(schemeIds.length > 0);
        uint totalMints = schemeIds.length;
        require(msg.value == totalMints * price, "send correct amount");
        require(totalMints <= 5, "too many mints :(");
        require(totalSupply() + totalMints <= maxSupply, "at limit");
        for(uint i=0; i<totalMints; i++) {
            require(schemeIds[i] > 0 && schemeIds[i]<=5, "color doesn't exist");
            uint256 newItemId = totalSupply() + 1;
            idToSchemeIndex[newItemId] = schemeIds[i] -1;
            _safeMint(msg.sender, newItemId);
        }

        emit TokenMint(msg.sender);

    }


    function withdrawFunds() public onlyOwner {
        uint amount = address(this).balance;

        Address.sendValue(payable(owner()), amount);
    }



    function tokenURI(uint id) public view override returns(string memory) {
        address owner = ownerOf(id);
        require(_exists(id), "not exist");
        uint schemeIndex = idToSchemeIndex[id];
        CalcLib.ColorScheme memory scheme = colorSchemes[schemeIndex];

        return CalcLib.generateTokenURI(owner, id, schemeIndex + 1, scheme, officialFrontEnd);


    }
    function tokenIdsByOwner(address owner) public view returns(uint[] memory) {
        uint arrLength = balanceOf(owner);
        uint[] memory arr = new uint[](arrLength);
        for (uint i=0;i<arrLength; i++) {
            arr[i] = tokenOfOwnerByIndex(owner, i);
        }
        return arr;

    }



// // REQUIRED OVERRIDES:
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }





}