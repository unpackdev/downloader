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

    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 public constant MAX_MINTS = 9;

    string public baseURI;

    bool public mintingEnabled = true;

    uint256 public startPresaleDate = 1642438800; // January 17, 9 am PST

    uint256 public endPresaleDate = 1642525199; // January 18, 8:59:59 am PST

    uint256 public startPublicMintDate = 1642525200; // January 18, 9 am PST

    uint256 public constant MAX_PRESALE_MINTS = 3;

    address public presaleSigner;

    string public constant R =
        "We are Nervous. Are you? Let us help you with your next NFT Project -> dylan@nervous.net";

    constructor(
        string memory name,
        string memory symbol,
        string memory _initBaseURI,
        uint256 _maxSupply,
        address _presaleSigner,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721Sequential(name, symbol) PaymentSplitter(payees, shares) {
        baseURI = _initBaseURI;
        maxSupply = _maxSupply;
        presaleSigner = _presaleSigner;
    }

    /* Minting */

    function toggleMinting() public onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function mint(uint256 numTokens, bytes memory pass)
        public
        payable
        nonReentrant
    {
        require(mintingEnabled, "Minting isn't enabled");
        require(totalMinted() + numTokens <= maxSupply, "Sold Out");
        require(
            numTokens > 0 && numTokens <= MAX_MINTS,
            "Machine can dispense a minimum of 1, maximum of 9 tokens"
        );
        require(
            msg.value >= numTokens * MINT_PRICE,
            "Insufficient Payment: Amount of Ether sent is not correct."
        );

        if (hasPreSaleStarted()) {
            require(
                isTicketEligibleForPresale(pass),
                "Ticket not valid for presale"
            );
            uint256 mintablePresale = calculateMintablePresale(pass);
            require(numTokens <= mintablePresale, "Minting Too Many Presale");
            useTicket(pass, numTokens);
        } else {
            require(hasPublicSaleStarted(), "Sale hasn't started");
        }

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    function calculateMintablePresale(bytes memory _pass)
        internal
        view
        returns (uint256)
    {
        uint256 maxMintForPresale = MAX_PRESALE_MINTS;
        require(usedTickets[_pass] < maxMintForPresale, "Ticket already used");
        return maxMintForPresale - usedTickets[_pass];
    }

    /* Ticket Handling */

    // Thanks for 0x420 and their solid implementation of tickets in the OG:DG drop.

    function getHash() internal view returns (bytes32) {
        return keccak256(abi.encodePacked("NERVOUS", msg.sender));
    }

    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function isTicketEligibleForPresale(bytes memory pass)
        internal
        view
        returns (bool)
    {
        bytes32 hash = getHash();
        address signer = recover(hash, pass);
        if (signer == presaleSigner) {
            return true;
        } else {
            return false;
        }
    }

    function useTicket(bytes memory pass, uint256 quantity) internal {
        usedTickets[pass] += quantity;
    }

    /* Sale state */

    function hasPublicSaleStarted() public view returns (bool) {
        if (startPublicMintDate <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function hasPreSaleStarted() public view returns (bool) {
        if (
            startPresaleDate <= block.timestamp &&
            endPresaleDate >= block.timestamp
        ) {
            return true;
        } else {
            return false;
        }
    }

    /* set the dates */
    function setPresaleDate(uint256 _startPresaleDate, uint256 _endPresaleDate)
        external
        onlyOwner
    {
        startPresaleDate = _startPresaleDate;
        endPresaleDate = _endPresaleDate;
    }

    function setPublicSaleDate(uint256 _startPublicMintDate)
        external
        onlyOwner
    {
        startPublicMintDate = _startPublicMintDate;
    }

    /* set signers */
    function setPresaleSigner(address _presaleSigner) external onlyOwner {
        presaleSigner = _presaleSigner;
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
