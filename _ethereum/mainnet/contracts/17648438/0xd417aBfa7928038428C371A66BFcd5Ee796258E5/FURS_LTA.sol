// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// _______________ _____________  _________    .____  ________________   
// \_   _____/    |   \______   \/   _____/    |    | \__    ___/  _  \  
//  |    __) |    |   /|       _/\_____  \     |    |   |    | /  /_\  \ 
//  |     \  |    |  / |    |   \/        \    |    |___|    |/    |    \
//  \___  /  |______/  |____|_  /_______  / /\ |_______ \____|\____|__  /
//      \/                    \/        \/  \/         \/             \/ 
// Visit https://lucatheastronaut.com 
// Minting Contract
// Developed by https://mayhemlabs.io 

import "./ERC721ABurnable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC2981.sol";

import "./OwnableDelegateProxy.sol";

//-----------------------------------------------------------------------------------------------------------------------
// Minting Contract
//-----------------------------------------------------------------------------------------------------------------------

contract FURS_LTA is ERC721ABurnable, IERC2981, ReentrancyGuard, Ownable, OwnableDelegateProxy {
    using Strings for uint256; 

    // Constants.
    uint16 public constant MAX_SUPPLY = 8000;                          // Total number of NFTs that can be minted ever. 
    uint16 public constant ROYALTY = 600;                              // 600 is divided by 10000 in the royalty info function to make 6%
   
    // Configuration.
    address private immutable proxyRegistryAddress;                   // Opensea proxy to preapprove.
    address private devWallet;                                         // The address the developer portion is paid to.
    uint256 public publicCost = 0.02 ether;                            // Public cost.
    string private baseURI;                                            // Stores the baseURI for location of NFT Metadata 
    bool public isPaused = true;                                       // Is the contract paused?
    

    // --------------------------
    //  Constructor
    // -------------------------- 

    /// @notice Contract constructor.
    /// @param _name The token name.
    /// @param _symbol The symbol the token will be known by.
    /// @param _BaseURI The URI of the NFT metadata.
    /// @param _devWallet the contract developers.
    constructor(string memory _name, string memory _symbol, string memory _BaseURI, address _proxyRegistryAddress, address _devWallet) 
        ERC721A(_name, _symbol) 
    {
        baseURI = _BaseURI;                                            // Set the not revealed URI for the metadata. 
        proxyRegistryAddress = _proxyRegistryAddress;                  // Set the opensea proxy address.
        devWallet = _devWallet;                                        // The wallet funds go to for the devs from the mint.
    }



    // --------------------------
    // Purchase and Minting
    // --------------------------

    /// @notice Returns the token url a token id.
    /// @param _mintAmount The amount the person minting has requested to mint.
    function ownerMint(uint16 _mintAmount) 
        external 
        onlyOwner 
        mintAmountGreaterThanZero(_mintAmount)
        doesntExceedMaxSupply(_mintAmount)
    {
        _mint(msg.sender, _mintAmount);
    }
    
    /// @notice Allows the owner to airdrop tokens to a specific address.
    /// @param _to The address of the person receiving the token/s.
    /// @param _mintAmount The number of tokens being minted and sent.
    function ownerAirdrop(address _to, uint16 _mintAmount) 
        external 
        onlyOwner 
        mintAmountGreaterThanZero(_mintAmount)
        doesntExceedMaxSupply(_mintAmount)
    {
        _mint(_to, _mintAmount);
    }

    /// @notice Purchase a token as the public.
    /// @param _mintAmount The amount the person minting has requested to mint.
    function publicMint(uint16 _mintAmount) 
        external 
        payable 
        nonReentrant
        isNotPaused
    {
        _doMint(_mintAmount, publicCost);
    }

    /// @notice Calls the underlying mint function of the ERC721Enumerable class.
    /// @param _mintAmount The quantity to mint for the given user.
    function _doMint(uint16 _mintAmount, uint256 _price) 
        internal
        doesntExceedMaxSupply(_mintAmount)
        insuffcientEth(_mintAmount, _price)
     {
        _mint(msg.sender, _mintAmount);
     }



    // --------------------------
    // Metadata Url
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

    /// @notice Returns the token url a token id.
    /// @param _tokenId The id of the token to return the url for.
    /// @return the compiled Uri string to the nft metadata.
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        // Check for the existence of the token.
        require(_exists(_tokenId), "ERC721AMetadata: URI query for nonexistent token");

        // Get the base url.
        string memory currentBaseURI = _baseURI();

        // Compile a url using the token details.
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json")) : "";
    }



    // --------------------------
    // Royalties
    // --------------------------


    /// @notice EIP2981 calculate how much royalties paid to the contract owner.
    /// @param _salePrice The sale price.
    /// @return receiver and a royaltyAmount.
    function royaltyInfo(uint256, uint256 _salePrice) 
        external 
        view 
        override(IERC2981) 
        returns (address receiver, uint256 royaltyAmount)
    {
        return (owner(), (_salePrice * 600) / 10000); // eg. (100*600) / 10000 = 6
    }



    // --------------------------
    // Modifiers
    // --------------------------

    /// @notice Check they are minting at least one.
    /// @param mintAmount the amount they are trying to mint.
    modifier mintAmountGreaterThanZero(uint256 mintAmount) {
        require(mintAmount > 0,  "Must mint at least one");
        _;
    }

    /// @notice Make sure the contract isn't paused.
    modifier isNotPaused() {
        require(!isPaused,  "Minting is paused");
        _;
    }

    /// @notice Make sure the amount being minted doesn't exceed total supply.
    /// @param mintAmount the amount they are trying to mint.
    modifier doesntExceedMaxSupply(uint256 mintAmount) {
        require(totalMinted() + mintAmount <= MAX_SUPPLY, "Max NFT supply exceeded");
         _;
    }

    /// @notice Check they provided enough eth to mint.
    /// @param mintAmount the amount they are trying to mint.
    /// @param price price per token.
    modifier insuffcientEth(uint256 mintAmount, uint256 price) {
        require(msg.value >= price * mintAmount, "Insuffcient ETH in transaction, check price");
         _;
    }



    // --------------------------
    // Misc
    // --------------------------

    /// @notice Indicates if we support the IERC2981 interface (https://eips.ethereum.org/EIPS/eip-2981).
    /// @param _interfaceId the interface to check the contract supports.
    /// @return true or fales if the requested interface is supported.
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return (_interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId));
    }

    /// @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    /// @param _owner the token owner.
    /// @param _operator the operator to check approval for.
    /// @return true if approved false otherwise.
    function isApprovedForAll(address _owner, address _operator) 
        public 
        view 
        override(ERC721A) 
        returns (bool)
    {
        // Whitelist OpenSea proxy contract to save gas by not needing approval when trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) { return true; }

        // Otherwise default to base implmentation.
        return super.isApprovedForAll(_owner, _operator);
    }

    function totalMinted() public view virtual returns (uint256) {
        return _totalMinted();
    }
    

    // --------------------------
    // Controls
    // --------------------------

    /// @notice Set the base URI for the NFT Metadata
    /// @param _newBaseURI The new base URI for the Metadata
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @notice Set public mint price.
    /// @param _newMintPrice The new maximum per address.
    function setMintPrice(uint256 _newMintPrice) external onlyOwner {
        publicCost = _newMintPrice;
    }

    /// @notice Set if the mint is paused or not.
    /// @param _state The state to set, true is paused false is unpaused.
    function setPaused(bool _state) external onlyOwner {
        isPaused = _state;
    }

    /// @notice Allow withdrawals from the contract by the owner.
    function withdraw() public payable onlyOwner {
        // This will payout the devs 4% of the contract balance and the owner 96%.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool devs, ) = payable(address(devWallet)).call{value: (address(this).balance * 4) / 100}("");
        require(devs, "Error withdrawing to devWallet");

        (bool owner, ) = payable(address(owner())).call{value: address(this).balance}("");
        require(owner, "Error withdrawing to ownerWallet");
        // =============================================================================
    }
}