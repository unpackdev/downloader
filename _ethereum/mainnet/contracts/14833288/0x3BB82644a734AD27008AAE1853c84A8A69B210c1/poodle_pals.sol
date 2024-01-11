// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC165.sol";
import "./ERC2981Base.sol";
import "./ERC721A.sol";

contract PoodlePals is
    Ownable,
    ReentrancyGuard,
    ERC721A,
    ERC2981Base
{
    uint256 public maxTokens = 1111; // total tokens that can be minted

    uint256 public PRICE = 0.02 ether;

    uint256 public maxMint = 20; // max that can be minted during pre or pub sale

    uint256 public amountForDevs = 100; // for marketing etc

    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _allowListClaimed;

    // counters
    mapping(address => uint8) public _preSaleListCounter;
    mapping(address => uint8) public _pubSaleListCounter;

    // Contract Data
    string private _baseTokenURI;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981Base, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /* Royalty EIP-2981 */
    RoyaltyInfo private _royalties;

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(address recipient, uint256 value) public onlyOwner {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }

    constructor() ERC721A("Poodle Pals", "POODLPAL") {
    }

    // Sale Switches
    bool public preMintActive = false;
    bool public pubMintActive = false;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /* Sale Switches */
    function setPreMint(bool state) public onlyOwner {
        preMintActive = state;
    }

    function setPubMint(bool state) public onlyOwner {
        pubMintActive = state;
    }

    /* Allowlist Management */
    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _allowList[addresses[i]] = true;

            /**
            * @dev We don't want to reset _allowListClaimed count
            * if we try to add someone more than once.
            */
            _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
        }
    }

    function allowListClaimedBy(address owner) external view returns (uint256){
        require(owner != address(0), "Zero address not on Allow List");

        return _allowListClaimed[owner];
    }

    function onAllowList(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    function removeFromAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            /// @dev We don't want to reset possible _allowListClaimed numbers.
            _allowList[addresses[i]] = false;
        }
    }

    /* Setters */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMaxMint(uint256 quantity) external onlyOwner {
        maxMint = quantity;
    }

    function setMaxTokens(uint256 quantity) external onlyOwner {
        maxTokens = quantity;
    }

    /* Getters */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /* Minting */
    function preMint(uint8 quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        // activation check
        require(preMintActive, "Pre minting is not active");
        require(_allowList[msg.sender], "You are not on the Allow List");
        require(totalSupply() + quantity <= maxTokens, "Not enough tokens left");
        require(
            _preSaleListCounter[msg.sender] + quantity <= maxMint,
            "Exceeds mint limit per wallet"
        );
        require(PRICE * quantity == msg.value, "Incorrect funds");

        // mint
        _safeMint(msg.sender, quantity);

        // increment counters
        _preSaleListCounter[msg.sender] = _preSaleListCounter[msg.sender] + quantity;
    }

    function publicMint(uint8 quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        // activation check
        require(pubMintActive, "Public minting is not active");
        require(totalSupply() + quantity <= maxTokens, "Not enough tokens left");
        require(
            _pubSaleListCounter[msg.sender] + quantity <= maxMint,
            "Exceeds mint limit per wallet"
        );
        require(PRICE * quantity == msg.value, "Incorrect funds");

        // mint
        _safeMint(msg.sender, quantity);

        // increment counters
        _pubSaleListCounter[msg.sender] = _pubSaleListCounter[msg.sender] + quantity;
    }

    // for marketing etc.
    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= amountForDevs,
            "too many already minted before dev mint"
        );
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
