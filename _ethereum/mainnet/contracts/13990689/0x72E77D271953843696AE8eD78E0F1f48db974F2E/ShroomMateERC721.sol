// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

//@@@@@@@*..,@@@@@@@@@@@@@@@@@@....*.@@@@@@@@**@*@@@@@@@@@@@@..*@@,,@(..@@@@@@  
//@&..............@@@@......@@@......@%@@@@@.........@@@@@@@..............@@@@  
//@@......#.......@%@@@....../@......@%@@@@@.........@@@@@@@*......@@%....@%@@  
//@@,,,,,@@&@@@@@@@@@@@.@#...........@%@@@@....@.%@..@%@@@@@@.....@@@@...@@%@@  
//@@*&***@%@(***,,@@@@@,,,,,,,,,,,,,@@%@@@#,@,,@@@,@,,@@@@@@@,*,*********%@&@@  
//@@/(%///@@@/////@@@@@@///&////****@@@@@@/*////*/////@@&@@@@///////////@@@@@@  
//@@/&///////////&@&@@@//////@#////(@@@@@/////@#(/@/////@@@@@/@////@//////@@@@  
//@@@@(//////////@@%@@@%//////@@@///@@@@@//%///(@@@/////#@@@@////@@@@/////@@@@  
//@@@@@@/&@@#/@@@%@@@@@@@@@@/@%@@@/@@@%@@@@&@@@&%@@@@(@@&%@@@@///@@@@@//@@%@@@  
//@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@(@%@@@@@@@@@%@@@@@@&@&@@@@@@@@%@@@@@@@@@@@@@  
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
//@@@@@@@@@,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     
//@@@@(.......@@@@@@@@@@@....%...*@@@@@@@...........@@@@**@@...........@@@@     
//@@@@(..%...@@@@@@@@@@@.........@@@@@@@@@.....@.....@@@*,@@...........@@@@     
//@@@@..,....*@@@@@@@@@@@...@.(.*.@&@@@@@@....#@....(.@@@,@(.....@@.(.%@@@@     
//@@@@%,,,,,,@@@@@@@@@@@,,,,@@@@,,,@@@@@@@,,,,,,,,,,,*@@**@%,,..,.,,,@@&@@@     
//@@@@*******@%@@@@@@@@***(**/****(**&@@@@****@/@&&****@@@@@@@@&/,,,,,,@@@@     
//@@@@@(@////(/&@/@@@@@////**%*******@@@@@@***#@@*&***%@@@@@@@@@@****%*@&@@     
//@@@@%/////@/////(@&@%/////(@@@//////@@@@///////////@#@@@@///////////@@%@@     
//@@@@//%@(//////@@%@@@@@#//@@%@@/#@/@@@@@//@%/(/@@@/@%@/@@///////&@/@@&@@@     
//@@@@@@@@@@@@@@//@@@@@@@@/@%@@@@@@/@@@@@@@@@@@@/(%@@@@@/,@%/@@@//@@%@@@@@@     
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@/@%@@@@@@@@@@@@@@@@@@@@@@@@ 
//%%%%%%%%%%%%%%%&%%%%&&&&&&%%&&&&&&&&&&&&%&&&&&&&&%&&&&&&%&%&&&&&&&&&&&&&&&%&&&%%
//%&%%%%%%%%%%%%%%%%%%&%%%%&&%&%@@&@@%&&&&&&&&&&%%%%%%%%&%%&&&&&&&&&&&&&&%%%%%%&&%
//%%%%%%%%%%%%%%%%%%%%%%@@@%   &@@@@@     @@@@ .&&%%%&&%%%%%&&%&&&%&%%&%%&%%%%&%%&
//%%%%%%%%%%%%%%%%%%,    @@@/   *@@@@@     @@@#   @.   @&&%%&%&%%%&%%%%%%%%%%&&%%%
//%%%%%%%%%%%%%%& &@@. ...@@@@....@@@@@.     .@   @@.   @@@.&&%%&%%&&%&&&&&&&%%%%%
//%%%%%%%%%%%%@@@&.(@@.....@@@@@....@@@@,........  .@.  .@@@. %%&&%&%%&&&&&&%%%%%%
//%%%%%%&%%%&  ,@@@@@@*.....@@@@@(...#@@@@@#.........@#  &@@@   (%&&&%&%%%%%%%%%%%
//%%%%%%%%%&. ...@@@@@@....,*@@@@@@*...#@@@@@@@.......,#. @@@@    @@%%%%%%%%%%%%%%
//%%%%%%%%%@@,.....@@@%%%%&%%%&%%%%&%%%%@&@@@@@@@@(........@@@.   #@@&%%%%%%%%%%%%
//&&&&&%%%%@@@,....@&%%%&%%%%%%%%%%%%%%%%%%%%@@@@@@@@&......@@@    @@& #%%%%%%%%%%
//%%%%%%%%%@@@@,..,%&%%%%&%%%%%&%&%%&%%&%%%%&%%&%@@@@@@@....%@@,.  @@&  &%%%%%%%%%
//&&%%%%%%%&@@@@...@&%%%%%%&%&%%&%%%&%%%%%%%%&%%%%%&@@@@@#..*@@...,@@    @%%%%%%%%
//%&%&%%%%%%%@@@@...@&%&%&%&*&%%*&%&%%%%%@%&%%%%%%%%%&&@@@@..@#...@@    @@@%%%%%%%
//%%%%%%%%%%%%@@@,....%&%&%/ #%%%,,,,,,*,/,&%&%%%%&%%%%%@@@@.@*..@..  *@@@ @%%%%%%
//%%%%%%%%%%%%%%@(......&&*%&/,,,,  (  ,,,,((,%%%%&&%%%%&%(@@@&......@@@  @@%%%%%%
//%%%%%%%%%%%%%%%%(....@&*&%,,,,,,(&&/,*#/  //%&(@%%&&%%%%%@@@@*....@@   @@@%%%%%%
//*#%&&%%%%%%%%%%%%%%,..,@%(,,,,,@@@@*.#/ %//,#./%%%%%%%%%%%#@@@...(@@  @@,%%%%%%%
//#/****/**%%%%%%%%%%%%%( *.(,,,,,(%(@@*/////,&,@&&%%&&%%%%%&.@@@..(@@ /@. @%%%%%%
//////*****///%&%%%%%%.%@%*,,,,,,,,,***////,,&&&&&%&%&&%%%%%%.,@@@.,@% &@ @%%%%%%%
//////********//////&,,   ,,,,,,,,&/*.&&%/,&%%/%%&&&&%&&%&%&(..%@@,.@,  /%%%%%%%%%
///////%***///***/(,,,,,,,,,,,,,,,***////,% .&@@.@@@@@@@@@@@&...@@/.@  %%%%%%%%%%%
///////**#**%%***%,,,%.#&&/,,,,,,***#    *%%%&*@@.*@@/...,@@@#..%@& .%%%%%%%%%%%%%
//((/////*(///**,,,,,, (&&,,,,,/  .&. %@%@&  .&%%%%%%&@#. .@@@. #%%%%%%%%%%%%%%%%%
//(***////**.@&,#,,,,,,,%..*,*/%@##. . ,.@%%****/******&%%%%%%%%%%%%%&#**(&/*&&&#*
///********/%/@*%.,,.&,,#* (,,,/@@**///*,//%/(*******%**/*&%%%%%%&%***//**////////
/////******@.%&@/,,.%*,,,,,*%#,***/////*,///(********///////*****************(/***
//&#//**********/(./*,,,,/@&,,,**//////,,**//////////////*****************//(((/**
///**/////////*****&#& #,,,,,,*//(////,,&***/*///////*********//////***////(((///*
//***//****(((//****    &,,/*& %@*  @,,&********//*******(#**//********//(((((//**
//***/*****/((((/%(*****/&#&/*%@@%@ %,**********//*******//*************/((((//***
///*******/(((((((//*******(,,,,*,&%//#%********////((////**************(((*******
///******//((((((((((///******///////(//#//((////////******************/((********

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract ShroomMateERC721 is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint;
    using SafeMath for uint256;
    using Address for address;

    string private baseURI;

    bytes32 private root;

    string public provinanceHash; 

    uint256 public maxSupply = 7777;
    uint256 public maxBuyable = 7700;
    uint256 public price = 0.035 ether;

    bool public presaleActive = false;
    bool public saleActive = false;

    uint256 public buffer;

    mapping (address => uint256) public genBalance;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }
    
    function mint(uint256 numberOfMints) public payable{
        uint256 supply = totalSupply();
        require(saleActive,                                 "Sale must be active to mint");
        require(numberOfMints > 0 && numberOfMints < 7,     "Invalid purchase amount");
        uint256 maxSupplyBuff = maxBuyable + buffer;
        require(supply.add(numberOfMints) <= maxSupplyBuff,     "Purchase would exceed max supply of ShroomMate");
        require(genBalance[msg.sender].add(numberOfMints) <= 7 , "Max number of mints per wallet is 7");
        require(msg.value >= price * numberOfMints, "Ether value sent is below the price");

        for(uint256 i; i < numberOfMints; i++) {
            _safeMint(msg.sender, supply + i);
            genBalance[msg.sender]++;
        }
    }
    
    function gift(uint256 numberOfMints, address _to) public onlyOwner{ 
        uint256 supply = totalSupply(); 
        require(numberOfMints > 0,                        "Invalid purchase amount");   
        require(supply.add(numberOfMints) <= maxSupply,   "Purchase would exceed max supply of ShroomMate");    
        buffer++;   
        for(uint256 i; i < numberOfMints; i++) {    
            _safeMint(_to, supply + i); 
            genBalance[msg.sender]++;   
        }   
    }   

    function whiteListMint(uint256 numberOfMints, bytes32[] calldata _proof) public payable {
        uint256 supply = totalSupply();
        require(presaleActive,                                 "Sale must be active to mint");
        require(numberOfMints > 0 && numberOfMints < 7,     "Invalid purchase amount");
        uint256 maxSupplyBuff = maxBuyable + buffer;
        require(supply.add(numberOfMints) <= maxSupplyBuff,     "Purchase would exceed max supply of ShroomMate");
        require(genBalance[msg.sender].add(numberOfMints) <= 7 , "Max number of mints per wallet is 7"); 
        require(msg.value >= price * numberOfMints, "Ether value sent is below the price");

        require(_verify(
            _proof,
            _leaf(msg.sender))
        );

        for(uint256 i; i < numberOfMints; i++) {
            _safeMint(msg.sender, supply + i);
            genBalance[msg.sender]++;
        }
    }

    function _leaf(address wallet) 
    internal pure returns (bytes32) 
    {
        return keccak256(abi.encodePacked(wallet));
    }

    function _verify(bytes32[] memory _proof, bytes32 leaf)
    internal view returns (bool)
    {
        return MerkleProof.verify(_proof, root, leaf);
    }

    function walletOfOwner(address owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setRoot(bytes32 _root) public onlyOwner {
        root = _root;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setHash(string memory _hash) public onlyOwner {
        provinanceHash = _hash;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}