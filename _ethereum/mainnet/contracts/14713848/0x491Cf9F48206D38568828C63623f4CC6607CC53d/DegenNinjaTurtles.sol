// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract DegenNinjaTurtles is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 5555;
    uint256 public discountMints = 2000;
    uint256 public price = 0.042 ether;
    uint256 public presalePrice = 0.024 ether;

    address public constant w1 = 0x0342A2973D3184fF47C52E2a70399A462FF26D68;
    address public constant w2 = 0x463aE947f2cf7ec7816aF8B2274d943b6774d989;
    address public constant w3 = 0x22F68242149f30c0932B28227aCD3048dE048E25;
    address public constant w4 = 0x4A8dCD0c0eD6E3f278215a3079cE9477eC9685d0;

    bool public publicSaleStarted = false;
    bool public presaleStarted = true;

    string public baseURI = "";
    bytes32 public merkleRoot = 0x3e11ca738c914d3a54e535c09543e1ca9d8718cb71793c157c79034de8c2bcf7;

    constructor() ERC721A("Degen Ninja Turtles", "DNT") {
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice * (1 ether);
    }

    function setPresalePrice(uint256 _newPrice) external onlyOwner {
        presalePrice = _newPrice * (1 ether);
    }

    function setDiscountMints(uint256 _newDiscountMints) external onlyOwner {
        discountMints = _newDiscountMints;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

    function mintPresale(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(presaleStarted, "Presale has not started");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not eligible to mint");
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(presalePrice * tokens <= msg.value, "ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "Public sale has not started");
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        if (totalSupply() > discountMints) {
            require(price * tokens <= msg.value, "ETH amount is incorrect");
        }
        require(presalePrice * tokens <= msg.value, "ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(w1, ((balance * 30) / 100));
        _withdraw(w2, ((balance * 30) / 100));
        _withdraw(w3, ((balance * 25) / 100));
        _withdraw(w4, ((balance * 15) / 100));
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}