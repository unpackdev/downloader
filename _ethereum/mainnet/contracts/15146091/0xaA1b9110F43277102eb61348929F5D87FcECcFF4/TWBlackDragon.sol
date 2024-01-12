// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract TWBlackDragon is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 220;
    uint256 public constant MAX_WHITE_MINT = 1;
    address public constant ownerAddress = 0xd8872A493e4d6136c9cef1aBB599B3E6a83633d6;

    bool public isRevealed = false;
    bool public whitelistStarted = false;
    mapping(address => uint256) private _whitelistMints;
    uint256 public whitelistMaxPerWallet = 1;

    string public baseURI = "";
    string public unrevealURI = "https://4everland.io/ipfs/Qmdhgym9rUbrD7JitMwiRx9qWeV3QfizduFSSbJzk9M8NT";
    bytes32 public merkleRoot = 0x32255a70aca274386bfceedc767f30b45b85c8f6aac8d13cea27819a11b2f903;

    constructor() ERC721A("TW BlackDragon", "TWBD", 100) {
    }

    function toggleWhitelistStarted() external onlyOwner {
        whitelistStarted = !whitelistStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setUnrevealURI(string memory _newUnrevealURI) external onlyOwner {
        unrevealURI = _newUnrevealURI;
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
            return unrevealURI;
        }
    }

    function setWhitelistMaxPerWallet(uint256 _newWhitelistMaxPerWallet) external onlyOwner {
        whitelistMaxPerWallet = _newWhitelistMaxPerWallet;
    }

    function mintWhitelist(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(whitelistStarted, "Whitelist sale has not started");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not eligible for the whitelist sale");
        require(_whitelistMints[_msgSender()] + tokens <= whitelistMaxPerWallet, "Whitelist sale limit for this wallet reached");
        require(tokens <= MAX_WHITE_MINT, "Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");

        _safeMint(_msgSender(), tokens);
        _whitelistMints[_msgSender()] += tokens;
    }

    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_TOKENS, "Minting would exceed max supply");
        require(tokens > 0, "Must mint at least one token");

        _safeMint(to, tokens);
    }

    function devMint(address[] calldata _addr, uint256[] calldata amount) external onlyOwner{
		uint256 i;
		uint256 addrLen = _addr.length;
		uint256 batchTotal = 0;
        for (i = 0; i < addrLen;){
            batchTotal += amount[i];
			unchecked{ ++i;}
		}
		require(totalSupply() + batchTotal <= MAX_TOKENS, "Reached max supply");
		for (i = 0; i < addrLen;){
			if(amount[i] >0) _safeMint(_addr[i], amount[i]);
			unchecked{ ++i;}
		}
	}

    /// Distribute funds to wallets
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(ownerAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to widthdraw Ether");
    }

}

