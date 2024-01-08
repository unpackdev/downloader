pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract FunkyMonkeys is ERC721, Ownable, ERC721Enumerable {

    uint public constant MAX_TOKENS = 1000;
    string public baseURI = "";
    bool public saleIsActive = false;

    // Public ETH address of the Rainforest Foundation US
    // Directly from: https://rainforestfoundation.org/donate/cryptocurrency/
    address public constant rainforestCharity = 0x54334Ebc8c9ef04bc28D614Caa557143ED8AfC87;

    // Creator 2 of project
    address public constant creator2 = 0xaF9C4391D3459c8b06429BC0a1717c7C362D125C;

    constructor() ERC721("Funky Monkeys", "MONKEYS") {
        reserveSomeForGiveaways(25);
    }

    // Get an array of tokenIds owned by a given address
    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0); // Return an empty array
        } else {
            uint[] memory result = new uint[](tokenCount);
            for (uint i = 0; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    // Adopt 1-20 monkeys
    function adoptMonkeys(uint adoptAmount) public payable {
        require(saleIsActive, "Sale is currently paused");
        require(totalSupply() < MAX_TOKENS, "Sale has ended");
        require(adoptAmount > 0 && adoptAmount <= 20, "You can adopt minimum 1, maximum 20 at a time");
        require(totalSupply() + adoptAmount <= MAX_TOKENS, "Exceeds MAX_TOKENS");
        require(msg.value >= determineCurrentPrice() * adoptAmount, "Ether value sent is below the price");

        // Mint the specified amount of tokens for this sender
        for (uint i = 0; i < adoptAmount; i++) {
            uint newTokenId = totalSupply();
            _safeMint(msg.sender, newTokenId);
        }
    }

    // Calculate price for the next token to mint
    function determineCurrentPrice() public view returns (uint) {
        return determinePriceForToken(totalSupply());
    }
    function determinePriceForToken(uint _id) public pure returns (uint) {
        require(_id < MAX_TOKENS, "Supplied token ID exceeds MAX_TOKENS");

        if (_id >= 950) {
            return 1 ether; //    950-1000:  1.00 ETH
        } else if (_id >= 800) {
            return 0.64 ether; // 800-950:   0.64 ETH
        } else if (_id >= 650) {
            return 0.32 ether; // 650-800:   0.32 ETH
        } else if (_id >= 450) {
            return 0.16 ether; // 450-650:   0.16 ETH
        } else if (_id >= 250) {
            return 0.08 ether; // 250-450:   0.08 ETH
        } else if (_id >= 50) {
            return 0.04 ether; // 50-250:    0.04 ETH
        } else {
            return 0.02 ether; // 0 - 50     0.02 ETH
        }
    }

    // Reserve some for giveaways & people who helped this project!
    function reserveSomeForGiveaways(uint amount) internal {
        uint currentSupply = totalSupply();
        for (uint i = 0; i < amount; i++) {
            _safeMint(owner(), currentSupply + i);
        }
    }

    // For setting base URI (for reveals)
    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Funcs that need to be overridden (FWD calls to super)
    function _beforeTokenTransfer(address from, address to, uint tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Start and pause the sale
    function startSale() public onlyOwner {
        saleIsActive = true;
    }
    function pauseSale() public onlyOwner {
        saleIsActive = false;
    }

    // Distribute eth to the charity and contract owners
    function withdrawAll() public payable onlyOwner {
        uint charityAmt = address(this).balance / 2; // 50% to charity
        uint foundersAmt = address(this).balance / 4; // 25% to each creator
        require(            
            payable(rainforestCharity).send(charityAmt)
            && payable(creator2).send(foundersAmt)
            && payable(owner()).send(foundersAmt)
            , "Failed to withdraw balance of contract"
        );
    }
}