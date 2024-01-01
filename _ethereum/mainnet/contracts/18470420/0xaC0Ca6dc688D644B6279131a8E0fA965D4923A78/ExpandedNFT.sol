// SPDX-License-Identifier: GPL-3.0

/**

    ExpandedNFTs

 */

pragma solidity ^0.8.19;

import "./ERC721Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./IExpandedNFT.sol";
/**
    This is a smart contract for handling dynamic contract minting.

    @dev This allows creators to mint a unique serial drop of an expanded NFT within a custom contract
    @author Zien
    Repository: https://github.com/joinzien/expanded-nft
*/
contract ExpandedNFT is
    ERC721Upgradeable,
    IExpandedNFT,
    IERC2981Upgradeable,
    OwnableUpgradeable
{
    using StringsUpgradeable for uint256;

    enum WhoCanMint{ NOT_FOR_SALE, ALLOWLIST, ANYONE }

    enum ExpandedNFTStates{ UNMINTED, RESERVED, MINTED, REDEEM_STARTED, REDEEMED }
    
    event PriceChanged(uint256 amount);
    event EditionSold(uint256 price, address owner);
    event WhoCanMintChanged(WhoCanMint minters);

    // State change events
    event RedeemStarted(uint256 tokenId);
    event ProductionComplete(uint256 tokenId);
    event DeliveryAccepted(uint256 tokenId);

    /// @title EIP-721 Metadata Update Extension

    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.    
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId); 

    struct PerToken { 
        ExpandedNFTStates state;

        // Who reserved this
        address reservedBy;

        // Metadata
        string mintedMetadataUrl;
        string redeemedMetadataUrl;
    }

    struct Pricing { 
        // Royalty amount in bps
        uint256 royaltyBPS;

        // Split amount to the platforms. the artist in bps
        uint256 splitBPS;

        // Price for allow list sales
        uint256 allowListSalePrice;

        // Limit for allow list sales
        uint256 allowListMintLimit;

        // Price for general sales
        uint256 generalMintLimit;   

        // Allow list Addresses allowed to mint edition
        mapping(address => bool) allowListMinters;
        address[] allowList;   

        // The number on the allow list
        uint256 allowListCount;

        // Who can currently mint
        WhoCanMint whoCanMint;

        // Mint counts for each address
        mapping(address => uint256) mintCounts;      

        // Annual pass address
        IERC721Upgradeable annualPassAddress;

        // Lifetime pass address
        IERC721Upgradeable lifetimePassAddress;

        // Annual pass price
        uint256 annualPassAllowListPrice; 
        uint256 annualPassGeneralPrice; 

        // Lifetime pass discount
        uint256 lifetimePassAllowListPrice;  
        uint256 lifetimePassGeneralPrice;                                            
    }

    // Artists wallet address
    address private _artistWallet;

    // Per Token data
    mapping(uint256 => PerToken) private _perTokenMetadata;

    // Total size of the drop that can be minted
    uint256 public dropSize;
    uint256 private _claimCount; 

    // Pricing
    Pricing private _pricing;
    uint256 public salePrice;

    string private _baseDir;

    // Reservations
    mapping(address => uint256)  private _resevationCount;
    mapping(address => uint256[]) private _resevations;   

    bool private _randomMint;
    uint256 private _currentIndex;

    // Global constructor for factory
    constructor() {
        _pricing.whoCanMint = WhoCanMint.NOT_FOR_SALE;

        _disableInitializers();
    }

    /**
      @param _owner wallet addres for the user that owns and can mint the drop, gets royalty and sales payouts and can update the base url if needed.
      @param artistWallet wallet address for thr User that created the drop
      @param _name Name of drop, used in the title as "$NAME NUMBER/TOTAL"
      @param _symbol Symbol of the new token contract
      @param baseDirectory The base directory fo the metadata
      @param _dropSize Number of editions that can be minted in total. 
      @param randomMint Mint in an random order   
      @dev Function to create a new drop. Can only be called by the allowed creator
           Sets the only allowed minter to the address that creates/owns the drop.
           This can be re-assigned or updated later
     */
    function initialize(
        address _owner,
        address artistWallet,
        string memory _name,
        string memory _symbol,
        string memory baseDirectory,
        uint256 _dropSize,
        bool randomMint
    ) public initializer {
        require(_dropSize > 0, "Drop size must be > 0");

        __ERC721_init(_name, _symbol);
        __Ownable_init();

        // Set ownership to original sender of contract call
        transferOwnership(_owner);

        _artistWallet = artistWallet;
        _baseDir = baseDirectory;
        dropSize = _dropSize;

        // Set edition id start to be 1 not 0
        _claimCount = 0; 
        _currentIndex = 1;
        _randomMint = randomMint;
    }

    /// @dev returns the base directory string
    function baseDir() public view returns (string memory) {
        return _baseDir;
    }
    
    /// @dev returns the number of minted tokens within the drop
    function totalSupply() public view returns (uint256) {
        return _claimCount;
    }

    /// @dev returns the royalty BPS
    function getRoyaltyBPS() public view returns (uint256) {
        return _pricing.royaltyBPS;
    }

    /// @dev returns the split BPS
    function getSplitBPS() public view returns (uint256) {
        return _pricing.splitBPS;
    }

    /// @dev returns the allow list sale price
    function getAllowListPrice() public view returns (uint256) {
        return _pricing.allowListSalePrice;
    }

    /// @dev returns the allow list mint limit
    function getAllowListMintLimit() public view returns (uint256) {
        return _pricing.allowListMintLimit;
    }

    /// @dev returns the number on the allow list
    function getAllowListCount() public view returns (uint256) {
        return _pricing.allowListCount;
    }    

    /// @dev returns the general mint limit
    function getGeneralMintLimit() public view returns (uint256) {
        return _pricing.generalMintLimit;
    }

    /// @dev returns the Annual pass address
    function getAnnualPassAddress() public view returns (address) {
        return address(_pricing.annualPassAddress);
    }

    /// @dev returns the Lifetime pass address
    function getLifetimePassAddress() public view returns (address) {
        return address(_pricing.lifetimePassAddress);
    }

    /// @dev returns the Annual pass price
    function getAnnualPassAllowListPrice() public view returns (uint256) {
        return _pricing.annualPassAllowListPrice;
    }

    /// @dev returns the Annual pass price
    function getAnnualPassGeneralPrice() public view returns (uint256) {
        return _pricing.annualPassGeneralPrice;
    }

    /// @dev returns the Lifetime pass price
    function getLifetimeAllowListPassPrice() public view returns (uint256) {
        return _pricing.lifetimePassAllowListPrice;
    }

    /// @dev returns the Lifetime pass price
    function getLifetimePassGeneralPrice() public view returns (uint256) {
        return _pricing.lifetimePassGeneralPrice;
    }

    /// @dev returns mint limit for the address
    function getMintLimit(address wallet) public view returns (uint256) {
        if (wallet == owner()) {
            return numberCanMint();
        }

        if ((_pricing.whoCanMint == WhoCanMint.ALLOWLIST) && (allowListed(wallet) == false)) {
            return 0;
        }

        uint256 currentMintLimit = _currentMintLimit(wallet);

        if (_pricing.mintCounts[wallet]  >= currentMintLimit) {
            return 0;
        }
            
        return (currentMintLimit - _pricing.mintCounts[wallet]);   
    }

    /// @dev returns  if the address can mint
    function canMint(address wallet) public view returns (bool) {
        uint256 currentMintLimit = getMintLimit(wallet);   
        return (currentMintLimit > 0);   
    }

    /// @dev returns if the address is on the allow list
    function allowListed(address wallet) public view returns (bool) {
        return _pricing.allowListMinters[wallet];
    }
   
    /**
      @dev returns the current ETH sales price
           based on who can currently mint.
     */
    function price() public view returns (uint256){
        if (_pricing.whoCanMint == WhoCanMint.ALLOWLIST) {
            // Assuming Lifetime passes have a greater or equal discount to the annual pass 
            if (address(_pricing.lifetimePassAddress) != address(0x0)) {
                if (_pricing.lifetimePassAddress.balanceOf(msg.sender) > 0) {
                    return _pricing.lifetimePassAllowListPrice;   
                }
            }

            if (address(_pricing.annualPassAddress) != address(0x0)) {
                if (_pricing.annualPassAddress.balanceOf(msg.sender) > 0) {
                    return _pricing.annualPassAllowListPrice;
                }
            }

            return _pricing.allowListSalePrice;
        } else if (_pricing.whoCanMint == WhoCanMint.ANYONE) {
            // Assuming Lifetime passes have a greater or equal discount to the annual pass 
            if (address(_pricing.lifetimePassAddress) != address(0x0)) {
                if (_pricing.lifetimePassAddress.balanceOf(msg.sender) > 0) {
                    return _pricing.lifetimePassGeneralPrice;
                }
            }

            if (address(_pricing.annualPassAddress) != address(0x0)) {
                if (_pricing.annualPassAddress.balanceOf(msg.sender) > 0) {
                    return _pricing.annualPassGeneralPrice;
                }
            }

            return salePrice;
        } 
            
        return 0;       
    }

    /**
      @dev returns the current state of the provided token
     */
    function redeemedState(uint256 tokenId) public view returns (uint256) {
        require(tokenId > 0, "tokenID > 0");
        require(tokenId <= dropSize, "tokenID <= drop size");

        return uint256(_perTokenMetadata[tokenId].state);
    }

    /**
        Simple eth-based sales function
        More complex sales functions can be implemented through IExpandedNFT interface
     */

    /**
      @dev This allows the user to purchase an edition
           at the given price in the contract.
     */

    function purchase() external payable returns (uint256) {
        address[] memory toMint = new address[](1);
        toMint[0] = msg.sender;

        return _mintEditionsBody(toMint);  
    }

     /**
      @param to address to send the newly minted edition to
      @dev This mints one edition to the given address by an allowed minter on the edition instance.
     */
    function mintEdition(address to) external payable override returns (uint256) {
        address[] memory toMint = new address[](1);
        toMint[0] = to;

        return _mintEditionsBody(toMint);        
    }

    /**
      @param recipients list of addresses to send the newly minted editions to
      @dev This mints multiple editions to the given list of addresses.
     */
    function mintEditions(address[] memory recipients)
        external payable override returns (uint256)
    {
        return _mintEditionsBody(recipients);
    } 

     /**
      @param to address to send the newly minted edition to
      @param count how many editions to mint      
      @dev This mints one edition to the given address by an allowed minter on the edition instance.
     */
    function mintMultipleEditions(address to, uint256 count) external payable returns (uint256) {
        address[] memory toMint = new address[](count);

        for (uint256 r = 0; r < count; r++) {
            toMint[r] = to;
        }

        return _mintEditionsBody(toMint);        
    }      

    /**
      @param numberToBeMinted Hopw many IDs trying to be minted    
      @dev This mints multiple editions to the given list of addresses.
     */
    function _paymentAmountCorrect(uint256 numberToBeMinted)
        internal returns (bool)
    {
        uint256 paymentAmount = price() * numberToBeMinted;

        if (msg.value == paymentAmount) {
            return (true);
        }

        return (false);
    }

    /**
      @dev This mints multiple editions to the given list of addresses.
     */
    function _getNextReservation()
        internal returns (uint256)
    {
        uint256 index = 0;
        while (_resevations[msg.sender][index] == 0) {
            index++;
        }  

        uint256 currentToken = _resevations[msg.sender][index];

        _resevations[msg.sender][index] = 0;  
        _resevationCount[msg.sender]--;
        _perTokenMetadata[currentToken].reservedBy = address(0);        
        
        return  currentToken;
    }

    /**
      @dev This mints multiple editions to the given list of addresses.
     */
    function _selectAvailableId()
        internal returns (uint256)
    {
        if (_randomMint) {
            uint256 random = uint(keccak256(abi.encodePacked(msg.sender,block.prevrandao,gasleft()))) % dropSize;
            uint256 randomIndex = 1 + random;

            while (_perTokenMetadata[randomIndex].state != ExpandedNFTStates.UNMINTED) {
                randomIndex++;

                if (randomIndex > dropSize)  {
                    randomIndex = 1;
                }
            } 

            return randomIndex;
        }

        uint256 index = _currentIndex;

        while (_perTokenMetadata[index].state != ExpandedNFTStates.UNMINTED) {
            index++;
        } 

        _currentIndex = index;

        return  index;
    }

    /**
      @param recipients list of addresses to send the newly minted editions to
      @dev This mints multiple editions to the given list of addresses.
     */
    function _mintEditionsBody(address[] memory recipients)
        internal returns (uint256)
    {
        require(_isAllowedToMint(), "Needs to be an allowed minter");

        require(recipients.length <= numberCanMint(), "Exceeded supply");
        require((_pricing.mintCounts[msg.sender] + recipients.length) <= _currentMintLimit(msg.sender), "Exceeded mint limit");

        require(_paymentAmountCorrect(recipients.length), "Wrong price");

        uint256 currentToken;

        for (uint256 i = 0; i < recipients.length; i++) {
            if (_resevationCount[msg.sender] > 0) {
                currentToken = _getNextReservation();
            } else {
                currentToken = _selectAvailableId();
            }

            _mint(recipients[i], currentToken);

            _perTokenMetadata[currentToken].state = ExpandedNFTStates.MINTED;
            _pricing.mintCounts[msg.sender]++;
            _claimCount++;

            emit EditionSold(price(), msg.sender);
            emit MetadataUpdate(currentToken);            
        }

        return currentToken;        
    }  

    /**
      @param annualPassAddress Annual pass ERC721 token address. Can be null if no token is in use.
      @param lifetimePassAddress Lifetime pass ERC721 token address. Can be null if no token is in use.
      @param annualPassAllowListPrice the allowlist price when holding an annual pass
      @param annualPassGeneralPrice the general price when holding an annual pass
      @param lifetimePassAllowListPrice the allowlist price when holding an lifetime pass
      @param lifetimePassGeneralPrice the general price when holding an lifetime pass                                                                               
      @dev Set various pricing related values
     */
    function  updateDiscounts(address annualPassAddress, address lifetimePassAddress, 
        uint256 annualPassAllowListPrice, uint256 annualPassGeneralPrice, 
        uint256 lifetimePassAllowListPrice, uint256 lifetimePassGeneralPrice) external onlyOwner { 
        _pricing.annualPassAddress = IERC721Upgradeable(annualPassAddress);
        _pricing.lifetimePassAddress = IERC721Upgradeable(lifetimePassAddress);

        _pricing.annualPassAllowListPrice = annualPassAllowListPrice;
        _pricing.annualPassGeneralPrice = annualPassGeneralPrice;

        _pricing.lifetimePassAllowListPrice = lifetimePassAllowListPrice;  
        _pricing.lifetimePassGeneralPrice = lifetimePassGeneralPrice;     
    }

    /**
      @param _royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty.
      @param _splitBPS BPS of the royalty set on the contract. Can be 0 for no royalty. 
      @param _allowListSalePrice Sale price for allow listed wallets
      @param _generalSalePrice SalePrice for the general public     
      @param _allowListMintLimit Mint limit for allow listed wallets
      @param _generalMintLimit Mint limit for the general public                                                                                 
      @dev Set various pricing related values
     */
    function setPricing (
        uint256 _royaltyBPS,
        uint256 _splitBPS,
        uint256 _allowListSalePrice,  
        uint256 _generalSalePrice,
        uint256 _allowListMintLimit,
        uint256 _generalMintLimit             
    ) external onlyOwner {  
        _pricing.royaltyBPS = _royaltyBPS;
        _pricing.splitBPS = _splitBPS;

        _pricing.allowListSalePrice = _allowListSalePrice;
        salePrice = _generalSalePrice;

        _pricing.allowListMintLimit = _allowListMintLimit;
        _pricing.generalMintLimit = _generalMintLimit;

        emit PriceChanged(salePrice);
    }

    /**
      @param wallets A list of wallets
      @param tokenIDs A list of tokenId to reserve                                                                           
      @dev Reserve an edition for a wallet
     */
    function reserve (address[] calldata wallets, uint256[] calldata tokenIDs)  external onlyOwner {  
        require(wallets.length == tokenIDs.length, "Lists length must match");

        for (uint256 i = 0; i < wallets.length; i++) {
            require(_perTokenMetadata[tokenIDs[i]].state == ExpandedNFTStates.UNMINTED, "Needs to be unminted");

            _perTokenMetadata[tokenIDs[i]].reservedBy = wallets[i];
            _perTokenMetadata[tokenIDs[i]].state = ExpandedNFTStates.RESERVED;
            _resevationCount[wallets[i]]++;
            _resevations[wallets[i]].push(tokenIDs[i]); 
        }
    }

    /**
      @param tokenIDs A list of tokenId to unreserve                                                                           
      @dev Unreserve an edition for a wallet
     */
    function unreserve (uint256[] calldata tokenIDs) external onlyOwner {  
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            require(_perTokenMetadata[tokenIDs[i]].state == ExpandedNFTStates.RESERVED, "Not reserved");

            address wallet = _perTokenMetadata[tokenIDs[i]].reservedBy;
            uint256 index = 0;
            while (_resevations[wallet][index] != tokenIDs[i]) {
                index++;
            }

            _resevations[wallet][index] = 0;  

            _resevationCount[_perTokenMetadata[tokenIDs[i]].reservedBy]--;
            _perTokenMetadata[tokenIDs[i]].reservedBy = address(0);
            _perTokenMetadata[tokenIDs[i]].state = ExpandedNFTStates.UNMINTED;
        }
    }

    /**
      @param tokenID the tokenId to check                                                                           
      @dev Unreserve an edition for a wallet
     */
    function isReserved (uint256 tokenID) external view returns (bool) {  
        return _perTokenMetadata[tokenID].reservedBy != address(0);
    }

    /**
      @param tokenID the tokenId to check                                                                           
      @dev who reserved the provided ID
     */
    function whoReserved (uint256 tokenID) external view returns (address) {  
        return _perTokenMetadata[tokenID].reservedBy;
    }
 
    /**
      @param wallet The wallet being checked                                                                          
      @dev returns the number of reservations for this wallet
    */
    function getReservationsCount(address wallet) public view returns (uint256) {           
        return _resevationCount[wallet];   
    }

    /**
      @param wallet The wallet being checked                                                                          
      @dev returns the IDs reserved by the wallet
    */
    function getReservationsList(address wallet) public view returns (uint256[] memory) {           
        return _resevations[wallet];   
    }   

    /**                                                                      
      @dev returns the wallets on the allow list
    */
    function getAllowList() public view returns (address[] memory) {           
        return _pricing.allowList;   
    }   

    /**
      @dev returns the current limit on edition that 
           can be minted by one wallet
     */
    function _currentMintLimit(address wallet) internal view returns (uint256){
        if (_pricing.whoCanMint == WhoCanMint.ALLOWLIST) {
            return _pricing.allowListMintLimit;
        } else if (_pricing.whoCanMint == WhoCanMint.ANYONE) {
            return _pricing.generalMintLimit;
        } else if (wallet == owner()) {
            return numberCanMint();
        }
            
        return 0;       
    }

    /**
      @param baseDirectory The base directory fo the metadata
      @dev Update the base directory
     */
    function updateBaseDir(string memory baseDirectory) external onlyOwner {
        _baseDir= baseDirectory;
    }

    /**
      @param _salePrice The amount of ETH is needed to start the sale.
      @dev This sets a simple ETH sales price
           Setting a sales price allows users to mint the drop until it sells out.
           For more granular sales, use an external sales contract.
     */
    function setSalePrice(uint256 _salePrice) external onlyOwner {
        salePrice = _salePrice;

        _pricing.whoCanMint = WhoCanMint.ANYONE;

        emit WhoCanMintChanged(_pricing.whoCanMint);
        emit PriceChanged(_salePrice);
    }

    /**
      @param _salePrice The amount of ETH is needed to start the sale.
      @dev This sets the allow list ETH sales price
           Setting a sales price allows users to mint the drop until it sells out.
           For more granular sales, use an external sales contract.
     */
    function setAllowListSalePrice(uint256 _salePrice) external onlyOwner {
        _pricing.allowListSalePrice = _salePrice;

        _pricing.whoCanMint = WhoCanMint.ALLOWLIST;

        emit WhoCanMintChanged(_pricing.whoCanMint);
        emit PriceChanged(_salePrice);
    }

     /**
      @param allowListSalePrice if sale price is 0 sale is stopped, otherwise that amount 
                       of ETH is needed to start the sale.
      @param generalSalePrice if sale price is 0 sale is stopped, otherwise that amount 
                       of ETH is needed to start the sale.                                              
      @dev This sets the members ETH sales price
           Setting a sales price allows users to mint the drop until it sells out.
           For more granular sales, use an external sales contract.
     */
    function setSalePrices(uint256 allowListSalePrice, uint256 generalSalePrice) external onlyOwner {
        _pricing.allowListSalePrice = allowListSalePrice;
        salePrice = generalSalePrice;        

        emit PriceChanged(generalSalePrice);
    }  

    /**
      @dev This withdraws ETH from the contract to the contract owner.
     */
    function withdraw() external onlyOwner {
        uint256 currentBalance = address(this).balance;
        if (currentBalance > 0) {
            if (_artistWallet != address(0x0)) {
                uint256 platformFee = (currentBalance * _pricing.splitBPS) / 10000;
                uint256 artistFee = currentBalance - platformFee;

                AddressUpgradeable.sendValue(payable(owner()), platformFee);
                AddressUpgradeable.sendValue(payable(_artistWallet), artistFee);            
            } else {
                AddressUpgradeable.sendValue(payable(owner()), currentBalance);
            } 
        }
    }

    /**
      @dev This helper function checks if the msg.sender is allowed to mint the
            given edition id.
     */
    function _isAllowedToMint() internal view returns (bool) {
        if (_pricing.whoCanMint == WhoCanMint.ANYONE) {
            return true;
        }

        if (owner() == msg.sender) {
            return true;
        }   

        if (_pricing.whoCanMint == WhoCanMint.ALLOWLIST) {
            if (_pricing.allowListMinters[msg.sender]) {
                return true;
            } 

            if (address(_pricing.lifetimePassAddress) != address(0x0)) {
                if (_pricing.lifetimePassAddress.balanceOf(msg.sender) > 0) {
                    return (true);
                }
            }

            if (address(_pricing.annualPassAddress) != address(0x0)) {
                if (_pricing.annualPassAddress.balanceOf(msg.sender) > 0) {
                    return (true);
                }
            }
        }

        return false;
    }

    /**
        Simple override for owner interface.
     */
    function owner()
        public
        view
        override(OwnableUpgradeable, IExpandedNFT)
        returns (address)
    {
        return super.owner();
    }

    /**
        return the artists wallet address
     */
    function getArtistWallet()
        public
        view
        returns (address)
    {
        return _artistWallet;
    }

     /**
        set the artists wallet address
     */
    function setArtistWallet(address wallet)
        public
        onlyOwner
    {
        _artistWallet = wallet;
    }   

    /**
      @dev Sets the types of users who is allowed to mint.
     */
    function getAllowedMinter() public view returns (WhoCanMint){
        return _pricing.whoCanMint;
    }

    /**
      @param minters WhoCanMint enum of minter types
      @dev Sets the types of users who is allowed to mint.
     */
    function setAllowedMinter(WhoCanMint minters) public onlyOwner {
        _pricing.whoCanMint = minters;
        emit WhoCanMintChanged(minters);
    }

    /**
      @param minter address to set approved minting status for
      @param allowed boolean if that address is allowed to mint
      @dev Sets the approved minting status of the given address.
           This requires that msg.sender is the owner of the given edition id.
           If the ZeroAddress (address(0x0)) is set as a minter,
             anyone will be allowed to mint.
           This setup is similar to setApprovalForAll in the ERC721 spec.
     */
    function setAllowListMinters(uint256 count, address[] calldata minter, bool[] calldata allowed) public onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            if (_pricing.allowListMinters[minter[i]] != allowed[i]) {
                if (allowed[i] == true) {
                    _pricing.allowListCount++;

                    _pricing.allowList.push(minter[i]);   

                } else {
                    _pricing.allowListCount--; 

                    uint256 index = 0;
                    while (_pricing.allowList[index] != minter[i]) {
                        index++;
                    }

                    _pricing.allowList[index] = address(0);  

                }
            }

            _pricing.allowListMinters[minter[i]] = allowed[i];
        }
    }

    /**
      @param startIndex The first ID index to write the data
      @param count How many rows of data to load 
      @param _mintedMetadataUrl The URL to the metadata for this Edtion
      @dev Function to create a new drop. Can only be called by the allowed creator
           Sets the only allowed minter to the address that creates/owns the drop.
           This can be re-assigned or updated later
     */
    function updateMetadata(
        uint256 startIndex,
        uint256 count,
        string[] memory _mintedMetadataUrl
    ) public onlyOwner {
        require(startIndex > 0, "StartIndex > 0");
        require(startIndex + count <= dropSize + 1, "Data large than drop size");

        require(_mintedMetadataUrl.length == count, "Data size mismatch");

        for (uint i = 0; i < count; i++) {
            uint index =  startIndex + i;
            
            _perTokenMetadata[index].mintedMetadataUrl =_mintedMetadataUrl[i];

            emit MetadataUpdate(index);
        }
    }

    /**
      @param tokenID The index to write the data
      @param _redeemedMetadataUrl The URL to the metadata for this Edtion
      @dev Function to create a new drop. Can only be called by the allowed creator
           Sets the only allowed minter to the address that creates/owns the drop.
           This can be re-assigned or updated later
     */
    function updateRedeemedMetadata(
        uint256 tokenID,
        string memory _redeemedMetadataUrl

    ) public onlyOwner {
        require(tokenID > 0, "tokenID > 0");
        require(tokenID <= dropSize, "tokenID <= drop size");

        _perTokenMetadata[tokenID].redeemedMetadataUrl = _redeemedMetadataUrl;

        emit MetadataUpdate(tokenID);
    }

    /// Returns the number of editions allowed to mint
    function numberCanMint() public view override returns (uint256) {
        return dropSize - _claimCount;
    }

    /**
        @param tokenId Token ID to burn
        User burn function for token id 
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved");
        _burn(tokenId);
    }

    function productionStart(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "No token");        
        require((_perTokenMetadata[tokenId].state== ExpandedNFTStates.MINTED), "Wrong state");

        _perTokenMetadata[tokenId].state = ExpandedNFTStates.REDEEM_STARTED;

        emit RedeemStarted(tokenId);
    }

    function productionComplete(
        uint256 tokenId,
        string memory _redeemedMetadataUrl              
    ) public onlyOwner {
        require(_exists(tokenId), "No token");        
        require((_perTokenMetadata[tokenId].state == ExpandedNFTStates.REDEEM_STARTED), "You currently can not redeem");

        _perTokenMetadata[tokenId].redeemedMetadataUrl = _redeemedMetadataUrl;
       _perTokenMetadata[tokenId].state = ExpandedNFTStates.REDEEMED;

        emit ProductionComplete(tokenId);
        emit MetadataUpdate(tokenId);
    }

    /**
        @dev Get royalty information for token
        @param _salePrice Sale price for the token
     */
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (owner() == address(0x0)) {
            return (owner(), 0);
        }
        return (owner(), (_salePrice * _pricing.royaltyBPS) / 10_000);
    }

    /**
        @dev Get URI for given token id
        @param tokenId token id to get uri for
        @return base64-encoded json metadata object
    */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "No token");

        if (_perTokenMetadata[tokenId].state == ExpandedNFTStates.REDEEMED) {
            return (_perTokenMetadata[tokenId].redeemedMetadataUrl);
        }

        bytes memory tempEmptyStringTest = bytes(_perTokenMetadata[tokenId].mintedMetadataUrl);
        if (tempEmptyStringTest.length == 0) {
            return string(abi.encodePacked(_baseDir, tokenId.toString(), ".json"));
        }

        return (_perTokenMetadata[tokenId].mintedMetadataUrl);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            type(IERC2981Upgradeable).interfaceId == interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }
}
