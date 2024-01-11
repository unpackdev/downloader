//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

/*
    website: https://cannypixelsclub.web.app/
    first 500 free then .003 each
*/
contract UncannyPixelClub is ERC721A, Ownable {
    using Strings for uint256;

    // Public constants
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public constant MAX_PER_WALLET = 15;
    uint256 public constant PRICE = 0.003 ether;
    mapping(address => uint256) public balances;

    string private unRevealedBaseURI = "ipfs://bafybeigxgbw4gxhoxh3esxww4r2p5yx7vvh7bzzcc2gyzo5yxv3seebxzm/placeholder.json";
    string private baseURI = "";
    bool public revealed = false;

    constructor() ERC721A("Uncanny Pixel Club", "UPC") {}

    /// @notice Mint a new Pixel. Minting 5 will give you a bonus NFT for free
    /// @param quantity The number of NFT's you want to mint, must be less than MAX_PER_WALLET
    function mint(uint256 quantity) external payable {
        require(
            balances[msg.sender] + quantity <= MAX_PER_WALLET,
            "You already have the maximum number of PHOSTs in your account."
        ); // Ensure the sender doesn't already have the maximum number of Pixels minted
        require(quantity + _totalMinted() <= MAX_SUPPLY, "Too many Phosts"); // Ensure that this mint will not exceed the maximum supply

        if (_totalMinted() + quantity > 500) {
            require(
                msg.value >= quantity * PRICE,
                "You don't have enough ether to mint this many PHOSTs."
            ); // Ensure that the sender has enough ether to pay for the transaction
        }
        balances[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice Get the metadata of a Pixel
    /// @param tokenId The token ID number.
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return revealed ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : unRevealedBaseURI;
    }

    function setUnrevealedURI(string memory unRevealedBaseURI_) external onlyOwner {
        unRevealedBaseURI = unRevealedBaseURI_;
    }
    
    function setRevealedURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        revealed = true;
    }

    // Withdraws the balance of the contract
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
