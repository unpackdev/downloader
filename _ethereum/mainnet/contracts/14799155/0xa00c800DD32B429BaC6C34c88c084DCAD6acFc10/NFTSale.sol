// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./IERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

/// @title NFT Sale
contract NFTSale is ERC721A, Pausable, Ownable {
    string private currentBaseURI;
    bool private baseURILock = false;
    string private URISuffix = ".json";
    uint256 private constant maxPerWallet = 20;
    uint256 private constant maxSupply = 10000;
    uint256 private constant price = 0.02 ether;
    IERC721 private constant notOkBears = IERC721(0x76B3AF5F0f9B89CA5a4f9fe6C58421dbE567062d);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        currentBaseURI = _initBaseURI;
    }

    /**
     * Internal
     */
    function _baseURI() internal view override returns (string memory) {
        return currentBaseURI;
    }

    /**
     * Public
     */
    /// @notice URI format: `<base URI>contract<URISuffix>`
    function contractURI() external view returns (string memory) {
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "contract", URISuffix))
                : "";
    }

    /// @notice URI format: `<base URI>tokens/<token ID><URISuffix>`
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, "tokens", URISuffix)
                )
                : "";
    }

    ///@notice Fuck BrokenSea
    function mint(uint256 quantity) external payable whenNotPaused {
        uint256 cost = price * quantity;

        // Check user's balance of this against maxPerWallet
        require(_numberMinted(msg.sender) + quantity <= maxPerWallet, "Too many fucks given.");

        // Check against maxSupply
        require(totalSupply() + quantity <= maxSupply, "No fucks left.");

        // Free if you're a NotOkBear holder!
        if (notOkBears.balanceOf(msg.sender) > 1) {
            cost = 0;
        }

        require(msg.value >= cost, "Send more eth.");

        _mint(msg.sender, quantity);
    }

    /**
     * Only Owner
     */
    /// @notice Watchdog: Lock #setBaseURI()
    function lockBaseURI() external onlyOwner {
        require(!baseURILock, "Already locked");
        baseURILock = true;
    }

    function ownerBatchMint(uint256 amt) external onlyOwner {
        require(totalSupply() + amt < maxSupply + 1, "Too many!");

        _mint(msg.sender, amt);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        require(!baseURILock, "Locked");
        currentBaseURI = _uri;
    }

    function setURISuffix(string memory _suffix) external onlyOwner {
        URISuffix = _suffix;
    }

    function withdraw() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }
}
