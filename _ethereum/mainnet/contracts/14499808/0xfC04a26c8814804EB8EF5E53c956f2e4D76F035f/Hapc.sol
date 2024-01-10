// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

//@author Lu33-Lucas#8195 on discord


//    @@@@@        @@@@@          @@@@@@@@@@@@@@@           @@@@@@@@@@@@@@@              @@@@@@@@@@@@@
//    @@@@@        @@@@@        @@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@
//    @@@@@        @@@@@        @@@@@@@@@@@@@@@@@@@       @@@@@        @@@@@@@@@        @@@@@@@@@@@@@@@
//    @@@@@        @@@@@        @@@@@         @@@@@       @@@@@         @@@@@@@@@       @@@@@@
//    @@@@@        @@@@@        @@@@@         @@@@@       @@@@@          @@@@@@@@@      @@@@@@
//    @@@@@        @@@@@        @@@@@         @@@@@       @@@@@           @@@@@@@@@     @@@@@@
//    @@@@@@@@@@@@@@@@@@        @@@@@         @@@@@       @@@@@          @@@@@@@@@      @@@@@@
//    @@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@       @@@@@        @@@@@@@@@        @@@@@@
//    @@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@         @@@@@@
//    @@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@           @@@@@@
//    @@@@@@@@@@@@@@@@@@        @@@@@         @@@@@       @@@@@                         @@@@@@
//    @@@@@        @@@@@        @@@@@         @@@@@       @@@@@                         @@@@@@
//    @@@@@        @@@@@        @@@@@         @@@@@       @@@@@                         @@@@@@
//    @@@@@        @@@@@        @@@@@         @@@@@       @@@@@                         @@@@@@
//    @@@@@        @@@@@        @@@@@         @@@@@       @@@@@                         @@@@@@@@@@@@@@@
//    @@@@@        @@@@@        @@@@@         @@@@@       @@@@@                         @@@@@@@@@@@@@@@
//    @@@@@        @@@@@        @@@@@         @@@@@       @@@@@                          @@@@@@@@@@@@@

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./ERC721A.sol";

contract Hapc is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;

    enum Step {
        Before,
        PublicSale,
        SoldOut,
        Reveal
    }

    string public baseURI;

    Step public sellingStep;

    uint private constant MAX_SUPPLY = 8000;
    uint public  MAX_gift = 30 ;

  
    uint public publicSalePrice = 0.01 ether;



    

  

    address[] private _team = [
        0xd008E851E84a2377aF5018C60a45EB6930e42966,//merchandise
        0xdF2F7444b4c8D207D6846B2f157454355063121b, // Metaverse
        0x58334a59Ef721b551b919EE1eFe993148EEb32f5, //Team
        0x046f3cB63c444298e24556dB13f6347C09c7d173, //Hapc2 ans party 
        0x02E5b0Eb9A7DE62Ca3009D98781d2c6B6FD45154 //collaborations
    ];

    

    uint[] private _teamShares = [
        18,
        28,
        10,
        28,
        16     
    ];

    

    uint private teamLength;

    constructor(  string memory _baseURI) ERC721A("Historical Ape Party Casino", "HAPC")
    PaymentSplitter(_team, _teamShares) {    
        baseURI = _baseURI;
        teamLength = _team.length;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }


    function publicSaleMint(address _account, uint _quantity) external payable callerIsUser {
        uint price = publicSalePrice;
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(totalSupply() + _quantity <= MAX_SUPPLY-MAX_gift , "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        _safeMint(_account, _quantity);
    }

    function gift(address _to, uint _quantity) external onlyOwner {
        require(_quantity <= MAX_gift, "Reached max Supply");
        MAX_gift = MAX_gift-_quantity;
        _safeMint(_to, _quantity);
    }

    
    function setUpMAX_gift(uint _quantity1) external onlyOwner{
        require(totalSupply() + _quantity1 <= MAX_SUPPLY , "Max supply exceeded");
        MAX_gift=_quantity1;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function changePriceSale(uint _priceSale) external onlyOwner {
       publicSalePrice = _priceSale;
    }

   

    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    
   
    //ReleaseALL
    function releaseAll() external {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    receive() override external payable {
        revert('Only if you mint');
    }



        

}