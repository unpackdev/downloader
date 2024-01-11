// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721S.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./PaymentSplitter.sol";

contract NervousNFT is
    ERC721Sequential,
    ReentrancyGuard,
    PaymentSplitter,
    Ownable
{
    using Strings for uint256;
    using ECDSA for bytes32;
    mapping(bytes => uint256) private usedTickets;

    uint256 public immutable maxSupply;

    uint256 public constant MINT_PRICE = 0.05 ether;
    uint256 public constant MAX_MINTS = 10;

    string public baseURI;

    bool public mintingEnabled = true;

    uint256 public startPublicMintDate = 1654880400; // Fri Jun 10 2022 12:00:00 GMT-0500 (Central Daylight Time)

    string public constant R =
        "We are Nervous. Are you? Let us help you with your next NFT Project -> dylan@nervous.net";

    constructor(
        string memory name,
        string memory symbol,
        string memory _initBaseURI,
        uint256 _maxSupply,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721Sequential(name, symbol) PaymentSplitter(payees, shares) {
        baseURI = _initBaseURI;
        maxSupply = _maxSupply;
    }

    /* Minting */

    function toggleMinting() public onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function mint(uint256 numTokens)
        public
        payable
        nonReentrant
    {
        require(mintingEnabled, "Minting isn't enabled");
        require(totalMinted() + numTokens <= maxSupply, "Sold Out");
        require(
            numTokens > 0 && numTokens <= MAX_MINTS,
            "Machine can dispense a minimum of 1, maximum of 10 tokens"
        );
        require(
            msg.value >= numTokens * MINT_PRICE,
            "Insufficient Payment: Amount of Ether sent is not correct."
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    /* Sale state */

    function hasPublicSaleStarted() public view returns (bool) {
        if (startPublicMintDate <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function setPublicSaleDate(uint256 _startPublicMintDate)
        external
        onlyOwner
    {
        startPublicMintDate = _startPublicMintDate;
    }

    // /* Magic */
    function magicMint(uint256 numTokens) external onlyOwner {
        require(
            totalMinted() + numTokens <= maxSupply,
            "Exceeds maximum token supply."
        );

        require(
            numTokens > 0 && numTokens <= 100,
            "Machine can dispense a minimum of 1, maximum of 100 tokens"
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    function magicGift(address[] calldata receivers) external onlyOwner {
        uint256 numTokens = receivers.length;
        require(
            totalMinted() + numTokens <= maxSupply,
            "Exceeds maximum token supply."
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(receivers[i]);
        }
    }

    /* Utility */

    /* URL Utility */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    /* eth handlers */

    function withdraw(address payable account) public virtual {
        release(account);
    }

    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }
}
