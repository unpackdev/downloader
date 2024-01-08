pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract KoiPond is ERC721, Ownable {
    uint public constant MAX_KOIS = 5000;
    uint public constant MAX_KOIS_PER_TX = 20;
    uint256 public PRICE = .02 ether;

    string _baseURL = "";
    string _contractURL = "";

    bool public paused;

    uint256[] kois;

    constructor() ERC721("EtherKois", "EKS") {
        paused = true;
        // token IDs will start at 1.
        kois.push(10000000000);
    }

    function makeKoi(address to) internal {
        uint256 dna = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, kois[kois.length - 1]))) % 100000000000000;
        kois.push(dna);
        _safeMint(to, kois.length - 1);
    }

    function reserve(uint256 amount) onlyOwner external {
        require(amount <= MAX_KOIS_PER_TX, "Too many kois at once");
        require(this.totalSupply() + amount <= MAX_KOIS, "Would exceed max supply");

        for(uint i = 0; i < amount; i++) {
            makeKoi(msg.sender);
        }
    }

    function goFish(uint amount) public payable {
        require(!paused, "Fishing is Paused");
        require(amount <= MAX_KOIS_PER_TX, "Too many kois at once");
        require(this.totalSupply() + amount <= MAX_KOIS, "Would exceed max supply");
        require(msg.value == PRICE * amount, "Incorrect ETH amount");

        for(uint i = 0; i < amount; i++) {
            makeKoi(msg.sender);
        }
    }

    function togglePaused() external onlyOwner {
        paused = !paused;
    }

    function getKoi(uint256 tokenID) external view returns (uint256) {
        return kois[tokenID];
    }

    function contractURI() external view returns (string memory) {
        return _contractURL;
    }

    function setContractURL(string memory _url) external onlyOwner {
        _contractURL = _url;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function setBaseUri(string memory _uri) external onlyOwner {
        _baseURL = _uri;
    }

    function totalSupply() external view returns (uint256) {
        return kois.length - 1;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function deposit(uint256 amount) payable public {
        require(msg.value == amount);
    }

    function withdraw() onlyOwner public {
        address payable p = payable(owner());
        p.transfer(getBalance());
    }
}
