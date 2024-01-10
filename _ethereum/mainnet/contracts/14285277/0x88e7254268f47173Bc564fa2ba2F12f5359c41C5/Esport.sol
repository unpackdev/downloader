// SPDX-License-Identifier: MIT
// import ERC-721
// import SafeMath

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./SafeMath.sol";


contract BROEsports is ERC721{

    address public devAddress;
    address constant public RecipientAddress = 0x6aCF699E4bF7F7B2e091DeBc58C1A21a01a39aAC;

    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public TeamOwn = 300;
    uint256 private TotalSupply = 6666;
    uint256 private TotalMint = 0;
    uint256 public SalePrice = 0.06 ether;


    string public baseTokenURI;
  

    bool public WhiteListStart = false;


    mapping(address => bool)public checkWhiteList; 
    mapping(address => uint256)public topFloor;

    constructor() ERC721("Bro-Esports","Bro-Esports"){
        devAddress = msg.sender;
    }

    function setBaseURI(string memory baseURI) external{
        require(msg.sender == devAddress,"You are not the dev");
        baseTokenURI = baseURI;
    }

    function tokenURI(uint256 _tokenId) public override view returns (string memory){
        return string(abi.encodePacked(baseTokenURI,_tokenId.toString()));
    }

    function totalSupply() public view returns(uint256){ 
        return TotalSupply;
    }
    
    function total_Mint() public view returns(uint256){
        return TotalMint;
    }

    function BurnTotalSupply()external{
        require(msg.sender == devAddress,"You are not the dev");

        TotalSupply = TotalMint;
    }

     function BurnTotalSupplySafety(uint256 amount)external{
        require(msg.sender == devAddress,"You are not the dev");

        TotalSupply = amount;
    }

    

    function Start() external{
        require(msg.sender == devAddress,"You are not the dev");

        if(WhiteListStart == false){
            WhiteListStart = true;
        }else{
            WhiteListStart = false;
        }
    }

    function ChangeSalePrice(uint256 price) external{
        require(msg.sender == devAddress,"You are not the dev");
        SalePrice = price * 1e16;
    }

   

    function Mint(uint256 amount) external payable{
        require(msg.value == SalePrice * amount,"Input price Wrong" );
        require(WhiteListStart == true,"White List is not start yet");
        require(total_Mint()+amount < TotalSupply -300 ,"Sale is ended");
        require(amount <= 20,"Can't but more then 20");
        


        for(uint256 a=0;a<amount;a++){
        TotalMint++;

        topFloor[msg.sender]++;
      
        _mint(msg.sender,TotalMint);
        
        }
        require(topFloor[msg.sender]<= 20,"You buy too much");
        
        payable(RecipientAddress).transfer(address(this).balance);
    }

    function CreaterMint(address user)external{
        require(msg.sender == devAddress || msg.sender == RecipientAddress,"You are not the DEV");
        require(total_Mint() < TotalSupply  ,"Sale is ended");
        require(TeamOwn>0,"usage Over");

        TeamOwn--;
        TotalMint++;
        _mint(user,TotalMint);

    }

    function AirDrop(address[] memory input) external{
        require(msg.sender == devAddress || msg.sender == RecipientAddress,"You are not the DEV");
        require(TeamOwn - input.length>0,"Airdrop over");

         for(uint256 a=0;a<input.length;a++){
            TotalMint++;
            TeamOwn--;
            _mint(input[a],TotalMint);
        }

        require(total_Mint() <= TotalSupply  ,"Not enought NFT");
    }

    



}