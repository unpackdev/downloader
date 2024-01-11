// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

/// @title YAUGA
/// @author Burn0ut#8868 hello@notableart.io
/// @notice https://yauga.io/ https://twitter.com/yauga_wellbeing
contract YAUGA is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 5000;
    uint256 public constant MAX_PER_MINT = 20;
    address public constant w1 = 0xfcb5D24D1b9361f8040ADD02616ec839E7F06CC4;
    address public constant w2 = 0x8deddE67889F0Bb474E094165A4BA37872A7c26B;

    uint256 public price = 0.11 ether;
    bool public isRevealed = false;
    bool public publicSaleStarted = false;
    bool public presaleStarted = false;
    mapping(address => uint256) private _presaleMints;
    uint256 public presaleMaxPerWallet = 6;

    string public baseURI = "";
    bytes32 public merkleRoot = 0x8791a922a93dee51680d6d3315d9edbcb4aa1d5bd725ecb079e5d33175c7aed1;

    constructor() ERC721A("YAUGA", "YAUGA", 20) {
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
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice * (1 ether);
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (isRevealed) {
            return super.tokenURI(tokenId);
        } else {
            return
                string(abi.encodePacked("ipfs://QmTG29ZG1LMuGWXfZ8GzsG1DdktV9WuKzYMFF8WquAWV9v/", tokenId.toString()));
        }
    }

    /// Set number of maximum presale mints a wallet can have
    /// @param _newPresaleMaxPerWallet value to set
    function setPresaleMaxPerWallet(uint256 _newPresaleMaxPerWallet) external onlyOwner {
        presaleMaxPerWallet = _newPresaleMaxPerWallet;
    }

    /// Presale mint function
    /// @param tokens number of tokens to mint
    /// @param merkleProof Merkle Tree proof
    /// @dev reverts if any of the presale preconditions aren't satisfied
    function mintPresale(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(presaleStarted, "YAUGA: Presale has not started");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "YAUGA: You are not eligible for the presale");
        require(_presaleMints[_msgSender()] + tokens <= presaleMaxPerWallet, "YAUGA: Presale limit for this wallet reached");
        require(tokens <= MAX_PER_MINT, "YAUGA: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "YAUGA: Minting would exceed max supply");
        require(tokens > 0, "YAUGA: Must mint at least one token");
        require(price * tokens == msg.value, "YAUGA: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
        _presaleMints[_msgSender()] += tokens;
    }

    /// Public Sale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "YAUGA: Public sale has not started");
        require(tokens <= MAX_PER_MINT, "YAUGA: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "YAUGA: Minting would exceed max supply");
        require(tokens > 0, "YAUGA: Must mint at least one token");
        require(price * tokens == msg.value, "YAUGA: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    /// Owner only mint function
    /// Does not require eth
    /// @param to address of the recepient
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the preconditions aren't satisfied
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_TOKENS, "YAUGA: Minting would exceed max supply");
        require(tokens > 0, "YAUGA: Must mint at least one token");

        _safeMint(to, tokens);
    }

    /// Distribute funds to wallets
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "YAUGA: Insufficent balance");
        _widthdraw(w2, ((balance * 20) / 100));
        _widthdraw(w1, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "YAUGA: Failed to widthdraw Ether");
    }

}
