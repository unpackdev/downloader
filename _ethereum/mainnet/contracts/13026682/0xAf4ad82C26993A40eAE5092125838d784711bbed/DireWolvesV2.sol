pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

interface IDirewolvesContract {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract DireWolvesV2 is Ownable, ERC721, ERC721Enumerable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    uint256 public constant MAX_MINT_QTY = 20;
    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant ADD_CLAIM_PERIOD = 31 days;
    address public constant DIREWOLVES_ORIGINAL_CONTRACT = 0x8A5a8dAEaDC99eA86cFfED5f65feCd34228dF388;
    IDirewolvesContract public oldContract;

    Counters.Counter private _supplyCounter;
    uint256 public maxDireWolves = 7777;
    uint256 public originalWolfCount;
    bool public live = false;
    bool public claimable = false;
    string public baseTokenURI;
    uint256 public deployTimeStamp;
    mapping(uint256 => bool) claimed;
    
    constructor() ERC721("DireWolvesV2", "DIREWOLF-V2") {
        baseTokenURI = "https://ipfs.io/ipfs/QmeGbAQAzPHKchETVuaaVwMiaKUc9QFvZHxYKFzD716T3P/";
        deployTimeStamp = block.timestamp;
        oldContract = IDirewolvesContract(DIREWOLVES_ORIGINAL_CONTRACT);
        
        _mint(owner(), 2353);
        _mint(owner(), 3742);
        _mint(owner(), 3791);
        _mint(owner(), 5192);
        _mint(owner(), 6990);
    }
    
    modifier allowPurchase {
        require(getCurrentSupply() <= maxDireWolves, "The Sale Has Been Completed");
        require(live, "Sale Paused");
        
        _;
    }
    
    modifier allowClaim {
        require(claimable, "Claiming is disabled");
        
        _;
    }
    
    function setOriginalWolfCount(uint256 supply) external onlyOwner {
        originalWolfCount = supply;
    } 
    
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdraw Failed");
    }
    
    function claimOldWolf() public allowClaim  {
        require(block.timestamp <= deployTimeStamp.add(ADD_CLAIM_PERIOD), "Claiming Expired");
        
        uint256 balanceOfOwner = oldContract.balanceOf(msg.sender);
        require(balanceOfOwner != 0, "You don't own any original Wolves");
        
        for (uint256 i = 0; i < balanceOfOwner; i++) {
            uint256 tokenId = oldContract.tokenOfOwnerByIndex(msg.sender, i);
            
             if(claimed[tokenId] == true || tokenId > originalWolfCount) {
                 continue;
             }
            
             claimed[tokenId] = true;
             _mint(msg.sender, tokenId);
        }
    }
    
    function mint(uint256 qty) public payable allowPurchase {
        require(qty <= MAX_MINT_QTY, "Greater than MAX_MINT_QTY");
        require(qty.add(getCurrentSupply()) <= maxDireWolves, "Would exceed total supply");
        require(msg.value >= qty.mul(PRICE), "Not Enough ETH");
        require(getCurrentSupply() <= maxDireWolves, "Sale Over");
        
        for (uint256 i = 0; i < qty; i++) {
            _mintWolf(msg.sender);
        }
    }
    
    function toggle() public onlyOwner {
        live = !live;
    }
    
    function toggleClaiming() public onlyOwner {
        claimable = !claimable;
    }
    
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseTokenURI = newBaseURI;
    }
    
    function setMaxSupply(uint256 newSupply) public onlyOwner {
        require(newSupply <= maxDireWolves && newSupply >= totalSupply(), "Cannot create more supply, only less");
        maxDireWolves = newSupply;
    }
    
    function getCurrentSupply() internal view returns (uint256) {
        return _supplyCounter.current().add(originalWolfCount);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function _mintWolf(address to) private {
        _supplyCounter.increment();
        _mint(to, getCurrentSupply());
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}