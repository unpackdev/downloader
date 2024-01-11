// SPDX-License-Identifier: MIT       
pragma solidity ^0.8.13;

// Written by @bigbear, Audited by @littlebear

//  _____ _                 _____       _       _   __                      _   _____ _       _     
// |  _  | |               /  __ \     | |     | | / /                     | | /  __ \ |     | |    
// | | | | | ____ _ _   _  | /  \/_   _| |__   | |/ /  ___ _ __  _ __   ___| | | /  \/ |_   _| |__  
// | | | | |/ / _` | | | | | |   | | | | '_ \  |    \ / _ \ '_ \| '_ \ / _ \ | | |   | | | | | '_ \ 
// \ \_/ /   < (_| | |_| | | \__/\ |_| | |_) | | |\  \  __/ | | | | | |  __/ | | \__/\ | |_| | |_) |
//  \___/|_|\_\__,_|\__, |  \____/\__,_|_.__/  \_| \_/\___|_| |_|_| |_|\___|_|  \____/_|\__,_|_.__/ 
//                   __/ |                                                                          
//                  |___/                                                                           
//                                                                               
//                             .**&**%(      %*************/ (%&*      
//                            *(////((#&**********************#(//     
//                            &////#&*********@.,,,@*****(,,,,/*/*     
//                              ((/********,,,,,@##(,,,,,,,,,,,,*      
//                                ********. .%*****/,#,,,,,****/.%     
//                               &*******,.,,.*   .@,,,,,,,,,/*..*     
//                               **********/,,,..,,,,,,.,,,,,%,/**(    
//         /*%                ./@****************,,,,,,,,,,,,,%***@    
//        %*****     **   /****@@%**************,,,,,,,,,@%%%%%%%*%    
//      (/*******,   /& *%*****//@*************,,,,,,,,%%&@@%%%@@&     
//      %*********    ,  %#****/(***#%*********,,,,,,,,,,,,*@&&,,      
//       #(******&(/*. .*&*#***@/(%************/,,,,,,,,,,,**,,,,      
//        *******(. .,*/%@*&**(*//&/@@**********#*,,,,,,,,,,(,,,       
//      **********  **   @**/**   @/#(//(#@**********%*,,,,*//         
//     (**********  **/  &******    *#/##//@/(@@/@*@****&@/&           
//    (&#&**************#&/*(&%****@&*  *&//##@%((//(@@&#&             
//    @*#*********/&********************(**(   ******** /              
//  ,@@(@********///***************************//     ,*               
//  &##&@%******//@///&/***********************//(,**%/                
//  @%&&&&&&&&@&@#///*    #////***&************/#//@/.                 
// @%%&&****/#&@////*          ////(***********((&((                   
// @%&&@&&&&&///////                 *********%((#(                    
// &%@***@  ////(%                     ******/((((                     
// ****       #///%                    ,*****#(((%                     
// ***&         (////@(                 /*****((((                     
// %***(*&                               **#****&(//&/                 
//                                        **@**#.                      
                                                                                

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract OCKC is Ownable, ERC721A {

    using Strings for uint256;
    
    //@dev: Constant variables
    uint256 price = 10000000000000000 wei;
    uint256 maxSupply = 2000;
    uint256 maxPerTx = 20;

    //@dev: Why keep reading the comments
    string baseURI = "ipfs://bafybeigzelpo4yuv4am77ejfwznp7dqonq2a4k5malguuw5zauvym3qmda/";
    string contract_URI = "ipfs://bafybeifhbxoaba4hjbahuhqdqiv7ofm7y7z3jn46geibruqtyj6yakeh5m/";
    
    //@dev: I think this is where you put the token name
    constructor() ERC721A("Okay Cub Kennel Club", "Okay Cub Kennel Club"){
    }
    
    //@dev: Not sure what this does
    mapping(uint256 => string) private _tokenURIs;
    
    //@dev: Toggling the sale feels better
    bool public publicSaleOpen = false;    
    
    //@dev: Call this function with 0.01 eth for your own cub!
    function mint(uint256 _quantity) public payable {
        require(maxPerTx >= _quantity && _quantity != 0, "Cannot mint more than 20");
        require(totalSupply() + _quantity <= maxSupply, "Supply Exceeded");
        require(msg.value >= price * _quantity, "Send more ETH (0.01 per)");
        require(publicSaleOpen, "Public Sale Not Started Yet!");

        _safeMint(msg.sender, _quantity);

    }

    //@dev: Just for show, no roadmap = never doing airdrops ;)
    function Airdrop(address _wallet, uint256 _num) external onlyOwner{
        require(totalSupply() + _num <= maxSupply, "Max Supply Reached.");
        _safeMint(_wallet, _num);
    }

    //@dev: ARGUuuuuuuuuuuuuuAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    //@dev: opensea
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(contract_URI, "contractURI.json"));
    }

    function updatecontractURI(string memory contrURI) public onlyOwner {
        contract_URI = contrURI;
    }

    //@dev: I dont feel like commenting anymore
    function updateBaseURI(string memory _newBaseURI) public onlyOwner{
        baseURI = _newBaseURI;
    }

    function getBaseURI() external view returns(string memory) {
        return baseURI;
    }

    function updatePrice(uint256 _price) public onlyOwner() {
        price = _price;
    }

    function updateMaxSupply(uint256 _supply) public onlyOwner() {
        maxSupply = _supply;
    }

    function toggleSale() public onlyOwner() {
        publicSaleOpen = !publicSaleOpen;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getMintedCount(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

    //@dev: I'll come back for another comment:
    
    // When that pay check hit baby I’m rolling, rolling
    // Rari on the hills of LA coasting, coasting
    // Forgiatos drive it like I stole it, stole it

    function paycheck() external onlyOwner {
        uint _balance = address(this).balance;
        payable(owner()).transfer(_balance); //Owner
    }

    receive() external payable {}

}