// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./console.sol";

/**
 * FELINOIDS
 *
 * For crazy cats who play the rules.
 * Foreign Agent On Working Staycation.
 * Not every letter is a symbol...
 *
 */
contract Felinoids is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;

    uint256 constant MAXIMUM_SUPPLY = 10000;
    uint256 constant MAX_NFT_MINT = 5;
    uint256 constant DEFAULT_PRICE_WEI = 50000000000000000; // 0.05 ETH
    uint256 constant DEFAULT_DOTDOTDOT_PRICE_WEI = 43600000000000000; // 0.0436 ETH
    address constant MAINNET_DOTDOTDOT_ADDRESS = 0xcE25E60A89F200B1fA40f6c313047FFe386992c3;

    bool public mintActive = false;
    uint256 public mintPriceWei = DEFAULT_PRICE_WEI;
    uint256 public dotdotdotMintPriceWei = DEFAULT_DOTDOTDOT_PRICE_WEI;

    IERC721 public dotdotdot;

    string private felinoidBaseURI;
    mapping(uint256 => string) tokenURIOverrides;

    event Mint(address to, uint256 tokenId);

    //
    // INIT
    //
    constructor() ERC721("Felinoids", "FOID") {
        dotdotdot = IERC721(MAINNET_DOTDOTDOT_ADDRESS);
    }

    function setDotdotdotAddrress(address _dotdotdotAddress) public onlyOwner {
        dotdotdot = IERC721(_dotdotdotAddress);
    }

    //
    // CONFIG
    //

    function setMintPriceWei(uint256 _mintPriceWei) public onlyOwner {
        mintPriceWei = _mintPriceWei;
    }

    function setDotDotDotMintPriceWei(uint256 _dotdotdotMintPriceWei) public onlyOwner {
        dotdotdotMintPriceWei = _dotdotdotMintPriceWei;
    }

    ///
    /// MINT
    ///

    function toggleMintActive() public onlyOwner {
        mintActive = !mintActive;
    }

    /**
     * Multi Mint
     */
    function mint(uint256 numberOfTokensMax5) public payable nonReentrant {
        require(mintActive, "Felinoid: Mint is not active");
        require(numberOfTokensMax5 > 0, "Felinoids: Number of tokens can not be less than or equal to 0");
        require(numberOfTokensMax5 <= MAX_NFT_MINT, "Felinoids: Can only mint up to 5 per purchase");
        require(totalSupply() + numberOfTokensMax5 <= MAXIMUM_SUPPLY, "Felinoids: Purchase would exceed max supply");
        require(msg.value >= (mintPriceWei * numberOfTokensMax5), "Felinoids: Invalid price");
        for (uint256 i = 0; i < numberOfTokensMax5; i++) {
            uint256 nextTokenId = totalSupply();
            _safeMint(msg.sender, nextTokenId);
            emit Mint(msg.sender, nextTokenId);
        }
    }

    /**
     * Mint with Dotdotdot
     * @notice Allow a dotdotdot token holder to mint a token
     */
    function mintWithDotdotdot() public payable nonReentrant {
        require(mintActive, "Felinoid: Mint is not active");
        require(totalSupply() < MAXIMUM_SUPPLY, "Felinoids: Purchase would exceed max supply");
        require(msg.value >= dotdotdotMintPriceWei, "Felinoids: Invalid price");
        require(dotdotdot.balanceOf(msg.sender) > 0, "Felinoids: Balance of dotdotdot not > 0");
        uint256 nextTokenId = totalSupply();
        _safeMint(msg.sender, nextTokenId);
        emit Mint(msg.sender, nextTokenId);
    }

    function reserve(uint256 num) public onlyOwner {
        require(num > 0, "Felinoids: Number of tokens can not be less than or equal to 0");
        require(num <= 10, "Felinoids: Can only mint up to 10 per reserve");
        for (uint256 i = 0; i < num; i++) {
            uint256 nextTokenId = totalSupply();
            _safeMint(msg.sender, nextTokenId);
            emit Mint(msg.sender, nextTokenId);
        }
    }

    //
    // VIEW
    //

    function _baseURI() internal view virtual override returns (string memory) {
        return felinoidBaseURI;
    }

    // Sets base URI for all tokens, only able to be called by contract owner
    function setBaseURI(string memory baseURI_) external onlyOwner {
        felinoidBaseURI = baseURI_;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        // If _tokenURIOverrides[tokenId] is set, return it
        string memory tokenURIOverride = tokenURIOverrides[_tokenId];
        if (bytes(tokenURIOverride).length > 0) {
            return tokenURIOverride;
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        string memory base = _baseURI();
        return string(abi.encodePacked(base, _tokenId.toString()));
    }

    //
    // WITHDRAW
    //
    /**
     * @notice Allows owner to withdraw amount
     */
    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // fallback functions
    fallback() external payable {}

    receive() external payable {}
}
