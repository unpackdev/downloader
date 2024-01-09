// ___/\\\\\\\\\\\\\____/\\\_____________/\\\\\\\_______________________/\\\____________/\\\\\\\\\\\\\____/\\\__________________________________________________________________        
//  __\/\\\/////////\\\_\/\\\___________/\\\/////\\\_________________/\\\\\\\___________\/\\\/////////\\\_\/\\\__________________________________________________________________       
//   __\/\\\_______\/\\\_\/\\\__________/\\\____\//\\\_______________\/////\\\___________\/\\\_______\/\\\_\/\\\__________________________________________________________________      
//    __\/\\\\\\\\\\\\\/__\/\\\_________\/\\\___//\/\\\__/\\/\\\\\\_______\/\\\___________\/\\\\\\\\\\\\\/__\/\\\_____________/\\\\\_____/\\/\\\\\\\______/\\\\\\\\_____/\\\\\\\\__     
//     __\/\\\/////////____\/\\\\\\\\\\__\/\\\_//__\/\\\_\/\\\////\\\______\/\\\___________\/\\\/////////____\/\\\\\\\\\\____/\\\///\\\__\/\\\/////\\\___/\\\//////____/\\\/////\\\_    
//      __\/\\\_____________\/\\\/////\\\_\/\\\/____\/\\\_\/\\\__\//\\\_____\/\\\___________\/\\\_____________\/\\\/////\\\__/\\\__\//\\\_\/\\\___\///___/\\\__________/\\\\\\\\\\\__   
//       __\/\\\_____________\/\\\___\/\\\_\//\\\____/\\\__\/\\\___\/\\\_____\/\\\___________\/\\\_____________\/\\\___\/\\\_\//\\\__/\\\__\/\\\_________\//\\\________\//\\///////___  
//        __\/\\\_____________\/\\\___\/\\\__\///\\\\\\\/___\/\\\___\/\\\_____\/\\\___________\/\\\_____________\/\\\___\/\\\__\///\\\\\/___\/\\\__________\///\\\\\\\\__\//\\\\\\\\\\_ 
//         __\///______________\///____\///_____\///////_____\///____\///______\///____________\///______________\///____\///_____\/////_____\///_____________\////////____\//////////__


// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

//import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract Ph0n1Phorce is ERC721, Ownable {

    uint public constant MAX_NFT_SUPPLY = 7777;
    uint public NFT_PRICE;

    string BASE_URI;

    bool public isSaleActive;

    
    uint public totalSupply;

    mapping(address => uint) public mintedNFTs;

    constructor () ERC721("Ph0n1 Phorce", "Ph0n1") {
        isSaleActive = true;
        totalSupply = 1;
        NFT_PRICE = 0 ether;
        BASE_URI = "https://ph0n1phorce.herokuapp.com/api/token/";
    }

    function setSaleActiveness(bool _isSaleActive) public onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function setBaseUri(string memory _baseURIArg) public onlyOwner {
        BASE_URI = _baseURIArg;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

   function mint(uint256 amount) external payable {
        require(isSaleActive, "Sale has not started.");
        require(amount > 0, "Amount of tokens must be positive");
        require(totalSupply + amount <= MAX_NFT_SUPPLY, "MAX_NFT_SUPPLY constraint violation");

        
        require(msg.value >= NFT_PRICE * amount, "Wrong ether value.");

        mintedNFTs[msg.sender] += amount;

        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply + i);
            
        }
        totalSupply += amount;
    }

   

    function setPrice(uint256 amount) public onlyOwner {
      NFT_PRICE = amount;
    }

   function withdraw() public payable onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
    }

}
