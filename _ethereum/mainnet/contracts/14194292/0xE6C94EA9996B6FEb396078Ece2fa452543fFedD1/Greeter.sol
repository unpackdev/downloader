// SPDX-License-Identifier: MIT
// import ERC-721
// import SafeMath

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./SafeMath.sol";

//R30


contract R30 is ERC721{

    address public devAddress;
    address constant public RecipientAddress = 0xeE2cf34dF7de0fB1F19213dB3E7E4eA755b64a80;

    using SafeMath for uint256;
    using Strings for uint256;

    uint256 private constant TotalSupply = 2000;
    uint256 private TotalMint = 0;
    uint256 public SalePrice = 0.33 ether;

   

    uint256 public setBuyValue;

    string public baseTokenURI;
    string private Fee;

    bool public saleStart = false;
    bool public WhiteListStart = false;


    mapping(address => bool)public checkWhiteList; 
    mapping(address => uint256)public topFloor;

    constructor() ERC721("R30","R30"){
        devAddress = msg.sender;
    }

    function setBaseURI(string memory baseURI) external{
        require(msg.sender == devAddress,"You are not the dev");
        baseTokenURI = baseURI;
    }

    function tokenURI(uint256 _tokenId) public override view returns (string memory){
        return string(abi.encodePacked(baseTokenURI,_tokenId.toString()));
    }

    function totalSupply() public pure returns(uint256){ 
        return TotalSupply;
    }
    
    function total_Mint() public view returns(uint256){
        return TotalMint;
    }

    function setFEE(string memory url) external{
        require(msg.sender == devAddress,"You are not the dev");
        Fee = url;
    }

    function SaleStart() external{
        require(msg.sender == devAddress,"You are not the dev");
        
        if(saleStart == false){
            saleStart = true;
        }else{
            saleStart = false;
        }
    }

    function ChangeWhiteListStart() external{
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

    function setBuyAmount(uint256 value)external{
        require(msg.sender == devAddress,"You are not the dev");

        setBuyValue = value;
    }

    function mint() external payable{
        require(msg.value == SalePrice,"Wrong input price");
        require(total_Mint() < totalSupply(),"Sale is ended");
        require(saleStart == true,"Sale is not start yet");
        require(setBuyValue > 0 ,"This batch has sold out");
        require(topFloor[msg.sender] <=3,"You already bought three");

        setBuyValue--;
        TotalMint++;
        topFloor[msg.sender]++;

        _mint(msg.sender,TotalMint);
    
        payable(RecipientAddress).transfer(address(this).balance);

    }

    function WhiteListMint() external payable{
        require(msg.value == SalePrice,"Input price Wrong" );
        require(checkWhiteList[msg.sender] == true,"You are not on the list");
        require(WhiteListStart == true,"White List is not start yet");
        require(setBuyValue > 0 ,"This batch has sold out");
        TotalMint++;
        setBuyValue--;
        _mint(msg.sender,TotalMint);
        
        payable(RecipientAddress).transfer(address(this).balance);
    }

    function setWhiteList(address[] memory input) external{
        require(msg.sender == devAddress,"You are not the dev");

        for(uint256 a=0;a<input.length;a++){
            checkWhiteList[input[a]] = true;
        }
        //["address","address"]
    }

    function contractURI() public view returns (string memory) {
        return Fee;
    }

    




}