// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract MTRKS_Token is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using SafeMath for uint256;

    uint256 public constant publicMintPrice = 0.01 ether;
    // Set max values to desired value + 1. Avoiding '<=' checks at minting for gas savings

    uint256 public constant MAX_SUPPLY = 8889; // max supply + 1 for gas optimization
    uint256 public constant MAX_FREE_SUPPLY = 101; // max tokens available to presale members. Amount +1 for gas optimization
    uint256 public constant TEAM_SUPPLY = 101; // For team, marketing, and giveaways. Amount +1 for gas optimization
    uint256 public MAX_FREE_PER_WALLET = 5; // max per tx
    uint256 public MAX_PER_TX = 26; // max per tx + 1 for gas optimization
    uint256 public teamMintedCount = 0;
    uint256 public freeMintRemaining = MAX_FREE_SUPPLY - 1;
    mapping(address => uint256) public freeMintCountMap;
    // Sale Controls
    // Storing as uint256 to reduce gas on boolean conversions since checked during every mint
    uint256 private constant _IS_ACTIVE = 1;
    uint256 private constant _IS_NOT_ACTIVE = 2;
    uint256 public publicSaleActive = _IS_NOT_ACTIVE;
    bool public isRevealed = false;

    // URIs
    string public baseURI;
    string private _collectionURI;

    address public immutable proxyRegistryAddress; // OpenSea proxy registry address - set at deploy time

    // Team Withdrawl Addresses
    address public address1 = 0x44Bdc363575fc1c2F6fD9d12d8B3C9C00Ab73F0c; // User1
    address public address2 = 0x00AF8dcCa82CCA4e93F9c317C4c1abECC9F21C1f; // User2

    mapping(address => bool) proxyToApproved;

    constructor(
        string memory _initialBaseURI,
        string memory collectionURI,
        address _proxyRegistryAddress
    ) ERC721A("Monster Trucks", "MTRKS") {
        proxyRegistryAddress = _proxyRegistryAddress;
        setBaseURI(_initialBaseURI);
        setCollectionURI(collectionURI);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            address(proxyRegistry.proxies(owner)) == operator ||
            proxyToApproved[operator]
        ) return true;
        return super.isApprovedForAll(owner, operator);
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setRevealedStatus(bool _status) public onlyOwner {
        isRevealed = _status;
    }

    /**
     * @dev set collection URI for marketplace display
     */
    function setCollectionURI(string memory collectionURI)
        public
        virtual
        onlyOwner
    {
        _collectionURI = collectionURI;
    }

    // Future proxy additions
    function flipProxyState(address proxyAddress) public onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

    // ================ Withdraw Functions ================ //

    /**
     * @dev withdraw funds to the owner account
     */
    function withdrawToOwner() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev withdraw funds to the team accounts
     */
    function withdrawToTeam() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(address1, balance.mul(50).div(100)); // 50% to address1
        _widthdraw(address2, balance.mul(50).div(100)); // 50% to address2
        _widthdraw(msg.sender, address(this).balance); // Any balance to the owner address
    }

    // Private Function -- Only Accesible By Contract
    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // Sets the public sale status. true = Active, false = Not Active. Stores as uint256 values: 1(Active) or 2(Not Active)
    // Also ends presale when public sale is active
    // Storing status as uint256 to reduct gas on boolean conversions during lookup for every mint, but providing this conversion for human owner interaction
    function setPublicSaleStatus(bool value) public onlyOwner {
        if (value == true) {
            publicSaleActive = _IS_ACTIVE;
        } else {
            publicSaleActive = _IS_NOT_ACTIVE;
        }
    }

    function updateFreeMintCount(address minter, uint256 count) private {
        freeMintCountMap[minter] += count;
    }

    // ================ Minting Check Modifiers ================ //
    /**
     * @dev validates that the correct payment has been sent to match the number of tokens requested
     */
    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    /**
     * @dev validates that the address can still mint free tokens
     */
    modifier canMintFree(address minter, uint256 numberOfTokens) {
        require(
            freeMintRemaining - numberOfTokens >= 0,
            "Free token supply exhausted"
        );
        require(
            (numberOfTokens > 0) &&
                (freeMintCountMap[minter] + numberOfTokens) <=
                MAX_FREE_PER_WALLET,
            "Free tokens per addr exceeded"
        );

        _;
    }
    /**
     * @dev validates that public minting is enabled, tokens per tx is not exceeded, and tokens are available
     */
    modifier canMintPublic(uint256 numberOfTokens) {
        require(publicSaleActive == _IS_ACTIVE, "Public sale not live");
        require(
            numberOfTokens > 0 && numberOfTokens < MAX_PER_TX,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + numberOfTokens < MAX_SUPPLY,
            "Not enough tokens remaining to mint"
        );
        _;
    }

    // ================ Minting Functions ================ //

    function publicMint(uint256 amount)
        external
        payable
        isCorrectPayment(publicMintPrice, amount)
        canMintPublic(amount)
        nonReentrant
    {
        require(msg.sender == tx.origin, "EOA only");
        _safeMint(msg.sender, amount);
    }

    function freeMint(uint256 amount)
        external
        canMintFree(msg.sender, amount)
        canMintPublic(amount)
        nonReentrant
    {
        require(msg.sender == tx.origin, "EOA only");
        updateFreeMintCount(msg.sender, amount);
        freeMintRemaining -= amount;
        _safeMint(msg.sender, amount);
    }

    // Allows contract own to mint up to TEAM_SUPPLY tokens for an address without charge, only pay gas fees
    // Used for team holdings, giveaways, and marketing supply
    function TeamMint(address _mintFor, uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        require(msg.sender == tx.origin, "EOA only");
        require(teamMintedCount + amount < TEAM_SUPPLY);
        _safeMint(_mintFor, amount);
        teamMintedCount += amount;
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")
            );
    }

    /**
     * @dev collection URI for marketplace display
     */
    function contractURI() public view returns (string memory) {
        return _collectionURI;
    }
}
