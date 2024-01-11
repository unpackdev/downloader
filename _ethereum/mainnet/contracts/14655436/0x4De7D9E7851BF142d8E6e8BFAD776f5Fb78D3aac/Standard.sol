// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Delegates.sol";

contract Standard is ERC721A, ReentrancyGuard, Delegated {
    using Strings for uint256;
    mapping(address => uint256) private _balances;

    // ======== SUPPLY ========
    uint256 public constant MAX_SUPPLY = 678;

    // ======== SUPPLY FREE ========
    uint256 public constant FREE_SUPPLY = 100;

    // ======== MAX MINTS ========
    uint256 public maxPublicSaleMint = 5;

    // ======== PRICE ========
    uint256 public publicSalePrice = 0.006 ether;

    // ======== SALE STATUS ========
    bool public isPublicSaleActive = true;

    // ======== METADATA ========
    bool public isRevealed = true;
    string private _baseTokenURI = "ipfs://QmfXhM6u6puYjceZ7kJwAWumQudcbfGVhm4dA1fUasnf21/";
    string public notRevealedUri;
    string public baseExtension = ".json";

    // ======== MINTED ========
    mapping(address => uint256) public publicSaleMinted;
    uint256 public totalMinted = 0;


    // ======== CONSTRUCTOR ========
    constructor() ERC721A("Glitched MoonBirbs", "GMB") {}

    /**
     * @notice must be an Externally Owned Account (EOA)
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // ======== MINTING ========
    /**
     * @notice public sale mint
     */
    function publicSaleMint(uint256 _quantity) external payable callerIsUser {
        require(isPublicSaleActive, "Public sale is not active");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply reached");
        require(_quantity <= maxPublicSaleMint, "Max mint reached");

        if (totalMinted > FREE_SUPPLY) {
            require(msg.value >= publicSalePrice, "Not enought ETH");
            require(
            msg.value >= publicSalePrice * _quantity,
            "Not enough ether sent"
            );
            
            totalMinted += _quantity;
            publicSaleMinted[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);
        }
        else { // Free mint 
            totalMinted += _quantity;
            publicSaleMinted[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);

        }

    }

    // ======== SALE STATUS SETTERS ========

    /**
     * @notice activating or deactivating public sale
     */
    function setPublicSaleStatus(bool _status) external onlyOwner {
        isPublicSaleActive = _status;
    }

    // ======== PRICE SETTERS ========
    /**
     * @notice set public sale price
     */
    function setPublicSalePrice(uint256 _price) external onlyOwner {
        publicSalePrice = _price;
    }

    /**
     * @notice set base URI
     */
    function setBaseURI(string calldata baseURI) external onlyDelegates {
        _baseTokenURI = baseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    /**
     * @notice set IsRevealed to true or false
     */
    function setIsRevealed(bool _reveal) external onlyOwner {
        isRevealed = _reveal;
    }

    /**
     * @notice set maxPublicSaleMint
     */
    function setMaxPublicSaleMint(uint _amount) external onlyOwner {
        maxPublicSaleMint = _amount;
    }

    /**
     *   @notice set startTokenId to 1
     */
    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    // ======== WITHDRAW GNOSIS ========

    /**
     * @notice withdraw funds to gnosis safe
     */
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("Caller not owner");
        require(os);
    }

    // ======== UTILS ========

    /**
     * @dev increment and decrement balances based on address from and  to.
     */
    function _beforeTokenTransfer(address from, address to) internal {
        if (from != address(0)) --_balances[from];

        if (to != address(0)) ++_balances[to];
    }

    // ========= GETTERS ===========
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
        _exists(tokenId),
        "ERC721aMetadata: URI query for nonexistent token"
        );
    
        if(isRevealed == false) {
            return notRevealedUri;
        }

        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), baseExtension));
    }
}
