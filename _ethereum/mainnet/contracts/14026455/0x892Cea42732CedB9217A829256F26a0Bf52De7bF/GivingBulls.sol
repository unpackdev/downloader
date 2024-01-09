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


Giving Bulls Season 1

Giving Bulls is a three season collection. Season one will contain 500 unique digital collectible NFTs,
with 55 different attributes living on the Ethereum blockchain. Every Giving Bulls NFT will give access
to our owners only exclusive giveaways. Information on the giveaways, Metaverse, season two, season three,
and all future plans will be avaliable on our road map. The road map is subject to change as the community
votes on the future of this project in Discord. At Giving Bulls, Bull holders are in charge of the project
and the staff works for you!

*/

pragma solidity 0.8.11;

import "./ERC721EnumerableLite.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract GivingBulls is ERC721EnumerableLite, Ownable {
    
    using Strings for uint256;

    uint public _price = 0.033 ether;
    uint8 public _presaleLimit = 2;
    uint public _maxSupply = 500;
    uint public _txnLimit = 5;
    bool public _saleIsActive = false;
    bool public _presaleIsActive = false;
    string private _tokenBaseURI;
    
    mapping(address => uint8) private _presale;
    
    constructor() ERC721B("Giving Bulls - Season 1", "GivingBulls") {
        
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

    function mintBull(uint8 total) public payable {

        if(_presaleIsActive) {
            require(_presale[msg.sender] > 0, "You have no presale mints available");
            require(_presale[msg.sender] >= total, "Amount requested is over presale limit");
            _presale[msg.sender] = _presale[msg.sender] - total;
        } else {
            require(_saleIsActive, "Sale is not active");
        }
        
        require(total > 0, "Number to mint must be greater than 0");
        require(total <= _txnLimit, "Over transaction limit");
        require(_price * total <= msg.value, "Ether value sent is not correct");

        uint256 supply = _owners.length;
        require(supply + total <= _maxSupply, "Purchase would exceed max supply");
        
        for(uint i = 0; i < total; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function addUserToPresale(address userAddress) public onlyOwner {
        _presale[userAddress] = _presaleLimit;
    }

    function addUsersToPresale(address[] calldata userAddresses) public onlyOwner {
        for(uint i=0; i < userAddresses.length; i++) {
            _presale[userAddresses[i]] = _presaleLimit;
        }
    }

    function isUserInPresale(address userAddress) public view returns(bool) {
        return _presale[userAddress] > 0;
    }

    function setPrice(uint price) public onlyOwner {
        _price = price;
    }

    function withdrawAllToAddress(address addr) public payable onlyOwner {
        require(payable(addr).send(address(this).balance));
    }
}
