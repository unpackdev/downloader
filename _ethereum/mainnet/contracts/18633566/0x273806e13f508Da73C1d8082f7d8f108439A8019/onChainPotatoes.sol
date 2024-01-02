// SPDX-License-Identifier: MIT
/*
 *                       
 *                                 ████████████        
 *                           ░░▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓      
 *                     ██████▒▒▒▒▒▒▒▒░░░░░░░░░░░░██    
 *                 ▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░▒▒▓▓  
 *             ▓▓▓▓▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▓▓
 *           ██▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▓▓
 *         ██▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓
 *       ░░▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓
 *     ▓▓▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓
 *   ░░▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓
 * ▓▓▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██  
 * ▓▓▒▒▒▒▒▒▒▒░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓  
 * ▓▓▒▒▒▒▒▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██    
 * ▓▓▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓      
 * ▓▓▒▒▒▒▒▒▒▒░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██        
 * ▓▓▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓          
 * ▓▓▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████            
 *   ▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓                
 *     ▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████                    
 *       ▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓                        
 *           ▓▓▓▓▓▓▓▓▓▓▓▓▓▓                            
 *
 *                                                                                    
 * Website: onchainpotatoes.xyz
 * X : @onChainPotatoes
 * A 0-0 onchain initiative
 */

pragma solidity 0.8.20;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./IERC721AQueryable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./Base64.sol";

contract onChainPotatoes is ERC721A, ERC721AQueryable, Ownable {

    uint256 public price = 0.01 ether; 
    uint256 public MAX_SUPPLY = 1000;
    uint256 public maxPerTransaction = 10;
    uint256 public maxPerWallet = 11;
    uint256 public mintNum = 1;
    uint256 public freemint = 1;

    bool public plantActive;

    mapping(uint256 => address) public _minters;

    
    constructor () ERC721A("onChainPotatoes", "OCP") {
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function startPlanting() external onlyOwner {
        require(plantActive == false);
        plantActive = true;
    }

    function stopPlanting() external onlyOwner {
        require(plantActive == true);
        plantActive = false;
    }

    function mint(uint256 amount) public payable {
        require(plantActive, "Minting is not active");
        require(amount <= maxPerTransaction, "Exceeds max per transaction");
        require(_numberMinted(msg.sender) + amount <= maxPerWallet, "Exceeds max per wallet");

        if (_numberMinted(msg.sender) < mintNum && amount == freemint) {
            require(msg.value == 0, "Free mint must be zero value");
        } else {
            require(msg.value >= price * amount, "Insufficient funds");
        }
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        for (uint256 i = 1; i <= amount; i++) {
            _minters[totalSupply() + i] = msg.sender;
        }
        _safeMint(msg.sender, amount);
    }


    function tokenURI(uint256 tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "token does not exist");

        string[20] memory colorNames = [
        "Red", "Grey", "Silver", "Gold", "White", "Orange", "Pink", "Brown", "Teal", "Cyan",
        "Lime", "Magenta", "Indigo", "Violet", "Green", "Olive", "Navy", "Aqua", "Blue", "Purple"
        ];

        uint256 colorIndex = (tokenId * 2 + uint160(_minters[tokenId])) % colorNames.length;
        uint256 colorIndex1 = ((tokenId + 3) * 2 + uint160(_minters[tokenId])) % colorNames.length;
        (string memory colorInfo, string memory colorInfo1) = (colorNames[colorIndex], colorNames[colorIndex1]);

        string memory baseSvg = string(abi.encodePacked(
            '<svg width="1200px" height="1200px" viewBox="0 0 1540 1540" class="icon" version="1.1" xmlns="http://www.w3.org/2000/svg">'
            '<rect width="100%" height="100%" fill="black"/>'
            '<filter id="blur" x="-10" y="-10" width="100" height="200">'
            '<feOffset in="SourceGraphic" dx="60" dy="60"/>'
            '<feGaussianBlur in="SourceGraphic" result="pOtato">'
            '<animate attributeName="stdDeviation" values="10;200;10" dur="1s" repeatCount="indefinite"/></feGaussianBlur>'
            '<feMerge>'
            '<feMergeNode in="pOtato"/>'
            '<feMergeNode in="SourceGraphic"/>'
            '</feMerge>'
            '</filter>'
            '<pattern id="pores" x="0" y="0" width="20" height="20" patternUnits="userSpaceOnUse">'
            '<rect width="20" height="20" fill="', colorInfo, '"/>'
            '<circle cx="2" cy="5" r="2" fill="black"/>'
            '<circle cx="10" cy="10" r="2" fill="black"/>'
            '<circle cx="15" cy="15" r="2" fill="black"/>'
            '</pattern>'
            '<path d="M422.4 917.333333c-14.933333 0-29.866667 0-44.8-2.133333-98.133333-10.666667-179.2-57.6-224-132.266667-108.8-177.066667 2.133333-277.333333 108.8-371.2 27.733333-25.6 57.6-51.2 83.2-78.933333 8.533333-8.533333 17.066667-19.2 25.6-27.733333 115.2-128 243.2-273.066667 422.4-149.333334 72.533333 51.2 115.2 128 125.866667 224 12.8 132.266667-42.666667 283.733333-142.933334 388.266667-98.133333 93.866667-228.266667 149.333333-354.133333 149.333333z" fill="', (tokenId % 4 == 0) ? "url(#pores)" : colorInfo, '" filter="url(#blur)"  stroke="#000" stroke-width="10" stroke-dasharray="10 5 34" transform="scale(1.5)"/>'
            '<path d="M725.333333 277.333333c12.8 0 21.333333 8.533333 21.333334 21.333334s-8.533333 21.333333-21.333334 21.333333-21.333333-8.533333-21.333333-21.333333 8.533333-21.333333 21.333333-21.333334z m0 234.666667c0 12.8 8.533333 21.333333 21.333334 21.333333s21.333333-8.533333 21.333333-21.333333-8.533333-21.333333-21.333333-21.333333-21.333333 8.533333-21.333334 21.333333z m-170.666666-149.333333c0 12.8 8.533333 21.333333 21.333333 21.333333s21.333333-8.533333 21.333333-21.333333-8.533333-21.333333-21.333333-21.333334-21.333333 8.533333-21.333333 21.333334zM298.666667 682.666667c0 12.8 8.533333 21.333333 21.333333 21.333333s21.333333-8.533333 21.333333-21.333333-8.533333-21.333333-21.333333-21.333334-21.333333 8.533333-21.333333 21.333334z m128-74.666667c0 17.066667 14.933333 32 32 32s32-14.933333 32-32-14.933333-32-32-32-32 14.933333-32 32z" fill="', colorInfo1, '" transform="scale(1.5)"/>'
            '<g transform="translate(1490, 1490) scale(2)" fill="white">'
            '<path fill-rule="evenodd" clip-rule="evenodd" d="m15 16c.6-.7.9-1.7.9-3.1v-1.8c-.1-1.4-.4-2.4-.9-3.1-.6-.7-1.4-1.1-2.5-1.1-1.1 0-1.9.4-2.5 1.1-.6.7-.9 1.8-.9 3.2v1.8c0 1.3.3 2.3.9 3.1.6.7 1.4 1 2.5 1 1.1 0 1.9-.3 2.5-1.1zm-1.5-6.9c.3.4.4 1 .4 1.8v2.3c0 .8-.1 1.4-.4 1.8-.2.4-.5.5-1 .5-.5 0-.8-.2-1.1-.5-.2-.4-.3-1-.3-1.9v-2.4c0-.7.1-1.3.4-1.7.2-.3.5-.5 1-.5.5 0 .8.2 1 .6z"/>'
            '<path fill-rule="evenodd" clip-rule="evenodd" d="M2 2H22V22H2V2ZM4 4H20V20H4V4Z"/>'
            '</g>'
            '</svg>'
        ));

        string memory hotPotatoAttribute = compareStrings(colorInfo, colorInfo1) ? '{"trait_type":"Hot Potato", "value":"Yes"}' : '{"trait_type":"Hot Potato", "value":"No"}';
        string memory poresAttribute = (tokenId % 4 == 0) ? '{"trait_type":"Fine Pores", "value":"Yes"}' : '{"trait_type":"Fine Pores", "value":"No"}';
        
        string memory json = Base64.encode(bytes(string(
            abi.encodePacked(
                '{"name": "onChainPotato #', uint2str(tokenId),
                '", "description": "OnChainAnimatedExclusive999Supply. HoldersUpdatedWith$", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(baseSvg)),
                '", "attributes":['
                '{"trait_type":"Potato Color", "value":"', colorInfo, '"},'
                '{"trait_type":"Pore Color", "value":"', colorInfo1, '"},',
                hotPotatoAttribute, ',',
                poresAttribute,
                ']}'
            )
        )));

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function changemintNum(uint256 _mintNum) public onlyOwner {
        mintNum = _mintNum;
    }

    function changefreemint(uint256 _freemint) public onlyOwner {
        freemint = _freemint;
    }

    function changePrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setmaxPerTransaction(uint256 _maxPerTransaction) external onlyOwner
    {
        maxPerTransaction = _maxPerTransaction;
    }

    function setmaxPerWallet(uint256 _maxPerWallet) external onlyOwner
    {
        maxPerWallet = _maxPerWallet;
    }

    function changeSupply(uint256 _MAX_SUPPLY) external onlyOwner
    {
        require(_MAX_SUPPLY <= MAX_SUPPLY);
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
    
    function devPlant(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY);
        for (uint256 i = 1; i <= amount ; i++)
            {
                _minters[totalSupply() + i] = msg.sender;
            }
        _safeMint(msg.sender, amount);
    }

    function uint2str(uint _i) internal pure returns (string memory str) {
            if (_i == 0) {
                return "0";
            }
            uint j = _i;
            uint length;
            while (j != 0) {
                length++;
                j /= 10;
            }
            bytes memory bstr = new bytes(length);
            uint k = length;
            while (_i != 0) {
                bstr[--k] = bytes1(uint8(48 + _i % 10));
                _i /= 10;
            }
            return string(bstr);
        }

    }