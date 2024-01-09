pragma solidity 0.8.9;

import "ERC721.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";

contract Octavate is ERC721, Ownable, ReentrancyGuard{

    uint256 public constant PRICE = 0.075 * 1e18; //0.075 ETH
    uint256 public constant MAX_SUPPLY = 10000;

    address public constant withdrawAddress = 0xB465492375116682F11628E4c0a07BD0e2E78C26;

    uint256 minted;

    string public baseTokenURI;

    mapping(address => uint8) public earlyAccess;

    bool public live = false;

    constructor(string memory baseURI) public ERC721("OctavateNFT","OCT")
    {
        setBaseURI(baseURI);
    }

    function setEarlyAccess(address[] calldata addresses, uint8[] calldata max_mint) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            earlyAccess[addresses[i]] = max_mint[i];
        }
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseTokenURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function withdraw() public {
        payable(withdrawAddress).transfer(address(this).balance);
    }

    function mint(uint8 amount) public payable nonReentrant {
        require(amount > 0, "Amount must be more than 0");
        require(amount <= 5, "Amount must be 5 or less");
        require(tx.origin == msg.sender,"Purchase cannot be called from another contract");
        require(msg.value == PRICE * amount, "Ether value sent is not correct");
        require(minted + amount <= MAX_SUPPLY, "Sold out! You can purchase our NFTs on OpenSea.");

        if (!live) {
            uint8 earlyAccessbalance = earlyAccess[msg.sender];
            require(
                earlyAccessbalance > 0,
                "Invalid presale balance - Public sale not live"
            );
            require(
                earlyAccessbalance >= amount,
                "Amount more than your presale limit"
            );
            earlyAccess[msg.sender] -= amount;
        }

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, ++minted);
        }        
    }
    function toggleLive() public onlyOwner {
        live = !live;
    }
    function devmint(uint8 amount) public onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, ++minted);
        }  
    }
}