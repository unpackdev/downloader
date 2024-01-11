// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract AMNFTPASS is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint;

    Counters.Counter private _tokenIdCounter;
    mapping(uint => uint256) public expiryTimeOfToken;

    uint256 public maxSupply;
    uint256 public passPrice = 0.2 ether;
    uint256 public renewalPrice = 0.2 ether;

    uint256 public passDuration = 90 days;
    uint256 public dateSpecificDrop_ExpiryDate = 1661990399;

    string private baseURI;
    
    bool public whitelistMintSwitch = false;
    bool public mintSwitch = false;
    bool public dateSpecificDropSwitch = false;
    bool public renewTokenSwitch = false;
    bool public showtokenURI = false;
    
    address[] private mintedAddressesForDrop;
    address[] private whitelistedAddresses;

    event tokenMinted(uint256 tokenId, uint256 _expiryTimeOfToken);
    event tokenRenew(uint256 tokenId, uint256 _expiryTimeOfToken);


    constructor(string memory _initBaseURI, uint256 numberOfTokens)
    ERC721("AMNFT Pass ", "AMNFT") 
    {
        setBaseURI(_initBaseURI);
        _tokenIdCounter.increment();
        maxSupply = numberOfTokens;
    } 

    modifier noHaxxor() {
        require(msg.sender == tx.origin, "Haxxor access blocked");
        _;
    }

    function getMintedAddressesForDrop() public view returns(address[] memory){
        return mintedAddressesForDrop;
    }
    
    function getWhitelistedAddressesForDrop() public view returns(address[] memory){
        return whitelistedAddresses;
    }
    
    function addressAlreadyMintedForDrop(address _walletAddress) public view returns (bool) {
        return addressExistsInArray(mintedAddressesForDrop, _walletAddress);
    }
    
    function addressWhitelistedForDrop(address _walletAddress) public view returns (bool) {
        return addressExistsInArray(whitelistedAddresses, _walletAddress);
    }

    function lastTokenId() public view returns (uint) {
        return _tokenIdCounter.current() - 1;
    }
    
     /**
     * @dev provide URI for token metadata
     * @return base URI for token metadata
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev provide URI for token metadata
     * @param tokenId - Id of the token
     * @return URI of the the token metadata
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
          _exists(tokenId),
          "ERC721Metadata: URI query for nonexistent token"
        );
        if (showtokenURI) {
            return super.tokenURI(tokenId);
        } else {
            return baseURI;
        }
    }

    function isTokenValid(uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "Token does not exist.");
        return (expiryTimeOfToken[_tokenId] <= block.timestamp);
    } 

    function addressExistsInArray(address[] memory array, address addressToFind) private pure returns (bool) {
        bool found = false;
        for (uint i=0; i < array.length; i++) {
            if(array[i] == addressToFind){
                found = true;
                break;
            }
        }
        return found;
    }

    /**
     * @dev public sale mint
     */
    function mint() external payable noHaxxor {
        require(mintSwitch, "Minting for whitelisted members not initiated.");

        uint256 supply = lastTokenId();
        require(supply + 1 <= (maxSupply), "Out of passes to mint :/");
        require(!addressAlreadyMintedForDrop(msg.sender), "You already minted in this drop.");

        mintedAddressesForDrop.push(msg.sender);

        require(msg.value >= passPrice, "Incorrect amount of ether sent.");
    
        uint256 tokenIndex = _tokenIdCounter.current();

        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();

        if (dateSpecificDropSwitch) {
            expiryTimeOfToken[tokenIndex] = dateSpecificDrop_ExpiryDate;
        } else {
            expiryTimeOfToken[tokenIndex] = block.timestamp + passDuration;
        }
        emit tokenMinted(tokenIndex, expiryTimeOfToken[tokenIndex]);
    }
    
    /**
     * @dev whitelist mint
     */
    function whitelistMint() external payable noHaxxor {
        require(whitelistMintSwitch, "Minting for whitelisted members not initiated.");
        require(addressWhitelistedForDrop(msg.sender), "You are not whitelisted for the actual drop");

        uint256 supply = lastTokenId();

        require(supply + 1 <= (maxSupply), "Out of passes to mint :/");
        require(!addressAlreadyMintedForDrop(msg.sender), "You already minted in this drop.");

        mintedAddressesForDrop.push(msg.sender);
 
        uint256 tokenIndex = _tokenIdCounter.current();

        require(msg.value >= passPrice, "Incorrect amount of ether sent.");
    
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();

        if (dateSpecificDropSwitch) {
            expiryTimeOfToken[tokenIndex] = dateSpecificDrop_ExpiryDate;
        } else {
            expiryTimeOfToken[tokenIndex] = block.timestamp + passDuration;
        }
        
        emit tokenMinted(tokenIndex, expiryTimeOfToken[tokenIndex]);
    }

    /**
     * @dev renew pass
     * @param _tokenId - tokenId 
     */
    function renewPass(uint _tokenId) public payable noHaxxor {
        require(renewTokenSwitch);
        require(msg.value >= renewalPrice, "Incorrect amount of ether sent.");
        require(_exists(_tokenId), "Pass does not exist.");

        require(_isApprovedOrOwner(_msgSender(), _tokenId), "You are not owner of the token nor approved");

        if (block.timestamp > expiryTimeOfToken[_tokenId]) {
            expiryTimeOfToken[_tokenId] = block.timestamp + passDuration;
        } else {
            expiryTimeOfToken[_tokenId] += passDuration;
        }

        emit tokenRenew(_tokenId, expiryTimeOfToken[_tokenId]);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(expiryTimeOfToken[tokenId] > block.timestamp, "Token is expired.");
        _safeTransfer(from, to, tokenId, _data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(expiryTimeOfToken[tokenId] > block.timestamp, "Token is expired.");
        _transfer(from, to, tokenId);
    }
    
    /** 
    ***************** onlyOwner methods ************************************
    */

    function changePassPrice(uint256 _changedPassPrice) external onlyOwner {
        require(passPrice != _changedPassPrice, "Pass price did not change.");
        passPrice = _changedPassPrice;
    }

    function changeRenewalPrice(uint256 _changedRenewalPrice) external onlyOwner {
        require(renewalPrice != _changedRenewalPrice, "Pass renewal price did not change.");
        renewalPrice = _changedRenewalPrice;
    }
  
    /**
     * @dev set base URI for metadata
     * @param _newBaseURI URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev set show tokenURI for metadata
     * @param _showtokenURI - bool to show tokenized URI
     */
    function setShowTokenURI(bool _showtokenURI) public onlyOwner {
        showtokenURI = _showtokenURI;
    }
    
    /**
     * @dev setter for whitelist mint
     * @param _whitelistMintSwitch - bool for whitelist mint is active
     */
    function setWhitelistMintSwitch(bool _whitelistMintSwitch) public onlyOwner {
        whitelistMintSwitch = _whitelistMintSwitch;                                         
    }
    
    /**
     * @dev setter for passDuration
     * @param _passDuration - value of passDuration in days
     */
    function setPassDuration(uint256 _passDuration) external onlyOwner {
        passDuration = _passDuration * 1 days;                                         
    }
    
    /**
     * @dev setter for mint
     * @param _mintSwitch - bool for mint is active
     */
    function setMintSwitch(bool _mintSwitch) public onlyOwner {
        mintSwitch = _mintSwitch;                                         
    }
    
    /**
     * @dev setter for date specific drop
     * @param _dateSpecificDropSwitch - bool for date specific drop is active
     */
    function setDateSpecificDropSwitch(bool _dateSpecificDropSwitch) public onlyOwner {
        dateSpecificDropSwitch = _dateSpecificDropSwitch;                                         
    }
    
    /**
     * @dev setter for renew
     * @param _renewTokenSwitch - bool for renewal is active
     */
    function setRenewTokenSwitch(bool _renewTokenSwitch) public onlyOwner {
        renewTokenSwitch = _renewTokenSwitch;                                         
    }

    /**
     * @dev renew pass owner
     * @param _tokenId - tokenId 
     */
    function renewPassOwner(uint _tokenId, uint256 timestampUntil) public payable onlyOwner {
        require(_exists(_tokenId), "Pass does not exist.");

        expiryTimeOfToken[_tokenId] = timestampUntil;

        emit tokenRenew(_tokenId, expiryTimeOfToken[_tokenId]);
    }

    /**
     * @dev mint tokens to addresses
     * @param _addresses - _addresses to mint 
     */
    function devMintTokensToAddresses(address[] memory _addresses) external onlyOwner {
        uint256 supply = lastTokenId();
        require(supply + _addresses.length <= (maxSupply), "Out of passes to mint :/");

        for (uint256 i; i < _addresses.length; i++) {
            _mint(_addresses[i], _tokenIdCounter.current());

            if (dateSpecificDropSwitch) {
                expiryTimeOfToken[_tokenIdCounter.current()] = dateSpecificDrop_ExpiryDate;
            } else {
                expiryTimeOfToken[_tokenIdCounter.current()] = block.timestamp + passDuration;
            }
            _tokenIdCounter.increment();
        }
    }

    /**
     * @dev withdraw all assets
     * @param _address - adress to withdraw all assets
     */  
    function withdraw(address _address) external payable onlyOwner {
        (bool success, ) = payable(_address).call{value: address(this).balance}("");
        require(success);
    }
    
    /**
     * @dev init new drop
     * @param numberOfNewSlots - number of new tokens that will be added to total 
                                 supply of tokens that can be minted (value > 0)
     * @param addresses - adresses to add whitelist access (addresses.length <= numberOfNewSlots)
     */  
    function initNewDrop(uint256 numberOfNewSlots, address[] calldata addresses) public onlyOwner {
        require(numberOfNewSlots > 0, "Number of new slots should be larger than 0!");
       
        deleteMintedAddressesForDrop();
        deleteWhitelistedAddresses();

        addAddressesToWhitelist(addresses);
        increaseMaxSupply(numberOfNewSlots);
    }
   
    /**
     * @dev init drop with specific expiry date for newly minted passes (first drop)
     * @param numberOfNewSlots - number of new tokens that will be added to total 
                                 supply of tokens that can be minted (value > 0)
     * @param addresses - adresses to add whitelist access (addresses.length <= numberOfNewSlots)
     * @param expiryDate - date until all minted passes will be valid
     */  
    function initDateSpecificDrop(uint256 numberOfNewSlots, address[] calldata addresses, uint256 expiryDate) external onlyOwner {
        initNewDrop(numberOfNewSlots, addresses);
        
        setDateSpecificDropSwitch(true);
        dateSpecificDrop_ExpiryDate = expiryDate;
    }

    /**
     * @dev stop drop - stop drop, dateSpecificSwitch and sale 
     */  
    function stopDrop() external onlyOwner {
        setDateSpecificDropSwitch(false);
        setMintSwitch(false);
        setWhitelistMintSwitch(false);
    }

    function addAddressesToWhitelist(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            whitelistedAddresses.push(addresses[i]);
        }
    }

    function increaseMaxSupply(uint256 numberOfNewSlots) public onlyOwner {
        maxSupply += numberOfNewSlots;

    }

    function decreaseMaxSupply(uint256 _numTokens) external onlyOwner {
        require(maxSupply - _numTokens >= lastTokenId(), "Supply cannot fall below minted tokens.");
        maxSupply -= _numTokens;
    }

    function deleteWhitelistedAddresses() public onlyOwner {
        delete whitelistedAddresses;
    }
   
    function deleteMintedAddressesForDrop() public onlyOwner {
        delete mintedAddressesForDrop;
    }

    function burnToken(uint256 tokenId) public virtual onlyOwner {
        _burn(tokenId);
    }
    
    function burnExpiredTokens() public virtual onlyOwner {
        for (uint256 i = 1; i <= lastTokenId(); i++) {
            if (_exists(i)) 
            {
                if (expiryTimeOfToken[i] < block.timestamp) {
                    _burn(i);
                }
            }
        }
    }

}