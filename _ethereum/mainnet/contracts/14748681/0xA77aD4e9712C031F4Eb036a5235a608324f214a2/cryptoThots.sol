// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";

contract cryptoThots is ERC721A, Ownable{
    using Strings for uint256;

    string public baseURI;

    uint256 public cost = 0.08 ether;
    uint256 public maxSupply = 3333;
    uint256 public nftPerAddressLimit = 3;

    bool public paused = false;
    bool public onlyWhitelisted = true;

    address[] public whitelistedAddresses;
    mapping(address => bool) public adminAddresses;

    event SetBaseURI(string newBaseURI);
    event SetNftPerAddressLimit(uint limit);
    event SetCost(uint cost);
    event SetPaused(bool _state);
    event SetOnlyWhitelisted(bool _state);
    event SetMaxSupply(uint _maxSupply);
    event SetWhitelistUsers(uint userCount);
    event SetAdmins(uint adminCount);
    event DisableAdmins(uint adminCount);
    event TokenMinted(address indexed owner, uint indexed amount, uint balance);


    modifier onlyAdmins {
        require(adminAddresses[msg.sender] == true, "you are not Admin!");
        _;
    }

    constructor() ERC721A("Crypto Thots", "CTT") {
        adminAddresses[_msgSender()] = true;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseURI = _baseTokenURI;
        emit SetBaseURI(_baseTokenURI);
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            require(_numberMinted(msg.sender) + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
            if(onlyWhitelisted == true) {
                require(isWhitelisted(msg.sender), "user is not whitelisted");
            }
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }

        _safeMint(msg.sender, _mintAmount);
        emit TokenMinted(msg.sender, _mintAmount, msg.value);
    }

    // internal Minting, for Credit Card and other payment

    function adminMint(uint256 _mintAmount, address _customerAddress) public onlyAdmins{
        require(!paused, "the contract is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(_numberMinted(_customerAddress) + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        _safeMint(_customerAddress, _mintAmount);
        emit TokenMinted(_customerAddress, _mintAmount, 0);
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }


    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
        emit SetNftPerAddressLimit(_limit);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
        emit SetCost(_newCost);
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
        emit SetPaused(_state);
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
        emit SetOnlyWhitelisted(_state);
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner{
        maxSupply = _maxSupply;
        emit SetMaxSupply(_maxSupply);
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        require(_users.length > 0, "Invalid Parameter!");
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
        emit SetWhitelistUsers(_users.length);
    }

    function setAdmins(address[] calldata _admins) public onlyOwner {
        require(_admins.length > 0, "Invalid Parameter!");
        for (uint i = 0; i < _admins.length; i++) {
            adminAddresses[_admins[i]] = true;
        }
        emit SetAdmins(_admins.length);
    }

    function disableAdmins(address[] calldata _admins) public onlyOwner {
        require(_admins.length > 0, "Invalid Parameter!");
        for (uint i = 0; i < _admins.length; i++) {
            adminAddresses[_admins[i]] = false;
        }
        emit DisableAdmins(_admins.length);
    }

    // withdraw
    function withdraw() public onlyOwner {
        // This will payout the owner 100% of the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

}