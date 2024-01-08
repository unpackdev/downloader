pragma solidity ^0.7.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./ERC165.sol";
import "./ERC721.sol";

contract DirewolvesContract is Ownable, ERC165, ERC721 {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // private variables
    Counters.Counter private _wolfCounter;
    string private _ipfsURI = "https://ipfs.io/ipfs/";

    // public constant
    uint256 public constant MAX_WOLVES = 7777;

    // is the sale open?
    bool public forSale = false;
    // permanent lock for immutability set after sale is completed and provenance is set
    bool public isLocked = false;
    // ipfs folder
    string public ipfsFolder = "";
    // provenance hash
    string public provenance = "";
    // provenance uri
    string public provenanceURI = "";

    constructor() ERC721("Direwolves", "DIREWOLF") {

    }

    modifier notLocked() {
        require(!isLocked, "Contract has been locked");
        _;
    }

    function mintNewWolf(uint256 qty) public payable {
        require(forSale, "Wolves are not for sale yet");
        require(qty > 0, "Minting quantity requires to be at least one wolf");
        require(qty <= 20, "Order cannot purchase more than 20 wolves at once");
        require(qty < MAX_WOLVES, "Only 7777 wolves exist");
        
        if (qty.add(totalSupply()) > MAX_WOLVES) {
            qty = MAX_WOLVES.sub(totalSupply());
        }

        uint256 price = calculatePurchasePrice(qty);
        require(msg.value >= price, "Insufficient ETH sent to complete purchase");

        for(uint256 x = 0; x < qty; x++) {
            _mintNewWolf(msg.sender);
        }
    }
    
    function calculatePurchasePrice(uint256 qty) public pure returns (uint256) {
        require(qty <= MAX_WOLVES);
        return qty.mul(0.05 ether);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId > 0 && tokenId <= totalSupply(), "Cannot query URI for non-existant token");

        return string(abi.encodePacked(_ipfsURI, ipfsFolder, "/", tokenId.toString()));
    }

    // onlyOwner methods
    function startSale() external onlyOwner {
        forSale = true;
    }

    function lock() external onlyOwner {
        isLocked = true;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner notLocked {
        _setBaseURI(_baseURI);
    }

    function setIpfsUri(string memory _newIpfsURI) external onlyOwner notLocked {
        _ipfsURI = _newIpfsURI;
    }

    function setIpfsFolder(string memory _ipfsFolder) external onlyOwner notLocked {
        ipfsFolder = _ipfsFolder;
    }

    function setProvenanceURI(string memory _provenanceURI) external onlyOwner notLocked {
        provenanceURI = _provenanceURI;
    }

    function setProvenance(string memory _provenance) external onlyOwner notLocked {
        provenance = _provenance;
    }
    
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    // private methods
    function _mintNewWolf(address customer) private {
        _wolfCounter.increment();
        uint256 newWolfId = _wolfCounter.current();
        _mint(customer, newWolfId);
    }
}