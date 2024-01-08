/***
 __          __      _______          _____  _       _ _        _ 
 \ \        / /     |__   __|        |  __ \(_)     (_) |      | |
  \ \  /\  / /_ _ _   _| | ___   ___ | |  | |_  __ _ _| |_ __ _| |
   \ \/  \/ / _` | | | | |/ _ \ / _ \| |  | | |/ _` | | __/ _` | |
    \  /\  / (_| | |_| | | (_) | (_) | |__| | | (_| | | || (_| | |
     \/  \/ \__,_|\__, |_|\___/ \___/|_____/|_|\__, |_|\__\__,_|_|
                   __/ |                        __/ |             
                  |___/                        |___/              
***/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
contract MonsterChompers is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    bool public merkleEnabled = true;
    uint8 private countTokenIdGiveAway = 1;
    string private baseURI;
    mapping(uint256 => string) private _tokenURIs;
    using MerkleProof for bytes32[];    
    bytes32 public merkleRoot;
     
    constructor() ERC721("MonsterChompers", "MTC") {       
    }
    bool public saleStarted = true;
    uint256 public constant monsterPrice = 50000000000000000; //0.05 ETH
    uint256 public constant maxMonsters = 9995;
    uint8 public constant maxMonstersPurchase = 20;
    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }
    function _baseURI() override internal view virtual returns (string memory) {
        return baseURI;
    }
  
    function mint(bytes32[] memory proof, bytes32 leaf, uint256 numberOfTokens) public payable returns(uint256,uint256){
        
        bool cond;
        uint res;
        if (merkleEnabled)
        {
            // merkle tree
            require( keccak256(abi.encodePacked(msg.sender)) == leaf, "no equal" );    
            require( proof.verify(merkleRoot, leaf), "You are not in the list" );
        }
        
        require(saleStarted == true, "The sale is paused");            
        require(numberOfTokens <= maxMonstersPurchase, "Can only mint 20 tokens at a time");        
        (cond, res) = totalSupply().tryAdd(numberOfTokens);
        require(cond, "Overflow error");
        require(res <= maxMonsters, "Purchase would exceed max supply of Monsters");        
        (cond, res) = monsterPrice.tryMul(numberOfTokens);
        require(cond, "Overflow error");                        
        require(res == msg.value, "Ether value sent is not correct");
        
        uint256 newItem;
        uint256 newItemInit = totalSupply() + 1;
        uint8 i;
        for(i=0;i<numberOfTokens;i++){
            newItem = totalSupply() + 1;
            _safeMint(msg.sender, newItem);        
        }
                             
        return (newItemInit,newItem);
                
    }
    function mintGiveAway(address _receiver) public onlyOwner returns(uint256){
        
        require(saleStarted == true, "The sale is paused");   
        require(totalSupply() < maxMonsters, "Max mint maximum exceeded");                             
        require(msg.sender != address(0x0), "Public address of the msg.sender is not correct");
        require(_receiver != address(0x0), "Public address of the receiver is not correct");
        require(countTokenIdGiveAway <= 5, "amount exceeded");
        uint256 newItemId = 9995 + countTokenIdGiveAway;
        
        _safeMint(_receiver, newItemId);        
        countTokenIdGiveAway++;
                                    
        return newItemId;
        
    }
    
    function startSale() public onlyOwner {
        saleStarted = true;
    }
    function pauseSale() public onlyOwner {
        saleStarted = false;
    }   
   
    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }     
     
    function setMerkleRoot(bytes32 _root) public onlyOwner{
        merkleRoot = _root;
    }
    function startMerkle() public onlyOwner {
        merkleEnabled = true;
    }
    function stopMerkle() public onlyOwner {
        merkleEnabled = false;
    }
}