// SPDX-License-Identifier: MIT

/* 

 $$$$$$\  $$\            $$\                           $$$$$$$\            $$\ $$\           
$$  __$$\ \__|           \__|                          $$  __$$\           $$ |$$ |          
$$ /  \__|$$\ $$\    $$\ $$\ $$$$$$$\   $$$$$$\        $$ |  $$ |$$\   $$\ $$ |$$ | $$$$$$$\ 
$$ |$$$$\ $$ |\$$\  $$  |$$ |$$  __$$\ $$  __$$\       $$$$$$$\ |$$ |  $$ |$$ |$$ |$$  _____|
$$ |\_$$ |$$ | \$$\$$  / $$ |$$ |  $$ |$$ /  $$ |      $$  __$$\ $$ |  $$ |$$ |$$ |\$$$$$$\  
$$ |  $$ |$$ |  \$$$  /  $$ |$$ |  $$ |$$ |  $$ |      $$ |  $$ |$$ |  $$ |$$ |$$ | \____$$\ 
\$$$$$$  |$$ |   \$  /   $$ |$$ |  $$ |\$$$$$$$ |      $$$$$$$  |\$$$$$$  |$$ |$$ |$$$$$$$  |
 \______/ \__|    \_/    \__|\__|  \__| \____$$ |      \_______/  \______/ \__|\__|\_______/ 
                                       $$\   $$ |                                            
                                       \$$$$$$  |                                            
                                        \______/                                             


Giving Bulls Season 2
https://www.givingbulls.com/
*/

pragma solidity 0.8.11;

import "./ERC721EnumerableLite.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";

abstract contract S1BULLS {
  function ownerOf(uint256 tokenId) public virtual view returns (address);
}

contract GivingBulls is ERC721EnumerableLite, Ownable, PaymentSplitter {
    
    using Strings for uint256;

    uint public _txnLimit = 10;
    uint public _price = 0.06 ether;
    uint public _presalePrice = 0.04 ether;
    uint public _mintCount = 0;
    uint public _presaleTotal = 1000;
    uint public _publicTotal = 2000;
    uint public _maxSupply = 2500;
    bool public _saleIsActive = false;
    bool public _presaleIsActive = false;
    address public _s1BullsAddress = 0x892Cea42732CedB9217A829256F26a0Bf52De7bF;
    mapping(uint => bool) public _s1BullClaimed;
    string private _tokenBaseURI;
    S1BULLS private _s1Bulls;
    
    address[] private _addressList = [
        0x938E426De81Df890eB716D724fb73D5484a7eC21,
        0xBc3B2d37c5B32686b0804a7d6A317E15173d10A7,
        0x71c59bE1164D1B4eF065C800a62aDB3E2EA61F01
    ];
    uint[] private _shareList = [
        8,
        8,
        84
    ];
    
    constructor() ERC721B("Giving Bulls - Season 2", "GivingBullsS2")
        PaymentSplitter(_addressList, _shareList) {
        _s1Bulls = S1BULLS(_s1BullsAddress);
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    } 

    function setBaseURI(string memory uri) public onlyOwner {
        _tokenBaseURI = uri;
    }

    function flipSaleState() public onlyOwner {
        _saleIsActive = !_saleIsActive;
    }

    function flipPresaleState() public onlyOwner {
        _presaleIsActive = !_presaleIsActive;
    }

    function mintBull(uint qty) public payable {
        
        require(qty > 0, "Number to mint must be greater than 0");
        require(qty <= _txnLimit, "Over transaction limit");

        _mintCount += qty;

        if(_presaleIsActive) {
            require(_mintCount <= _presaleTotal, "Amount requested will exceed presale limit");
            require(_presalePrice * qty <= msg.value, "Ether value sent is not correct for presale");
        } else {
            require(_saleIsActive, "Sale is not active");
            require(_mintCount <= _publicTotal, "Amount requested will exceed public sale limit");
            require(_price * qty <= msg.value, "Ether value sent is not correct");
        }
                
        uint256 supply = _owners.length;
        require(supply + qty <= _maxSupply, "Purchase would exceed max supply");
        
        for(uint i = 0; i < qty; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function claimFreeBulls(uint[] calldata s1TokenIds) public payable {
        uint256 supply = _owners.length;
        for(uint i=0; i < s1TokenIds.length; i++) {
            require(!_s1BullClaimed[s1TokenIds[i]], "This S1 Bull has already claimed a S2 Bull");
            require(_s1Bulls.ownerOf(s1TokenIds[i]) == msg.sender, "You do not own this S1 bull");
            _s1BullClaimed[s1TokenIds[i]] = true;
            _safeMint(msg.sender, supply++);
        }
    }

    function adminClaimFreeBulls(uint[] calldata s1TokenIds) public payable onlyOwner {
        uint256 supply = _owners.length;
        for(uint i=0; i < s1TokenIds.length; i++) {
            require(!_s1BullClaimed[s1TokenIds[i]], "This S1 Bull has already claimed a S2 Bull");
            _s1BullClaimed[s1TokenIds[i]] = true;
            _safeMint(msg.sender, supply++);
        }
    }

    function setPrice(uint price) public onlyOwner {
        _price = price;
    }
    
    function setPresalePrice(uint price) public onlyOwner {
        _presalePrice = price;
    }
}
