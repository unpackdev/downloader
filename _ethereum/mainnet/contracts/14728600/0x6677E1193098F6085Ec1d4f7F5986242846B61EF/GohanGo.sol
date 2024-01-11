//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@&&##BBGGGBB##&@@@@@@@@@@@@@@&&##BGY5P5PGBBB##&&@@@@@@@@@@@@@&##BBGGGBB##&&@@@@@@@@@@@@@
@@@@@@@@@&&BGP555PPPPPPP555PGB&@@@@@&#BGP5555P5Y5P5PPPPP5555PG#&&@@@@&BGP555PPPPPPP555PGB&&@@@@@@@@@
@@@@@@@&BP55PG##&&&@@&&&&##GP55PB##GP55PGB#&&&&&&@@@@@@&&##BGP55PB#BP55PG##&&&&@@&&&##GP55PB&@@@@@@@
@@@@@&B5YPB#&@@@@@@@@@@@@@@@&&BPYYYPG#&@@@@@@@@@@@@@@@@@@@@@@&#BPYYYPB&&@@@@@@@@@@@@@@@&#BPY5B&@@@@@
@@@&#PYPB&@@@@@@@@@@@@@@@@@@@@@&#B#&@@@####@@@@@@@@@@@@@&#B#&@@@&#G#&@@@@@@@@@@@@@@@@@@@@@&BPYP#&@@@
@@&#PYG#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5???JJB@@@@@@@@@@GJJ???P@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#GYP#&@@
@@#PYG#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B5YYY5#@@@@&&&@@@BYYYY5#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GYP#@@
@&BYP#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#G#@@@BGBBBBGG&@@BG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#PYB&@
@#PJG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#P#@@@PGBB#BBP#@@BP&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GJP#@
&#5YB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#####&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BY5#&
@#PJG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GJP#@
@&BJP#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#PJB&@
@&#PJG#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GJP#&@
@@&#5YG#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GY5#&@@
@@@&#PYP#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#PYP#&@@@
@@@@@&G5YPB&@@@@@@@@@@@@@@@@@@&#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#&&@@@@@@@@@@@@@@@@@&BPY5G&@@@@@
@@@@@@&#G5Y5GB#&&@@@@@@@@@&#BG5Y5PB#&@@@@@@@@@@@@@@@@@@@@@@@@@@&#BPYY5PB#&@@@@@@@@@&&#BG5Y5G#&@@@@@@
@@@@@@@@@&#GP555PGGGGBGGGP555PGBBG55PGB#&@@@@@@@@@@@@@@@@@@&&#GP55PGBGP555PGGGBGGGGP555PG#&@@@@@@@@@
@@@@@@@@@@@@&&#BGPPPPPPPGGB#&&@@@@&#BP555PGGB####&&&&###BGPP55PGB#&@@@&&#BGGPPPPPPPGB#&&@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@&&#BGPPP555555555PPPGB#&&@@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&#####&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 */
// @author Dbgkinggg
contract GohanGo is ERC721A, Ownable {
    using Strings for uint256;

    /** ====== Define Constants ====== */
    uint256 public constant WHITELIST_NUM = 1234;
    // team preserve + community preserve + another bowl activity
    uint256 public constant RESERVE_NUM = 300;
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_PER_WALLET = 6;
    string public constant baseExtension = ".json";

    uint256 public publicPrice = 0.02 ether;
    uint256 public whitelistCount;
    uint256 public reserveCount;

    bool public whitelistActive = false;
    bool public publicSaleActive = false;
    string private baseURI;
    string private unrevealURI =
        "ipfs://QmSvq7Wm9xqq6wBysXbYJW67TgkqSfMV7zW4HHYiEn9bkA";
    bool public revealed;

    mapping(address => uint256) public whitelist;

    constructor() ERC721A("GohanGo", "GOHANGO") {}

    error WhitelistNotActive();
    error TokenNotExsited();
    error ExceedWhitelistNum();
    error PublicSaleNotActive();
    error NotWhitelisted();
    error MintAmountIncorrect();
    error WrongPaymentAmount();
    error ExceedPreserveAmount();
    error MintFromContractNotAllowed();

    modifier isWhitelistActive() {
        if (!whitelistActive) revert WhitelistNotActive();
        _;
    }

    modifier senderIsHuman() {
        if (tx.origin != msg.sender) {
            revert MintFromContractNotAllowed();
        }
        _;
    }

    /** ====== View Functions ====== */
    /**
     * @notice token URI
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert TokenNotExsited();
        if (revealed) {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        _tokenId.toString(),
                        baseExtension
                    )
                );
        } else {
            return unrevealURI;
        }
    }

    function howManyBowlOfRice() public view returns (uint256) {
        return whitelist[msg.sender];
    }

    /** ====== External Write Functions ====== */

    /**
     * @notice whitelist mint => ALL FREE MINT
     */
    function whitelistMint(uint256 _quantity)
        external
        payable
        senderIsHuman
        isWhitelistActive
    {
        if (whitelistCount + _quantity > WHITELIST_NUM)
            revert ExceedWhitelistNum();

        uint256 mintableAmount = whitelist[msg.sender];

        if (mintableAmount == 0) revert NotWhitelisted();
        if (_quantity > mintableAmount) revert MintAmountIncorrect();

        if (_quantity == mintableAmount) {
            delete whitelist[msg.sender];
        } else {
            whitelist[msg.sender] = mintableAmount - _quantity;
        }

        whitelistCount = whitelistCount + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice function for public sale
     * @dev happen after presale
     */
    function mintMyGohan(uint256 _quantity) public payable senderIsHuman {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (_quantity > MAX_PER_WALLET) revert MintAmountIncorrect();

        uint256 cost = _quantity * publicPrice;
        if (msg.value < cost) revert WrongPaymentAmount();

        uint256 reserveRemaining = RESERVE_NUM - reserveCount;
        if (totalSupply() + _quantity + reserveRemaining > MAX_SUPPLY)
            revert MintAmountIncorrect();
        _safeMint(msg.sender, _quantity);
    }

    /** ====== Only Owner ====== */
    /**
     * @notice This is used for team preserve mint and airdrop
     * @dev It should not exceed the team preserve number
     */
    function mintForAddresses(address[] calldata addresses, uint256 _quantity)
        external
        onlyOwner
    {
        uint256 total = 0;
        for (uint256 i; i < addresses.length; i++) {
            _safeMint(addresses[i], _quantity);
            total += _quantity;
        }

        reserveCount += total;
        if (reserveCount > RESERVE_NUM) revert ExceedPreserveAmount();
    }

    /**
     * @notice toggle whitelist sale state
     */
    function toggleWhitelist() external onlyOwner {
        whitelistActive = !whitelistActive;
    }

    /**
     * @notice toggle public sale state
     */
    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    /**
     * @notice toggle public sale and presale state together
     */
    function openPublicAndStopPresale() external onlyOwner {
        publicSaleActive = true;
        whitelistActive = false;
    }

    /**
     * @notice set baseURI and toggle the reveal flag (if needed)
     */
    function setBaseURI(string calldata _baseURI, bool reveal)
        external
        onlyOwner
    {
        if (!revealed && reveal) {
            revealed = reveal;
        }

        baseURI = _baseURI;
    }

    /**
     * @notice set the unreal URI in case we need to change it
     */
    function setUnRevealURI(string calldata _unrevealURI) external onlyOwner {
        unrevealURI = _unrevealURI;
    }

    /**
     * @notice toggle reveal state
     */
    function toggleReveal() external onlyOwner {
        revealed = !revealed;
    }

    /**
     * @notice add addresses to whitelist (with quantity)
     */
    function addToWhitelist(address[] calldata addresses, uint256 quantity)
        external
        onlyOwner
    {
        for (uint256 i; i < addresses.length; i++) {
            whitelist[addresses[i]] = quantity;
        }
    }

    /**
     * @notice delete addresses from whitelist
     * @dev this won't be used most likely
     */
    function deleteFromWhitelist(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i; i < addresses.length; i++) {
            delete whitelist[addresses[i]];
        }
    }

    /**
     * @notice withdraw all funds so that I can buy myself more and more bubble tea xD
     */
    function withdrawAllFunds(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }

    /**
     * @notice withdraw funds so that I can buy myself a bubble tea xD
     */
    function withdrawFunds(address payable to, uint256 amount)
        external
        onlyOwner
    {
        require(amount <= address(this).balance, "Amount incorrect");
        to.transfer(amount);
    }
}
