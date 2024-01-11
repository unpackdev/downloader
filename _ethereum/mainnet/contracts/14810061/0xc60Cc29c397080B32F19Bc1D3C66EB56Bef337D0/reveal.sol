// SPDX-License-Identifier: MIT

/*
██████╗░███████╗██╗░░░██╗██████╗░░█████╗░██╗░░░░░
██╔══██╗██╔════╝██║░░░██║╚════██╗██╔══██╗██║░░░░░
██████╔╝█████╗░░╚██╗░██╔╝░█████╔╝███████║██║░░░░░
██╔══██╗██╔══╝░░░╚████╔╝░░╚═══██╗██╔══██║██║░░░░░
██║░░██║███████╗░░╚██╔╝░░██████╔╝██║░░██║███████╗
╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚═════╝░╚═╝░░╚═╝╚══════╝
*/
pragma solidity ^0.8.0;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Address.sol"; 
import "./IERC20.sol";

contract REV3AL is ERC721A, Ownable, ReentrancyGuard {

uint256 public immutable maxSupply = 7000;
uint256 public reservedSize = 200;
uint64  private immutable maxBatchSize = 50;

struct MintInfo {
    bytes32 Root;
    uint256 Price;
    uint64 Max;
    uint256 Supply;
    bool Paused;
}

mapping(uint64 => MintInfo) public MintList;
mapping(address => uint256) public MintHistory;
mapping(address => uint256) public WhiteListMintHistory;
mapping(address => uint256) public GoldListMintHistory;
mapping(address => uint256) public CoinMintHistory;

address[] public TeamList;
uint256[] public ShareList;
bool private teamListDone = false;
bool private mintStatus = false;
bool private teamMint;
bool private isRevealed = false;

address public constant teamWallet = 0x449E0945C21A951DAb3ae6136Af00ACeaE092bB4;
IERC20 public revCoinContract = IERC20(0x01c44267AECC20E239B21E1ef3Ce09Dd41013F3f);
string public _baseTokenURI;

constructor() ERC721A("REVEAL", "REVEAL") {
    MintList[1]  = MintInfo(0,0.1 ether,2,5800,true);
    MintList[2]  = MintInfo(0xee61932913c89134ebda94809fc300f505348025959d69c3f5bffbe109487116,0.08 ether,2,3000,true);
    MintList[3]  = MintInfo(0xfa382b6278c8ea79b84905707b60c5fbfedfa0490d7477cecc4a5fe901420ea8,0.06 ether,3,390,true);
    MintList[4]  = MintInfo(0,100 ether,5,1000,true);
}

function _onlySender() private view {
    require(msg.sender == tx.origin);
}

modifier onlySender {
    _onlySender();
    _;
}

function _revMint(address to, uint256 amount) internal {
    require((totalSupply() + amount) <= maxSupply, "Sold out!");
    _safeMint(to, amount);
}

function devMintBulk(uint256 amount) external onlyOwner {
    require(amount <= reservedSize, "Minting amount exceeds reserved size");
    require((totalSupply() + amount) <= maxSupply, "Sold out!");
    require(amount % maxBatchSize == 0,"Can only mint a multiple of the maxBatchSize");
    uint256 numChunks = amount / maxBatchSize;

    for (uint256 i = 0; i < numChunks; i++) {
        _safeMint(msg.sender, maxBatchSize);
    }
}

function devMint(uint256 amount) external onlyOwner {
    require(amount <= reservedSize, "Minting amount exceeds reserved size");
    require((totalSupply() + amount) <= maxSupply, "Sold out!");
    _safeMint(teamWallet, amount);
}

function isAddressGoldlisted(bytes32[] memory proof, bytes32 _leaf) public view returns (bool)
{
    return checkMerkleRoot(MintList[3].Root, proof, _leaf);
}


function isAddressWhitelisted(bytes32[] memory proof, bytes32 _leaf) public view returns (bool)
{
    return checkMerkleRoot(MintList[2].Root, proof, _leaf);
}

function checkMerkleRoot(bytes32 merkleRoot,bytes32[] memory proof,bytes32 _leaf) internal pure returns (bool) {
    return MerkleProof.verify(proof,merkleRoot, _leaf);
}

function setRootOps(bytes32 _goldRoot,bytes32 _wlRoot,uint256 _coinUnit) external onlyOwner {
    MintList[1].Root = _goldRoot;
    MintList[2].Root = _wlRoot;
    MintList[4].Price = _coinUnit;
}

function setOptions(bool _publicSaleStatus, bool _presaleStatus, bool _coinStatus, bool _mintStatus, bool _revealed) external onlyOwner {
    MintList[1].Paused = _publicSaleStatus;
    MintList[2].Paused = _presaleStatus;
    MintList[3].Paused = _presaleStatus;
    MintList[4].Paused = _coinStatus;
    mintStatus = _mintStatus;
    isRevealed = _revealed;
}

function setTeamData(address[] calldata _teamAddressList, uint256[] calldata _shareList) external onlyOwner {
    require(!teamListDone, "The team data already filled..");
    delete TeamList;
    delete ShareList;
    for(uint256 i = 0;i < _teamAddressList.length;i++)
    {
        TeamList.push(_teamAddressList[i]);
        ShareList.push(_shareList[i]);
    }
    teamListDone = true;
}

function GoldListMint(bytes32[] memory proof, uint256 amount) external payable onlySender nonReentrant {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(!MintList[3].Paused, "Goldlist mint is paused");
    require(isAddressGoldlisted(proof,leaf),"You are not eligible for a gold list mint");
    require(msg.value >= MintList[3].Price * amount, "Value is not correct");
    require(GoldListMintHistory[msg.sender] + amount <= MintList[3].Max,"Minting amount exceeds allowance per wallet");
    require(MintList[3].Supply >= amount, "Gold list mint is sold out");

    MintList[3].Supply = MintList[3].Supply - amount;
    GoldListMintHistory[msg.sender] += amount;
    _revMint(msg.sender, amount);
}

function WhiteListMint(bytes32[] memory proof, uint256 amount) external payable onlySender nonReentrant {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(!MintList[2].Paused, "Goldlist mint is paused");
    require(isAddressWhitelisted(proof,leaf),"You are not eligible for a whitelist mint");
    require(msg.value >= MintList[2].Price * amount , "Value is not correct");
    require(WhiteListMintHistory[msg.sender] + amount <= MintList[2].Max,"Minting amount exceeds allowance per wallet");
    require(MintList[2].Supply >= amount, "Whitelist mint is sold out");

    MintList[2].Supply = MintList[2].Supply - amount;
    WhiteListMintHistory[msg.sender] += amount;
    _revMint(msg.sender, amount);
}


function publicMint(uint256 amount) external payable onlySender nonReentrant {
    require(msg.value >= MintList[1].Price * amount , "Value is not correct");
    require(!MintList[1].Paused, "Public mint is paused");
    require(MintHistory[msg.sender] + amount <= MintList[1].Max,"Minting amount exceeds allowance per wallet");

    MintList[1].Supply = MintList[1].Supply - amount;
    MintHistory[msg.sender] += amount;
    _revMint(msg.sender, amount);
}

function revCoinMint(uint256 amount) external payable onlySender nonReentrant{
    require(revCoinContract.balanceOf(msg.sender) * amount >= MintList[4].Price * amount, "Not enought coin for mint");
    require(!MintList[4].Paused, "Coin mint is paused");
    require(CoinMintHistory[msg.sender] + amount <= MintList[4].Max,"Minting amount exceeds allowance per wallet");

    revCoinContract.transferFrom(_msgSender(), address(revCoinContract),  MintList[4].Price * amount);
    MintList[4].Supply = MintList[4].Supply - amount;
    CoinMintHistory[msg.sender] += amount;
    _revMint(msg.sender, amount);
}


function withdraw() public onlyOwner nonReentrant
{
    require(mintStatus,"Invalid status for withdraw");
    uint256 total = address(this).balance;
    for(uint256 i = 0;i<TeamList.length;i++)
    {
        uint256 share = total * ShareList[i] / 100;
        (bool success, ) = payable(TeamList[i]).call{value: share}("");
        require(success, "Transfer failed..");
    }
}


function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
}

function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
}

function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory)
{
    if(isRevealed)
    {
    return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId),".json"));
    }
    else
    {
    return  string(_baseTokenURI);
    }
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

