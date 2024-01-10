// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract KongMfers is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_PER_PUBLIC_MINT;
    uint256 public PRICE = 0.01 ether;
    uint256 public MAX_SUPPLY = 8888;
    bool public SALE_STARTED = false;

    mapping(address => uint256) public allowlist;

    string public baseURI = "";

    constructor(uint256 maxPerPublicMint) ERC721A("kong Mfers", "KONGMFERS", maxPerPublicMint) {
        MAX_PER_PUBLIC_MINT = maxPerPublicMint;
    }

    function seedAllowlist(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
        require(addresses.length == numSlots.length, "addresses does not match numSlots length");
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }

    function togglePublicSaleStarted() external onlyOwner {
        SALE_STARTED = !SALE_STARTED;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        PRICE = _newPrice * (1 ether);
    }

    function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
	    MAX_SUPPLY = _newMaxSupply;
	}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

    /// Public Sale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(SALE_STARTED, "Sale has not started yet.");
        require(tokens <= MAX_PER_PUBLIC_MINT, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_SUPPLY, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(PRICE * tokens <= msg.value, "ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);

        refundIfOver(tokens * PRICE);
    }

    /// freelist mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the freelist sale preconditions aren't satisfied
    function freelistMint(uint256 tokens) external {
        require(SALE_STARTED, "Sale has not started yet.");
        require(totalSupply() + tokens <= MAX_SUPPLY, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(allowlist[msg.sender] >= tokens, "Cannot mint more than alloted quota");

        _safeMint(_msgSender(), tokens);

        allowlist[msg.sender] -= tokens;
    }

    /// Owner only mint function
    /// Does not require eth
    /// @param to address of the recepient
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the preconditions aren't satisfied
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_SUPPLY, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");

        _safeMint(to, tokens);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        _withdraw(msg.sender, balance);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdrawAmount(address to, uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        require(amount <= balance, "Insufficient balance");
        _withdraw(to, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}