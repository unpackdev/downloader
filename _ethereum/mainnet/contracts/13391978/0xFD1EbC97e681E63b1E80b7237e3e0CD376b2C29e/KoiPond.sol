pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract KoiPond is ERC721, Ownable {
    uint public constant MAX_KOIS = 5000;
    uint public constant MAX_KOIS_PER_TX = 20;
    uint public constant MAX_CLAIMABLE = 3;
    uint256 public PRICE = .02 ether;

    string _baseURL = "";
    string _contractURL = "";

    bool public paused;
    bool public claimPaused;

    bool private mintedPerfect;

    uint256[] kois;
    address[] claimableAddrs;
    mapping(address => bool) claimed;

    constructor() ERC721("EtherKois", "EKS") {
        paused = true;
        claimPaused = true;
        mintedPerfect = false;

        kois.push(0);  // token IDs will start at 1.
        claimableAddrs.push(0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6);
        claimableAddrs.push(0x364C828eE171616a39897688A831c2499aD972ec);
        claimableAddrs.push(0x4f89Cd0CAE1e54D98db6a80150a824a533502EEa);
    }

    function makeKoi(address to) internal {
        uint256 dna = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, kois[kois.length - 1]))) % 100000000000000;
        kois.push(dna);
        _safeMint(to, kois.length - 1);
    }

    function reserve(uint256 amount) onlyOwner external {
        require(amount <= MAX_KOIS_PER_TX, "Too many kois at once");
        require(this.totalSupply() + amount <= MAX_KOIS, "Would exceed max supply");

        for (uint i = 0; i < amount; i++) {
            makeKoi(msg.sender);
        }
    }

    function goFish(uint amount) public payable {
        require(!paused, "Fishing is Paused");
        require(amount <= MAX_KOIS_PER_TX, "Too many kois at once");
        require(this.totalSupply() + amount <= MAX_KOIS, "Would exceed max supply");
        require(msg.value == PRICE * amount, "Incorrect ETH amount");

        for (uint i = 0; i < amount; i++) {
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

    function getClaimableAddresses() public view returns (address[] memory){
        return claimableAddrs;
    }

    function addClaimableAddress(address _addr) external onlyOwner {
        claimableAddrs.push(_addr);
    }

    function claim() external {
        require(!claimed[msg.sender], "already claimed");
        require(!claimPaused, "claiming is paused");
        uint claimable = 0;
        for (uint i = 0; i < claimableAddrs.length; i++) {
            IERC721 erc721 = IERC721(claimableAddrs[i]);
            claimable += erc721.balanceOf(msg.sender);
            if (claimable > MAX_CLAIMABLE) {
                claimable = MAX_CLAIMABLE;
                break;
            }
        }
        require(claimable > 0, "nothing to claim");
        require(this.totalSupply() + claimable <= MAX_KOIS, "Would exceed max supply");

        for (uint i = 0; i < claimable; i++) {
            makeKoi(msg.sender);
        }
        claimed[msg.sender] = true;
    }

    function toggleClaimable() external onlyOwner {
        claimPaused = !claimPaused;
    }

    function reservePerfectKois() external onlyOwner {
        require(!mintedPerfect, "perfect already minted");

        kois.push(11111111111111);  // Traditional
        _safeMint(msg.sender, kois.length - 1);
        kois.push(69696969696969);  //Dragon
        _safeMint(msg.sender, kois.length - 1);
        kois.push(77777777777777);  // Holographic
        _safeMint(msg.sender, kois.length - 1);
        kois.push(80808080808080);  // Fire
        _safeMint(msg.sender, kois.length - 1);
        kois.push(88888888888888);  // Sunset
        _safeMint(msg.sender, kois.length - 1);
        kois.push(95959595959595);  // Space
        _safeMint(msg.sender, kois.length - 1);
        kois.push(98989898989898);  // Ether
        _safeMint(msg.sender, kois.length - 1);
        kois.push(99999999999999);  // Cyborg
        _safeMint(msg.sender, kois.length - 1);

        mintedPerfect = true;
    }
}
