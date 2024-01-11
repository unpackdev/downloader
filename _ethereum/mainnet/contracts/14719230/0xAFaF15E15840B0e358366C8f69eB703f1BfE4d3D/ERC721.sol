// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

contract Angora is Ownable, ERC721Enumerable {
    using SafeMath for uint256;

    bool public ALLOW_MINTING = false;
    uint256 public MAX_MINTS = 1000;
    address public MARKETING_WALLET;

    uint256 private _mintPrice = 0.12 ether;
    string private _baseTokenURI = "";

    constructor(address _marketingWallet) ERC721("Angora", "ANGOS") {
        MARKETING_WALLET = _marketingWallet;
    }

    /**
     * Check if minting is enabled
     */
    modifier isMintable(uint256 count) {
        if (msg.sender != owner()) {
            require(ALLOW_MINTING, "Minting is disabled");
        }
        require(totalSupply().add(count) <= MAX_MINTS, "Maximum number of tokens have been minted");
        _;
    }

    /**
     * Return base url of ipfs endpoint
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Set base url for ipfs endpoint
     */
    function setBaseURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    /**
     * Get current minting price
     */
    function mintPrice() public view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply < 250) {
            return _mintPrice.div(100).mul(25);
        }
        if (supply < 500) {
            return _mintPrice.div(100).mul(50);
        }
        if (supply < 750) {
            return _mintPrice.div(100).mul(75);
        }
        return _mintPrice;
    }

    /**
     * Update mint price
     */
    function setMintPrice(uint256 amountEtherWei) external onlyOwner {
        _mintPrice = amountEtherWei;
    }

    /**
     * Update marketing wallet
     */
    function setMarketingWallet(address wallet) external onlyOwner {
        MARKETING_WALLET = wallet;
    }

    /**
     * Withdraw collected ether from mints
     */
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Failed to withdraw ether");
    }

    /**
     * Enable or disable minting
     */
    function switchMintStatus() external onlyOwner {
        ALLOW_MINTING = !ALLOW_MINTING;
    }

    /**
     * Add new collections for minting
     */
    function increaseMaxMints(uint256 count) external onlyOwner {
        MAX_MINTS += count;
        require(MAX_MINTS <= 2500, "Total mints exceeds allowance");
    }

    /**
     * Send next token to a user
     */
    function airdropRandom(address to, uint256 count) external onlyOwner isMintable(count) {
        for (uint256 index = 0; index < count; index++) {
            _safeMint(to, totalSupply().add(1));
        }
    }

    /**
     * Mint tokens at next index
     */
    function mint(uint256 count) public payable isMintable(count) {
        require(msg.value >= mintPrice().mul(count), "Ether value sent is lower than expected");
        for (uint256 index = 0; index < count; index++) {
            _safeMint(msg.sender, totalSupply().add(1));
        }

        // Send ether to marketing wallet
        (bool success, ) = MARKETING_WALLET.call{ value: msg.value }("");
        require(success, "Failed to send payment");
    }

    /**
     * List all tokens of a certain wallet
     */
    function tokensOfOwner(address wallet) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(wallet);
        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 index = 0; index < tokenCount; index++) {
            result[index] = tokenOfOwnerByIndex(wallet, index);
        }
        return result;
    }
}
