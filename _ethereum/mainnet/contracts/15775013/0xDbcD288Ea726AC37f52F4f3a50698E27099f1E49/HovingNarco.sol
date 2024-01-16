// SPDX-License-Identifier: GPL-3.0

/*
    Hoving Narco NFT | CC0
*/

pragma solidity 0.8.7;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract HovingNarco is ERC721A {
    uint256 public immutable maxSupply = 333;
    address public owner;
    uint256 _price = 0.0033 ether;
    uint256 _maxPerTx = 3;
    uint256 _maxFree;


    function mint(uint256 amount) payable public {
        require(totalSupply() + 1 <= maxSupply, "Sold Out");
        require(amount <= _maxPerTx);
        uint256 cost = amount * _price;
        require(msg.value >= cost, "Pay For");
        _safeMint(msg.sender, amount);
    }

    function mint() public {
        require(msg.sender == tx.origin, "EOA");
        require(totalSupply() + 1 <= _maxFree, "No Free");
        require(balanceOf(msg.sender) == 0, "Only One");
        _safeMint(msg.sender, 1);
    }
    
    modifier onlyOwner {
        require(owner == msg.sender, "No Permission");
        _;
    }

    constructor() ERC721A("Hoving Narco", "HNC") {
        owner = msg.sender;
        _price = 0.0033 ether;
        _maxFree = 110;
    }

    function changePrice(uint256 mprice) external onlyOwner {
        _price = mprice;
    }

    function changeMaxFree(uint256 mfree) external onlyOwner {
        _maxFree = mfree;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked("ipfs://QmaDrBwDyYzZyZjuqWLCotuoHV548bWVAvuHjzK3HdDn3h/", _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

