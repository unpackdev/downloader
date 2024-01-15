// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Strings.sol";

contract KintaroBotz is ERC721, Pausable, ReentrancyGuard, Ownable {
    using Strings for uint256;

    string public baseURI = "https://bafybeih5xia54cyqla5xfoemxwfz776q6wkseh5voi2btovygaahllik3e.ipfs.nftstorage.link/metadata/kintaro";
    uint256 public maxSupply = 100;
    uint256 public tokenIndex = 1;
    uint256 public price = 0.07 ether;
    uint256 public dtcPrice = 0.06 ether;
    uint256 public teamPrice = 0 ether;
    uint256 public maxMintPerAddress = 1;
    uint256 public publicReserve = 46;
    uint256 public publicSupply = 0;
    bool public sale = false;
    mapping(address => bool) public whitelistAddresses;
    mapping(address => bool) public enablerAddresses;
    mapping(address => bool) public ogAddresses;
    mapping(address => bool) public teamAddresses;
    mapping(address => bool) public adminAddresses;
    mapping(address => uint256) public addressMintedBalance;

    modifier onlyAdminOrOwner {
        bool isAdmin = false;
        if (adminAddresses[msg.sender] == true) {
            isAdmin = true;
        }
        if (msg.sender == owner()) {
            isAdmin = true;
        }
        require(isAdmin == true, "Not an admin");
        _;
    }

    constructor() payable ERC721("Kintaro Botz", "BOTZ") {
        uint256 _tokenIndex = tokenIndex;
        for (uint256 i = 0; i < 2; i++) {
            _safeMint(msg.sender, _tokenIndex);
            unchecked {
                _tokenIndex++;
            }
            tokenIndex = _tokenIndex;
        }
    }

    function mint() external payable nonReentrant whenNotPaused {
        uint256 _tokenIndex = tokenIndex;
        uint256 _price = price;
        uint256 _dtcPrice = dtcPrice;
        uint256 _maxMintPerAddress = maxMintPerAddress;
        uint256 _publicSupply = publicSupply;
        uint256 _publicReserve = publicReserve;
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(sale == true, "Minting has not started yet");
        require(_tokenIndex <= maxSupply, "Cannot mint more than max supply");
        require(tx.origin == msg.sender, "Cannot mint through a custom contract"); 
        require(ownerMintedCount + 1 <= _maxMintPerAddress, "Only one token allowed per address");
        
        if (isRole(0, msg.sender) == true) { //Team
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, tokenIndex);
            unchecked {
                _tokenIndex++;
            }
            tokenIndex = _tokenIndex;
        }
        else if (isRole(1, msg.sender) == true) { //OG
            require(msg.value >= _dtcPrice, "Insufficient funds for purchase");
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, tokenIndex);
            unchecked {
                _tokenIndex++;
            }
            tokenIndex = _tokenIndex;
        }
        else if (isRole(2, msg.sender) == true) { //Enabler
            require(msg.value >= _dtcPrice, "Insufficient funds for purchase");
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, tokenIndex);
            unchecked {
                _tokenIndex++;
            }
            tokenIndex = _tokenIndex;
        }
        else if (isRole(3, msg.sender) == true) { //Whitelist
            require(msg.value >= _dtcPrice, "Insufficient funds for purchase");
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, tokenIndex);
            unchecked {
                _tokenIndex++;
            }
            tokenIndex = _tokenIndex;
        }
        else { //Public
            require(msg.value >= _price, "Insufficient funds for purchase");
            require(_publicSupply + 1 <= _publicReserve, "Public sale sold out");
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, tokenIndex);
            unchecked {
                _tokenIndex++;
                _publicSupply++;
            }
            tokenIndex = _tokenIndex;
            publicSupply = _publicSupply;
        }
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory currentBaseURI = _baseURI();
        return currentBaseURI;
    }
    //roles: Team: 0, OG: 1, Enabler: 2, Whitelist: 3
    function isRole(uint256 _role, address _wallet) internal view returns (bool) {
        bool result = false;
        if (_role == 0) {
            result = teamAddresses[_wallet];
        }
        if (_role == 1) {
            result = ogAddresses[_wallet];
        }
        if (_role == 2) {
            result = enablerAddresses[_wallet];
        }
        if (_role == 3) {
            result = whitelistAddresses[_wallet];
        }
        return result;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function totalMinted() public view returns (uint256) {
        return tokenIndex - 1;
    }

    function getRole(address _wallet) public view returns (string memory) { //Returns the role of given address as a string
        string memory role = "public";
        if (teamAddresses[_wallet] == true) {
            role = "team";
        }
        else if (ogAddresses[_wallet] == true) {
            role = "og";
        }
        else if (enablerAddresses[_wallet] == true) {
            role = "enabler";
        }
        else if (whitelistAddresses[_wallet] == true) {
            role = "whitelist";
        }
        return role;
    }

    // ---------------------------------Admin functions-------------------------------------
    function setRoleAddresses(uint256 _role, address[] calldata _wallets) external onlyAdminOrOwner{
        if (_role == 0) { //Team
            for (uint256 i = 0; i < _wallets.length; i++) {
                teamAddresses[_wallets[i]] = true;
            }
        }
        else if (_role == 1) { //OG
            for (uint256 i = 0; i < _wallets.length; i++) {
                ogAddresses[_wallets[i]] = true;
            }
        }
        else if (_role == 2) { //Enabler
            for (uint256 i = 0; i < _wallets.length; i++) {
                enablerAddresses[_wallets[i]] = true;
            }
        }
        else if (_role == 3) { //Whitelist
            for (uint256 i = 0; i < _wallets.length; i++) {
                whitelistAddresses[_wallets[i]] = true;
            }
        }    
    }

    function setAdminAddresses(address[] calldata _wallets) external onlyAdminOrOwner { 
        for (uint256 i = 0; i < _wallets.length; i++) {
            adminAddresses[_wallets[i]] = true;
        }
    }
    function removeAdminAddresses(address[] calldata _wallets) external onlyAdminOrOwner { 
        for (uint256 i = 0; i < _wallets.length; i++) {
            adminAddresses[_wallets[i]] = false;
        }
    }

    function removeRoleAddresses(uint256 _role, address[] calldata _wallets) external onlyAdminOrOwner {
        if (_role == 0) { //Team
            for (uint256 i = 0; i < _wallets.length; i++) {
                teamAddresses[_wallets[i]] = false;
            }
        }
        else if (_role == 1) { //OG
            for (uint256 i = 0; i < _wallets.length; i++) {
                ogAddresses[_wallets[i]] = false;
            }
        }
        else if (_role == 2) { //Enabler
            for (uint256 i = 0; i < _wallets.length; i++) {
                enablerAddresses[_wallets[i]] = false;
            }
        }
        else if (_role == 3) { //Whitelist
            for (uint256 i = 0; i < _wallets.length; i++) {
                whitelistAddresses[_wallets[i]] = false;
            }
        }    
    }

    function setBaseURI(string memory _newBaseURI) external onlyAdminOrOwner { 
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) external onlyAdminOrOwner {
        price = _newPrice;
    }

    function setDTCPrice(uint256 _newDTCPrice) external onlyAdminOrOwner {
        dtcPrice = _newDTCPrice;
    }

    function setPublicReserve(uint256 _newReserve) public onlyAdminOrOwner{
        require(_newReserve <= maxSupply, "Cannot set public reserve higher than max supply");
        publicReserve = _newReserve;
    }

    function releaseDTCReserve(uint256 _supply) external onlyAdminOrOwner {
        setPublicReserve(_supply);
        dtcPrice = 0.07 ether;
    }

    function toggleSale() public onlyAdminOrOwner{
        sale = !sale;
    }

    function pauseContract() public onlyAdminOrOwner{
        _pause();
    }

    function unpauseContract() public onlyAdminOrOwner{
        _unpause();
    }

    function withdrawAll(address _to) external onlyAdminOrOwner {
        address payable to = payable(_to);
        to.transfer(getBalance());
    }
}
