// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./UUPSUpgradeable.sol";

contract PROPERTIES is ERC721AUpgradeable, PausableUpgradeable, ERC2981Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

    uint currentTokenId;
    uint256 internal MAX_SUPPLY;
    uint256 internal MAX_PER_WALLET;
    mapping(uint8 => uint) public propertyPrice;
    mapping(string => bool) uriIsPresent;
    mapping(uint => uint8) tokenProperty;
    mapping(address => bool) _isBlackListed;
    mapping(uint => string) idToUri;
    mapping(string => uint) uriToId;
    mapping(uint => uint) timeOfToken;
    mapping(uint => bool) controlFloor;
    mapping(uint => uint) lastPrice;
    address payable internal wallet1;
    string public contractURI;


    event Mint(
        address to,
        string uri
    );

    event Burn(
        uint tokenId
    );

    event Pause(
        bool state
    );

    event Paid(
        uint _required,
        uint _paid
    );

function initialize(string memory _contractURI) initializerERC721A initializer public {
        __ERC721A_init('PROPERTIES', 'PRP');
        __Ownable_init();
        propertyPrice[0] = 0.115 ether;
        propertyPrice[1] = 0.15 ether;
        propertyPrice[2] = 0.23 ether;
        propertyPrice[3] = 1.15 ether;
        currentTokenId = 1;
        MAX_SUPPLY = 500000;
        MAX_PER_WALLET = 50000;
        setRoyaltyInfo(0x10c34C3EBeA5163EfAe92D6A36a7b93249beCb45, 250);
        contractURI = _contractURI;
        wallet1 = payable(0x10c34C3EBeA5163EfAe92D6A36a7b93249beCb45);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function MintNFT(uint8 _property, string memory _uri, address _to) external payable whenNotPaused {
        require(!uriIsPresent[_uri], "This URI already exists");
        require(!_isBlackListed[_to], "This account is blacklisted");
        
        // any other conditions
        require(_property==0 || _property==1 || _property==2 || _property==3, "Enter a valid property");

        if(MAX_SUPPLY != 0) {
            require(currentTokenId + 1 < MAX_SUPPLY, "Max supply exceeded");
        }
        
        if(MAX_PER_WALLET != 0) { 
            require(balanceOf(_to) < MAX_PER_WALLET, "Mint limit exceeded");
        }

        require(msg.value == propertyPrice[_property], "Wrong Payment");
        emit Paid(propertyPrice[_property], msg.value);
        _safeMint(_to, 1);
        tokenProperty[currentTokenId] = _property;

        uriIsPresent[_uri] = true;
        idToUri[currentTokenId] = _uri;
        uriToId[_uri] = currentTokenId;
        timeOfToken[currentTokenId] = block.timestamp;
        controlFloor[currentTokenId] = true;

        currentTokenId++;

        emit Mint(_to, _uri);
    }

    function batchMintNFT(uint8 _property, string memory _baseUri, address _to, uint256 _quantity)  external payable whenNotPaused {
        string memory _urii = string(bytes.concat(bytes(_baseUri), bytes(_toString(currentTokenId)), ".json"));
        require(!uriIsPresent[_urii], "This URI already exists");
        require(!_isBlackListed[_to], "This account is blacklisted");
        
        // any other conditions
        require(_property==0 || _property==1 || _property==2 || _property==3, "Enter a valid property");

        if(MAX_SUPPLY != 0) {
            require(currentTokenId + _quantity < MAX_SUPPLY, "Max supply exceeded");
        }
        
        if(MAX_PER_WALLET != 0) { 
            require(balanceOf(_to) + _quantity <= MAX_PER_WALLET, "Mint limit exceeded");
        }

        require(msg.value == propertyPrice[_property]*_quantity, "Wrong Payment");
        emit Paid(propertyPrice[_property], msg.value);

        _safeMint(_to, _quantity);
        for(uint i=0; i<_quantity; i++){
            tokenProperty[currentTokenId + i] = _property;
            string memory _uri = string(bytes.concat(bytes(_baseUri), bytes(_toString(currentTokenId)), ".json"));

            uriIsPresent[_uri] = true;
            idToUri[currentTokenId] = _uri;
            uriToId[_uri] = currentTokenId;
            timeOfToken[currentTokenId] = block.timestamp;
            controlFloor[currentTokenId] = true;

            currentTokenId++;
        }
    }

    function airdropNFT(uint8 _property, string memory _uri, address _to) external whenNotPaused onlyOwner {
        require(!uriIsPresent[_uri], "This URI already exists");
        require(!_isBlackListed[_to], "This account is blacklisted");
        
        // any other conditions
        require(_property==0 || _property==1 || _property==2 || _property==3, "Enter a valid property");

        if(MAX_SUPPLY != 0) {
            require(currentTokenId + 1 < MAX_SUPPLY, "Max supply exceeded");
        }
        
        if(MAX_PER_WALLET != 0) { 
            require(balanceOf(_to) < MAX_PER_WALLET, "Mint limit exceeded");
        }

        _safeMint(_to, 1);
        tokenProperty[currentTokenId] = _property;

        uriIsPresent[_uri] = true;
        idToUri[currentTokenId] = _uri;
        uriToId[_uri] = currentTokenId;
        timeOfToken[currentTokenId] = block.timestamp;
        controlFloor[currentTokenId] = true;

        currentTokenId++;

        emit Mint(_to, _uri);
    }
    function batchAirdropNFT(uint8 _property, string memory _baseUri, address _to, uint256 _quantity) external whenNotPaused onlyOwner{
        string memory _urii = string(bytes.concat(bytes(_baseUri), bytes(_toString(currentTokenId)), ".json"));
        require(!uriIsPresent[_urii], "This URI already exists");
        require(!_isBlackListed[_to], "This account is blacklisted");
        
        // any other conditions
        require(_property==0 || _property==1 || _property==2 || _property==3, "Enter a valid property");

        if(MAX_SUPPLY != 0) {
            require(currentTokenId + _quantity < MAX_SUPPLY, "Max supply exceeded");
        }
        
        if(MAX_PER_WALLET != 0) { 
            require(balanceOf(_to) + _quantity <= MAX_PER_WALLET, "Mint limit exceeded");
        }

        _safeMint(_to, _quantity);
        for(uint i=0; i<_quantity; i++){
            tokenProperty[currentTokenId + i] = _property;
            string memory _uri = string(bytes.concat(bytes(_baseUri), bytes(_toString(currentTokenId)), ".json"));

            uriIsPresent[_uri] = true;
            idToUri[currentTokenId] = _uri;
            uriToId[_uri] = currentTokenId;
            timeOfToken[currentTokenId] = block.timestamp;
            controlFloor[currentTokenId] = true;

            currentTokenId++;
        }
        // tokenProperty[currentTokenId] = _property;

        // uriIsPresent[_uri] = true;
        // idToUri[currentTokenId] = _uri;
        // uriToId[_uri] = currentTokenId;
        // timeOfToken[currentTokenId] = block.timestamp;
        // controlFloor[currentTokenId] = true;

        // currentTokenId++;

    }

    function getPropertyType(uint tokenId) public view returns(uint8) {
        require(_exists(tokenId), "Token id does not exist");
        return tokenProperty[tokenId];
    }

    function addToBlackList(address[] calldata accounts) external onlyOwner {
        for(uint256 i; i < accounts.length; ++i) {
            _isBlackListed[accounts[i]] = true;
        } 
    }

    // remove single account at a time from the blacklist
    function removeFromBlackList(address account) external onlyOwner {
        require(_isBlackListed[account], "This account is not blacklisted");
        _isBlackListed[account] = false;
    }

    function checkBlacklist(address acc) public view returns(bool) {
        return _isBlackListed[acc];
    }

    function setMaxSupply(uint num) public onlyOwner {
        MAX_SUPPLY = num;
    }

    function removeMaxSupply() public onlyOwner {
        MAX_SUPPLY = 0;
    }

    function setMaxPerWallet(uint32 num) public onlyOwner {
        MAX_PER_WALLET = num;
    }

    function removeMaxPerWallet() public onlyOwner {
        MAX_PER_WALLET = 0;
    }

    function getTimestampOfToken(uint tokenId) public view returns(uint) {
        require(_exists(tokenId), "Token id doesnt exist");
        return timeOfToken[tokenId];
    }

    function setWallet1(address payable acc) public onlyOwner {
        wallet1 = acc;
    }

    function checkContractBalance() public onlyOwner view returns(uint) {
        return address(this).balance;
    }

    function listNFT(uint tokenId, uint _price) public returns(uint, string memory) {
        require(_exists(tokenId), "Token id doesnt exist");
        require(msg.sender == ownerOf(tokenId), "You are not authorised");
        if(_price > propertyPrice[tokenProperty[tokenId]] && _price > lastPrice[tokenId]){
           delete(controlFloor[tokenId]);
        }
        require(!controlFloor[tokenId], "Sorry! Unable to process this request");
        return (tokenId, tokenURI(tokenId));
    }

    function transferNFT(address from, address to, uint tokenId) public payable {
        safeTransferFrom(from, to, tokenId);
        lastPrice[tokenId] = msg.value;
    }

    function withdrawMoney() public onlyOwner {
        wallet1.transfer(address(this).balance);
    }

    // upgradeable part from here

    function updatePrice(uint _condo, uint _house, uint _mansion, uint tier4) public onlyOwner {
        propertyPrice[0] = _condo;
        propertyPrice[1] = _house;
        propertyPrice[2] = _mansion;
        propertyPrice[3] = tier4;
    }

    function setTokenUri(uint256 _tokenId, string memory _uri ) public whenNotPaused {
        require(msg.sender == ownerOf(_tokenId), "You are not allowed");
        require(_exists(_tokenId), "Token id does not exist");
        require(!_isBlackListed[msg.sender], "This account is blacklisted.");

        delete(uriToId[tokenURI(_tokenId)]);
        delete(uriIsPresent[tokenURI(_tokenId)]);
        uriIsPresent[_uri] = true;
        idToUri[_tokenId] = _uri;
        uriToId[_uri] = _tokenId;
    }

    // function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    //     internal
    //     whenNotPaused
    //     override
    // {
    //     super._beforeTokenTransfer(from, to, tokenId);
    // }    

    // for Royalty

    // royalty fees in bips => 2.5 becomes 250
    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(uriIsPresent[idToUri[tokenId]] , "Not minted yet.");
        return idToUri[tokenId];
    }

    function tokenIdFromUri(string memory _uri) public view returns(uint){
        require(uriToId[_uri] != 0, "Not a valid URI");
        return uriToId[_uri];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981Upgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function burn(uint256 tokenId) public virtual{
        //solhint-disable-next-line max-line-length
        require(!_isBlackListed[msg.sender], "This account is blacklisted.");
        
        delete(uriIsPresent[tokenURI(tokenId)]);
        delete(tokenProperty[tokenId]);
        delete(timeOfToken[tokenId]);
        delete(controlFloor[tokenId]);
        _burn(tokenId);
        emit Burn(tokenId);
    }

}