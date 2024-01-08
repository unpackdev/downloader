// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Imports
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

// ** Contract Author: Hyveli LLC. https://hyveli.com/ ** //

/**
 * @title EtherCrap Implementation Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract EtherCrap is ERC721Enumerable, Pausable, Ownable, ReentrancyGuard {
    
    // SafeMath from OpenZeppelin
    using SafeMath for uint256;
    
    // Token IDs as strings.
    using Strings for uint256;

    // Counter parameter for token IDs.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
     // Token Base URI parameters.
    string public baseURI;
    string private notRevealedUri;
    string public baseExtension = "";
    
    /** 
    *** BOOLEAN/STATE PARAMETERS ***
    **/

    // Pre-sale launch - automatically set to false.
    bool public presaleIsOpen = false;

    // Main launch sale - automatically set to false.
    bool public saleIsOpen = false;

    // Whitelist state parameter - automatically set to true.
    bool public whitelistState = true;
    
    

    /** 
    *** PURCHASE & SUPPLY PARAMETERS ***
    **/
    // Maximum supply of tokens allowed during launch.
    uint256 public constant maxSupply = 10000;

    // Main launch price.
    uint256 public constant price = 69000000000000000; //0.069 ETH

    // Maximum quantity of tokens per purchase.
    uint256 public constant maxQuantityPerPurchase = 30;

    // Maximum quantity of tokens that a single holder is allowed to have.
    uint256 public constant maxQuantityPerAddress = 500;

    // Maximum pre-sale purchases a single address can make. 
    uint256 public constant presalePurchasesMax = 5;
    
    // Mapping for the minted balance of each address.
    mapping(address => uint256) public addressTokenBalance;
    
    // Mapping for tracking the pre-sales purchases.
    mapping(address => uint256) private _presaleClaimed;
    
    // Whitelisted addresses for the pre-sale.
    address[] public whitelistedAddresses;


    /** 
     *** ERC721 DECLARATION ***
     *
     * Our metadata is not revealed until all tokens are minted to ensure a fair purchase!
    **/
    constructor(string memory _name, string memory _symbol, string memory _initBaseURI) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    // Modifier used on all minting functions.
    modifier requireMint(uint256 numOfTokens) {
        require(totalSupply().add(numOfTokens) <= maxSupply, "Quantity reaches over the maximum supply of tokens.");
        require(numOfTokens > 0, "Quantity must be greater than 0 tokens.");
        require(numOfTokens <= maxQuantityPerPurchase, "You have exceeded the limit per purchase. Please choose a smaller amount of tokens.");
        require(price.mul(numOfTokens) == msg.value, "Ether value is not correct. Please check the price and update your transaction value.");
        _;
    }
    
    // Pauses all functions. Only the owner has access to this function.
    function pause() public whenNotPaused onlyOwner {
        _pause();
    }
    
    // Reverses the pause on all functions. Only the owner has access to this function.
    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    // Whitelists an array of users. EXAMPLE INPUT.) ["ADDRESS1", "ADDRESS2"]
    function whitelistUsers(address[] calldata _users) public whenNotPaused onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    // Changes the state of whitelist restriction.
    function setWhitelistState(bool _state) public whenNotPaused onlyOwner {
        whitelistState = _state;
    }

    // Changes the state of the pre-sale. Only the owner has access to this function.
    function changePresaleState() public whenNotPaused onlyOwner {
        presaleIsOpen = !presaleIsOpen;
    }

    // Changes the state of the launch sale. Only the owner has access to this function.
    function changeSaleState() public whenNotPaused onlyOwner {
        saleIsOpen = !saleIsOpen;
    }
    

    // Updates the revealed base URI for all tokens. Only the owner has access to this function.
    function setBaseURI(string memory _tokenuri) public whenNotPaused onlyOwner returns(string memory) {
        baseURI = _tokenuri;
        return baseURI;
    }

    // View Base URI.
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Pre-sale mint tokens by quantity. Must be purchased and match the price set by the owner.
    function presaleMint(uint _quantity) public whenNotPaused nonReentrant payable requireMint(_quantity) {
        require(presaleIsOpen, "Pre-sale must be active in order to mint tokens.");
        require(_quantity <= presalePurchasesMax, 'You cannot purchase this many tokens during pre-sale.');
        require(_presaleClaimed[msg.sender].add(_quantity) <= presalePurchasesMax, 'Pre-sale purchase max reached. Please wait for launch.');

        if (msg.sender != owner()) {
            if (whitelistState == true) {
                require(isWhitelisted(msg.sender), "You are not whitelisted for this sale.");
                uint256 ownerMintedCount = addressTokenBalance[msg.sender];
                require(ownerMintedCount.add(_quantity) <= maxQuantityPerAddress, "Maximum allowed quantity of tokens per holder exceeded.");
            }
            require(msg.value >= price.mul(_quantity), "Ether value is not correct. Please check the price and update your transaction value.");
        }

        uint256 newItemId;

        for (uint256 i = 0; i < _quantity; i++) {
            _tokenIds.increment();
            addressTokenBalance[msg.sender]++;
            _presaleClaimed[msg.sender] += 1;
            newItemId = totalSupply();
            _safeMint(msg.sender, newItemId);
        }
    }

     // Mint tokens by quantity. Must be purchased and match the price set by the owner.
    function mintToken(uint _quantity) public whenNotPaused nonReentrant payable requireMint(_quantity) {
        require(saleIsOpen, "Launch sale must be active in order to mint tokens.");

        uint256 newItemId;

        if (msg.sender != owner()) {
            for (uint256 i = 0; i < _quantity; i++) {
                _tokenIds.increment();
                newItemId = totalSupply();
                _safeMint(msg.sender, newItemId);
            }
        }
    }

    // Mint tokens by quantity. Only the owner has access to this function.
    function reserveTokens(uint _quantity) public whenNotPaused nonReentrant onlyOwner {
        require(totalSupply().add(_quantity) <= maxSupply, "Quantity reaches over the maximum supply of tokens.");
        require(_quantity > 0, "Quantity must be greater than 0 tokens.");
         
        uint256 newItemId;

        for (uint256 i = 0; i < _quantity; i++) {
            _tokenIds.increment();
            newItemId = totalSupply();
            _safeMint(msg.sender, newItemId);
        }
    }

    // Giveaway tokens by quantity to a single receipient. Only the owner has access to this function.
    function giveawayTokens(uint _quantity, address recipient) public whenNotPaused nonReentrant onlyOwner {
        require(totalSupply().add(_quantity) <= maxSupply, "Quantity reaches over the maximum supply of tokens.");
        require(_quantity > 0, "Quantity must be greater than 0 tokens.");
         
        uint256 newItemId;

        for (uint256 i = 0; i < _quantity; i++) {
            _tokenIds.increment();
            newItemId = totalSupply();
            _safeMint(recipient, newItemId);
        }
            
    }

     // Giveaway a single token to many receipients. Only the owner has access to this function.
    function giveawayTokenToMultiple(address[] memory recipients) external whenNotPaused nonReentrant onlyOwner {
        require(totalSupply().add(recipients.length) <= maxSupply, "Quantity reaches over the maximum supply of tokens.");
         
        for (uint256 i = 0; i < recipients.length; i++) {
          giveawayTokens(1, recipients[i]);
        }
            
    }
    
    // Check if whitelisted.
    function isWhitelisted(address _user) public view returns (bool) {
            for (uint i = 0; i < whitelistedAddresses.length; i++) {
                if (whitelistedAddresses[i] == _user) {
                    return true;
                }
            }
        return false;
    }

    // Check token balance.
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
            for (uint256 i; i < ownerTokenCount; i++) {
                tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
            }
        return tokenIds;
    }

    // Withdraw the funds from the contract. Only the owner has access to this function.
    function withdraw() public whenNotPaused onlyOwner nonReentrant {
        address payable to = payable(msg.sender);
        uint256 balance = address(this).balance;
        to.transfer(balance);
    }
    
}