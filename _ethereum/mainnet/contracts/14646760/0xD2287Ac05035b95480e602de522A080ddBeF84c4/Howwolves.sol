// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract HowlWolves is ERC721A, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 7000;
    uint256 public constant MAX_PER_MINT = 3;
    address public walletAddress = 0xFCb31b17eaB846e337138eA8964B76A5f02E71e0;

    uint256 public presalePrice = 0.08 ether;
    uint256 public publicSalePrice = 0.1 ether;
    bool public isRevealed = false;
    bool public publicSaleStarted = false;
    bool public presaleStarted = false;
    mapping(address => uint256) private _presaleMints;
    uint256 public presaleMaxPerWallet = 10;

    uint256 public presaleStartTime;

    string public baseURI = "";
    string public revealURI = "";
    
    bytes32 public merkleRoot;

    constructor() ERC721A("Howling Werewolves", "WOLVES", 20) {
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
        presaleStartTime = block.timestamp;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function getTokenPrice() public view returns (uint256) {
        if(publicSaleStarted == true) {
            return publicSalePrice;
        }
        else {
            return presalePrice;
        }
    }

    function setPresalePrice(uint256 newPrice) external onlyOwner {
        presalePrice = newPrice;
    }

    function setPublicPrice(uint256 newPrice) external onlyOwner {
        publicSalePrice = newPrice;
    }

    function setTeamWalletAddress(address addr) public onlyOwner {
        walletAddress = addr;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
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
            if(bytes(revealURI).length > 0) {
                return
                    string(abi.encodePacked(revealURI, "symbol.json"));
            }
            return "";
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
        require(presaleStarted, "Presale has not started");
        require((block.timestamp - presaleStartTime) < 3 days, "Presale has stopped");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not eligible for the presale");
        require(_presaleMints[_msgSender()] + tokens <= presaleMaxPerWallet, "Presale limit for this wallet reached");
        require(tokens <= MAX_PER_MINT, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(presalePrice * tokens == msg.value, "ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
        _presaleMints[_msgSender()] += tokens;
    }

    /// Public Sale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "Public sale has not started");
		require(tx.origin == msg.sender, "Contract is not allowed to mint.");
        require(tokens <= MAX_PER_MINT, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");
        require(publicSalePrice * tokens == msg.value, "ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    /// Distribute funds to wallets
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");

        _widthdraw(walletAddress, balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to widthdraw Ether");
    }
}