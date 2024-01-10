// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///  _____ _             ___  _                     _             _     _       ______                  _     
/// |_   _| |           / _ \| |                   (_)           | |   | |      | ___ \                | |    
///   | | | |__   ___  / /_\ \ |__   ___  _ __ ___  _ _ __   __ _| |__ | | ___  | |_/ /_   _ _ __   ___| |__  
///   | | | '_ \ / _ \ |  _  | '_ \ / _ \| '_ ` _ \| | '_ \ / _` | '_ \| |/ _ \ | ___ \ | | | '_ \ / __| '_ \ 
///   | | | | | |  __/ | | | | |_) | (_) | | | | | | | | | | (_| | |_) | |  __/ | |_/ / |_| | | | | (__| | | |
///   \_/ |_| |_|\___| \_| |_/_.__/ \___/|_| |_| |_|_|_| |_|\__,_|_.__/|_|\___| \____/ \__,_|_| |_|\___|_| |_|

/// https://www.theabominablebunch.io/
/// Developers: Breezi, K3x

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./IERC2981.sol";

import "./EIP712Whitelisting.sol";
import "./OwnableDelegateProxy.sol";

//-----------------------------------------------------------------------------------------------------------------------
// Main Contract
//-----------------------------------------------------------------------------------------------------------------------

contract TheAbominableBunch is IERC721, IERC2981, ERC721Enumerable, EIP712Whitelisting, ReentrancyGuard, ContextMixin, NativeMetaTransaction {
    using Strings for uint256;

    // Constants.
    uint16 public constant MAX_SUPPLY = 4400;               // The total amount that can be minted ever.
    uint128 public constant WHITELIST_COST = 0.065 ether;   // Whitelist cost.
    uint128 public constant PUBLIC_COST = 0.09 ether;       // Public cost.
   
    // Configuration.
    bool public isWhiteList = true;                         // Is this the whitelist phase?
    bool public isPaused = true;                            // Controls if the minting is paused or not.   
    bool public revealed = false;                           // Define if the tokens are revealed or not and the address if they are.
    uint8 public maxMintPerAddress = 6;                     // The max amount of mints any single address can mint.
    string private baseURI;                                 // stores the base urI of where to find NFT metadata.
    string private notRevealedUri;                          // Define the address if the tokens are not revealed yet.
    mapping(address => uint16) private mintBalances;        // Store lifetime mints for an address.
    
    // Proxy
    address private immutable proxyRegistryAddress;        // Opensea Proxy


    // --------------------------
    // constructor
    // --------------------------

    /// @notice Contract constructor.
    /// @param _name The token name.
    /// @param _symbol The symbol the token will be known by.
    /// @param _initNotRevealedUri The URI of the not revealed version of the NFT metadata.
    constructor(string memory _name, string memory _symbol, string memory _initNotRevealedUri, address _proxyRegistryAddress)
        ERC721(_name, _symbol) 
        EIP712Whitelisting(_name)
    {
        notRevealedUri = _initNotRevealedUri;           // Set the not revealed URI for the placeholder metadata. 
        proxyRegistryAddress = _proxyRegistryAddress;   // Set the openseac proxy address.

        _initializeEIP712("The Abominable Bunch");     // Init base EIP712.
    }


    // --------------------------
    // External / public
    // --------------------------

    /// @notice Returns the token url a token id.
    /// @param _max The max amount the person minting is allow to mint.
    /// @param _signature The signature proving that the user is on the whitelist and the values haven't been altered.
    /// @param _mintAmount The amount the person minting has requested to mint.
    function purchase(uint16 _max, bytes calldata _signature, uint16 _mintAmount) 
        external 
        payable 
        nonReentrant 
    {
        require(_mintAmount > 0,  "Must mint at least one");
       
        // Owner Minting
        if (msg.sender == owner())
        {
            _mint(_mintAmount, 0);
        } 
        else
        {
            // Prevent mint if paused.
            if (isPaused) { revert("Minting is paused"); }                      

            // Check people aren't exceeding their per address limits.
            if (_mintAmount + mintBalances[msg.sender] > maxMintPerAddress) { revert("Exceeds per address limit"); }
    
            // Check if we are in one of the mints to with whitelist restrictions.
            if (isWhiteList)             
            {      
                // Check if the amount they are trying to buy exceeds the whitelist limit.
                // we are doing ! to avoid >= (gas costly)
                require(!(_mintAmount + mintBalances[msg.sender] > _max), "You have exceeded your mint whitelist allocation");

                // Check the whitelist details match.
                require(checkWhitelist(_max, _signature),  "Invalid whitelist signature");
            }

            // Mint!
            _mint(_mintAmount, isWhiteList ? WHITELIST_COST : PUBLIC_COST);
        }
    }


    /// @notice Returns a list of token ids belonging to an account.
    /// @param _address The address to request a list of tokens for.
    /// @return an array of token ids.
    function walletOfOwner(address _address)
        external
        view
        returns (uint256[] memory)
    {
        uint256 addressTokenCount = balanceOf(_address);
        uint256[] memory tokenIds = new uint256[](addressTokenCount);

        for (uint256 i; i < addressTokenCount; i++) 
        {
            tokenIds[i] = tokenOfOwnerByIndex(_address, i);
        }

        return tokenIds;
    }


    /// @notice Returns the token url a token id.
    /// @param _tokenId The id of the token to return the url for.
    /// @return the compiled Uri string to the nft metadata.
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // Check for the existence of the token.
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Check if the token have been revealed. If not return url to a common image.
        if (revealed == false) { return notRevealedUri; }

        // Get the base url.
        string memory currentBaseURI = _baseURI();

        // Compile a url using the token details.
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json")) : "";
    }


    // --------------------------
    // Royalties
    // --------------------------

    /// @notice EIP2981 calculate how much royalties paid to the contract owner.
    /// @param _tokenId The token id (not used all tokens attaract same level of royalties).
    /// @param _salePrice The sale price.
    /// @return receiver and a royaltyAmount.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount)
    {
        return (owner(), (_salePrice * 500) / 10000);
    }

    /// @notice Indicates if we support the IERC2981 interface.
    /// @param _interfaceId the interface to check the contract supports.
    /// @return true or fales if the requested interface is supported.
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return (_interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId));
    }


    // --------------------------
    // internal
    // --------------------------

    /// @notice generates the return URL from the base URL.
    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) {

        return baseURI;
    }
 
    /// @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    function isApprovedForAll(address owner, address operator) 
        public 
        view 
        override(IERC721, ERC721) 
        returns (bool)
    {
        // whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) { return true; }
        return super.isApprovedForAll(owner, operator);
    }

    /// @notice Does the actual minting.
    /// @param _quantity The quantity to mint for the given user.
    function _mint(uint16 _quantity, uint128 price) internal {

        // Check the total supply.
        uint256 supply = totalSupply();

        // Make sure we dont exceed the total supply.
        require(supply + _quantity <= MAX_SUPPLY, "Max NFT limit exceeded");

        // Check the user is putting the right amount of eth in.
        require(msg.value >= price * _quantity, "Insuffcient Eth in transaction, check price");

        // Loop through and call the underlying mint function of the ERC721Enumerable
        for (uint16 i = 1; i <= _quantity; i++) 
        {
            _safeMint(msg.sender, supply + i);  // request underlying contract to mint.
        }

        // Update the count of how many items and given address has minted over the lifetime of the contract.
        mintBalances[msg.sender] += _quantity;
    }


    // --------------------------
    // owner
    // --------------------------

    /// @notice Set the amount of nfts per address is allowed.
    /// @param _newMax The new maximum pr address.
    function setMaxPerAddress(uint8 _newMax) external onlyOwner {
        maxMintPerAddress = _newMax;
    }

    /// @notice Burn a token.
    /// @param _tokenId The token id to burn.
    function burn(uint256 _tokenId) external onlyOwner {
        _burn(_tokenId);
    }

    /// @notice determines if the tokens should return proper images or place holders before reveal.
    /// @param _state The state to set, true is revelaed false is hidden.
    function setRevealed(bool _state) external onlyOwner {
        revealed = _state;
    }

    /// @notice Set the base uri for the the NFT metadata.
    /// @param _newBaseURI The new base uri for the metadata.
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @notice set if the mint is paused or not.
    /// @param _state The state to set, true is paused false is unpaused.
    function setPaused(bool _state) external onlyOwner {
        isPaused = _state;
    }

    /// @notice Set the whitelist mode.
    /// @param _state The state to set, true is in whitelist mode false is in public mode.
    function setIsWhiteList(bool _state) external onlyOwner {
        isWhiteList = _state;
    }

    /// @notice allow withdrawls from the contract by the owner.
    function withdraw() public payable onlyOwner {
        // This will payout the owner 100% of the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }
}
