// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./Allowlist.sol";

/// @custom:security-contact security@therelix.xyz
contract AllowlistedNFT is ERC721, ERC721Enumerable, Ownable, Allowlist {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    bool private mintPaused = false;
    mapping(address => bool) private tokenPurchased;
    string private currentBaseURI;
    string private URISuffix = ".json";

    constructor(
        string memory name_,
        string memory symbol_,
        string memory initBaseURI
    ) ERC721(name_, symbol_) {
        currentBaseURI = initBaseURI;
    }

    /**
     * Internal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return currentBaseURI;
    }

    /**
     * Public
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

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
                    abi.encodePacked(baseURI, "tokens/", Strings.toString(tokenId), URISuffix)
                )
                : "";
    }

    function safeMint(bytes32[] calldata proof) external {
        require(!mintPaused, "Minting Paused");
        require(!tokenPurchased[msg.sender], "Can only mint one");
        require(isAllowlisted(msg.sender, proof), "Not allowlisted");

        tokenPurchased[msg.sender] = true;

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    /**
     * Only Owner
     */
    /// @notice Should end with a `/` (slash)
    function setBaseURI(string memory _uri) external onlyOwner {
        currentBaseURI = _uri;
    }

    function setURISuffix(string memory _suffix) external onlyOwner {
        URISuffix = _suffix;
    }

    function toggleMintPaused() external onlyOwner {
        mintPaused = !mintPaused;
    }

    function withdraw() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }
}
