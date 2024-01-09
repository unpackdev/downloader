// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract RenegadeRabbits is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 6969;
    uint256 public constant MAX_PER_MINT = 15;
    address public constant w1 = 0xC5dC0325e6a0e9fB6DBD30B211D9BCB7faD0F1f9; // dev
    address public constant w2 = 0x66e5B3d4158228230DA11e20fa85aF9F41a0ac90; // founder

    uint256 public price = 0.069 ether;
    uint256 public presalePrice = 0.05 ether;
    uint256 public presaleMaxPerWallet = 2;
    bool public publicSaleStarted = false;
    bool public presaleStarted = false;
    mapping(address => uint256) private _presaleMints;

    string public baseURI = "";
    bytes32 public merkleRoot = 0xfbaa96a1f7806c1ab06f957c8fc6e60875b6880254f77b71439c7854a6b47755;

    constructor() ERC721A("Renegade Rabbits", "RR", 15) {
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

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
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
        require(presaleStarted, "RR: Presale has not started");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "RR: You are not eligible for the presale");
        require(_presaleMints[_msgSender()] + tokens <= presaleMaxPerWallet, "RR: Presale limit for this wallet reached");
        require(tokens <= MAX_PER_MINT, "RR: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "RR: Minting would exceed max supply");
        require(tokens > 0, "RR: Must mint at least one token");
        require(presalePrice * tokens <= msg.value, "RR: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
        _presaleMints[_msgSender()] += tokens;
    }

    /// Public Sale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "RR: Public sale has not started");
        require(tokens <= MAX_PER_MINT, "RR: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "RR: Minting would exceed max supply");
        require(tokens > 0, "RR: Must mint at least one token");
        require(price * tokens <= msg.value, "RR: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    /// Owner only mint function
    /// Does not require eth
    /// @param to address of the recepient
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the preconditions aren't satisfied
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_TOKENS, "RR: Minting would exceed max supply");
        require(tokens > 0, "RR: Must mint at least one token");

        _safeMint(to, tokens);
    }

    /// Distribute funds to wallets
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "RR: Insufficent balance");
        _withdraw(w1, ((balance * 15) / 100));
        _withdraw(w2, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "RR: Failed to withdraw Ether");
    }
}