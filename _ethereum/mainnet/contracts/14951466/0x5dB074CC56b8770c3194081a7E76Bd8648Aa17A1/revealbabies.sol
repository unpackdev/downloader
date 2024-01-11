// SPDX-License-Identifier: MIT

/*
██████╗ ███████╗██╗   ██╗██████╗  █████╗ ██╗         ██████╗  █████╗ ██████╗ ██╗   ██╗
██╔══██╗██╔════╝██║   ██║╚════██╗██╔══██╗██║         ██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝
██████╔╝█████╗  ██║   ██║ █████╔╝███████║██║         ██████╔╝███████║██████╔╝ ╚████╔╝ 
██╔══██╗██╔══╝  ╚██╗ ██╔╝ ╚═══██╗██╔══██║██║         ██╔══██╗██╔══██║██╔══██╗  ╚██╔╝  
██║  ██║███████╗ ╚████╔╝ ██████╔╝██║  ██║███████╗    ██████╔╝██║  ██║██████╔╝   ██║   
╚═╝  ╚═╝╚══════╝  ╚═══╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚═════╝ ╚═╝  ╚═╝╚═════╝    ╚═╝  
*/


pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Address.sol"; 
import "./IERC20.sol";

contract REV3ALBABY is ERC721A, Ownable, ReentrancyGuard {

uint256 public immutable maxSupply = 2500;
uint256 private immutable reservedSize = 200;
uint64  private immutable maxBatchSize = 50;

struct MintInfo {
    bytes32 Root;
    uint256 Price;
    uint64 Max;
    uint256 Supply;
    bool Paused;
}

mapping(uint64 => MintInfo) public MintList;
mapping(address => uint256) public OwnersHistory;
mapping(address => uint256) public OGOwnersHistory;


ERC721A REBORNCONTRACT = ERC721A(0x4b530443A78001F38d96A272f0d5eD3eB0A5328e);
string public _baseTokenURI = "ipfs://QmYgUs7rSvyKav3q9g6ZoZUCP4JDnNBSaD8StzcRX2dC4r/";

constructor() ERC721A("REV3ALBABY", "REV3ALBABY") {
    MintList[1]  = MintInfo(0x98e42f970869dadbd53f93dc89999572154c33b4ce44c5a7446d821778ae8a85,0,1,2300,false); // owners
    MintList[2]  = MintInfo(0x520e3e0a36ab3c07f460cafea2522970cda08be7258fc66f41c5d746d2b8d312,0,1,2300,false); // og owners
}

function _onlySender() private view {
    require(msg.sender == tx.origin);
}

modifier onlySender {
    _onlySender();
    _;
}


function _revMint(address to, uint256 amount) internal {
    require((totalSupply() + amount) <= maxSupply - reservedSize, "Sold out!");
    _safeMint(to, amount);
}

function lowBulkMint(address to,uint256 amount) external onlyOwner {
    _safeMint(to,amount);
}


function getUserMintCount(address _address, bool _isOG) public view returns(uint256){
        uint256 balance = REBORNCONTRACT.balanceOf(_address);
        if(_isOG == true){
            balance = balance < 2 ? 2 : balance;
        }
        return _isOG == true ? balance : balance / 2;
}

function bulkMint(uint256 amount) external onlyOwner {
    require((totalSupply() + amount) <= maxSupply, "Sold out!");
    require(amount % maxBatchSize == 0,"Can only mint a multiple of the maxBatchSize");
    uint256 numChunks = amount / maxBatchSize;
    numChunks = numChunks == 0 ? amount : numChunks;
    for (uint256 i = 0; i < numChunks; i++) {
        _safeMint(msg.sender, maxBatchSize);
    }
}

function isAddressOwner(bytes32[] memory proof, bytes32 _leaf) public view returns (bool)
{
    return checkMerkleRoot(MintList[1].Root, proof, _leaf);
}

function isAddressOGOwner(bytes32[] memory proof, bytes32 _leaf) public view returns (bool)
{
    return checkMerkleRoot(MintList[2].Root, proof, _leaf);
}

function checkMerkleRoot(bytes32 merkleRoot,bytes32[] memory proof,bytes32 _leaf) internal pure returns (bool) {
    return MerkleProof.verify(proof,merkleRoot, _leaf);
}

function setPrices(uint256 _ownerPrice,uint256 _ogOwnerPrice) external onlyOwner{
    MintList[1].Price = _ownerPrice;
    MintList[2].Price = _ogOwnerPrice;
}


function setOptions(bytes32 _ownerRoot,bytes32 _ogRoot) external onlyOwner {
    MintList[1].Root = _ownerRoot;
    MintList[2].Root = _ogRoot;
}

function OwnerMint(bytes32[] memory proof, uint256 amount) external payable onlySender nonReentrant {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(isAddressOwner(proof,leaf),"You are not eligible for an owner mint");
    uint256 balance = getUserMintCount(msg.sender,false);
    require(OwnersHistory[msg.sender] + amount <= balance,"Minting amount exceeds allowance per wallet");
    MintList[1].Supply = MintList[1].Supply - amount;
    OwnersHistory[msg.sender] += amount;
    _revMint(msg.sender, amount);
}


function OGOwnerMint(bytes32[] memory proof, uint256 amount) external payable onlySender nonReentrant {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(isAddressOGOwner(proof,leaf),"You are not eligible for an og owner mint");
    uint256 balance = getUserMintCount(msg.sender,true);
    require(OGOwnersHistory[msg.sender] + amount <=  balance,"Minting amount exceeds allowance per wallet");
    MintList[2].Supply = MintList[2].Supply - amount;
    OGOwnersHistory[msg.sender] += amount;
    _revMint(msg.sender, amount);
}

function withdraw() public onlyOwner nonReentrant
{
    uint256 total = address(this).balance;
     (bool success, ) =  payable(msg.sender).call{value: total}("");
     require(success, "Transfer failed..");
}

function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
}

function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
}

function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory)
{
    return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId),".json"));
}

function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
    uint256 _balance = balanceOf(address_);
    uint256[] memory _tokens = new uint256[] (_balance);
    uint256 _index;
    uint256 _loopThrough = totalSupply();
    for (uint256 i = 0; i < _loopThrough; i++) {
    bool _exists = _exists(i);
    if (_exists) {
    if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
    }
    else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
    }
    return _tokens;
}  

}

