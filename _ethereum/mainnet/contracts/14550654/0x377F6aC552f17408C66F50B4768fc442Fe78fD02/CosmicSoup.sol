// contracts/CosmicSoup.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A_CS.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./PullPayment.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

// Based on ERC721A v3.1.0 https://www.erc721a.org, https://github.com/chiru-labs/ERC721A
contract COSMICSOUP is ERC721A_CS, Ownable, Pausable, PullPayment, ReentrancyGuard {
    using Strings for uint256;
    uint256 public constant MAX_MINT = 3; // Maximum number of tokens per transaction
    uint256 public constant MAX_CUSTOM = 16; // Maximum number of custom tokens
    uint256 public tokensTotal  = 158; // Number of total tokens
    uint256 public tokensLaunch = 142; // Number of launch tokens
    uint256 public tokensBase   = 118; // Number of base tokens
    uint256 public walletMax    = 12;  // Maximum number of tokens per wallet (should be a multiple of MAX_MINT)
    // Mint price for 1 token  (0.010 ether, 1 ether = 10^18 wei)
    // Mint price for 2 tokens (0.018 ether, 10% discount)
    // Mint price for 3 tokens (0.024 ether, 20% discount)
    uint256[MAX_MINT] public mintPrice = [10000000 gwei, 18000000 gwei, 24000000 gwei];
    string[MAX_CUSTOM] public tokenUriCustom; // URIs for the custom tokens
    string public tokenUriLaunch; // URI for the launch tokens
    string public tokenUriHidden; // URI for the pre-reveal place holder
    bool public collectionHidden = true; // If the collection is hidden

    constructor() ERC721A_CS("Cosmic Soup", "COSMICSOUP") {
        _pause();
        for (uint256 i = 0; i < MAX_CUSTOM; i++) {
            tokenUriCustom[i] = "";
        }
        tokenUriLaunch = "";
        tokenUriHidden = "ar://Pl4jJ32OLi3ETD3dN78F6jR2mDqcJiogFD-VAOF1ISg/hidden.json";
    }

    // Mint tokens (user)
    function mintUser(uint256 quantity) external payable whenNotPaused nonReentrant {
        unchecked { require(quantity > 0 && quantity <= MAX_MINT, 'ERC721A_CS: invalid quantity'); }
        unchecked { require(totalSupply() + quantity <= tokensBase, 'ERC721A_CS: supply exceeded'); }
        unchecked { require(_numberMinted(msg.sender) + quantity <= walletMax, 'ERC721A_CS: wallet limit exceeded'); }
        require(msg.sender == tx.origin, 'ERC721A_CS: caller is another contract');
        require(msg.value >= mintPrice[quantity-1], 'ERC721A_CS: insufficient funds');
        _safeMint(msg.sender, quantity);
        _asyncTransfer(owner(), msg.value);
    }

    // Number of burned tokens
    function numberBurned(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }

    // Number of minted tokens
    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    // Number of minted tokens in total
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    // Token URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721A_CS: URI query for nonexistent token');
        if (collectionHidden == true) {
            return tokenUriHidden;
        }
        string memory baseURI = tokenId > tokensLaunch ? tokenUriCustom[tokenId-tokensLaunch-1] : tokenUriLaunch;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    // Initial tokenId set to 1 (tokenId = 1->tokensTotal)
    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    // <--<--<--<--<--<--<--<--<-- OnlyOwner -->-->-->-->-->-->-->-->-->-->
    // Mint tokens (owner)
    function mintOwner(address to, uint256 tokenId) external onlyOwner nonReentrant {
        require(tokenId > tokensBase && tokenId <= tokensTotal, 'ERC721A_CS: token ID out of range');
        require(!_exists(tokenId), 'ERC721A_CS: token already minted');
        require(msg.sender == tx.origin, 'ERC721A_CS: caller is another contract');
        _mintOwner(to, tokenId);
    }

    // Burn tokens
    function burnToken(uint256 tokenId) external onlyOwner nonReentrant {
        require(_exists(tokenId), 'ERC721A_CS: cannot burn nonexistent token');
        require(msg.sender == tx.origin, 'ERC721A_CS: caller is another contract');
        _burn(tokenId);
    }

    // Total number of tokens
    function setNumTokensTotal(uint256 newSize) external onlyOwner {
        tokensTotal = newSize;
    }

    // Number of launch tokens
    function setNumTokensLaunch(uint256 newSize) external onlyOwner {
        tokensLaunch = newSize;
    }

    // Number of base tokens
    function setNumTokensBase(uint256 newSize) external onlyOwner {
        tokensBase = newSize;
    }

    // Mint price for tokens, price in wei (1 ether = 10^18 wei = 10^9 GWei)
    function setMintPrice(uint256 quantity, uint256 newPriceWei) external onlyOwner {
        unchecked { require(quantity > 0 && quantity <= MAX_MINT, 'ERC721A_CS: invalid quantity'); }
        mintPrice[quantity-1] = newPriceWei;
    }

    // Maximum number of tokens per wallet (should be a multiple of MAX_MINT)
    function setWalletMax(uint256 newWalletMax) external onlyOwner {
        walletMax = newWalletMax;
    }

    // URIs for the custom tokens [customId = 0->15]
    function setTokenUriCustom(uint256 customId, string memory newURI) external onlyOwner {
        unchecked { require(customId < MAX_CUSTOM, 'ERC721A_CS: invalid customId'); }
        tokenUriCustom[customId] = newURI;
    }

    // URI for the launch tokens
    function setTokenUriLaunch(string memory newURI) external onlyOwner {
        tokenUriLaunch = newURI;
    }

    // URI for the pre-reveal place holder
    function setTokenUriHidden(string memory newURI) external onlyOwner {
        tokenUriHidden = newURI;
    }

    // Hide the collection
    function setCollectionHide() external onlyOwner {
        collectionHidden = true;
    }

    // Show the collection
    function setCollectionShow() external onlyOwner {
        collectionHidden = false;
    }

    // Pause the contract
    function setContractPause() external onlyOwner {
        _pause();
    }

    // Unpause the contract
    function setContractUnpause() external onlyOwner {
        _unpause();
    }

    // Withdraw funds
    function withdrawPayments(address payable payee) public virtual override onlyOwner nonReentrant {
        super.withdrawPayments(payee);
    }
}
