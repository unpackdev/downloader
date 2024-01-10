//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Strings.sol";

interface IGameObjectMaker {
    function isSaleClosed(uint256 gameObjectId) external returns (bool);
    function exists(uint256 id) external returns (bool);
    function mint(address _recipient, uint256 _gameObjectId, uint256 _amount) external;
    function openSale(uint256[] calldata _gameObjectIds) external;
    function openSingleSale(uint256 _gameObjectId) external;
    function closeSale(uint256[] calldata _gameObjectIds) external;
    function closeSingleSale(uint256 _gameObjectId) external;
    function getMintPrice(uint256 gameObjectId) external returns (uint256);
    function isPaidWithToken(uint256 gameObjectId) external returns (bool);
    function getTotalSupply(uint256 gameObjectId) external returns (uint256);
}

contract GameObjectXBMFMinter is Ownable {

    IGameObjectMaker gameObjectMaker;
    ERC20 paymentToken;
    ERC721 soda;

    mapping(uint256 => mapping(address => bool)) private whitelist;
    mapping(uint256 => mapping(address => bool)) private whitelistUsed;
    mapping(uint256 => mapping(address => uint256)) private whitelistMultiples;
    mapping(uint256 => bool) private needSoda;
    mapping(uint256 => uint256) private mintCounter;

    constructor(address _paymentToken, address _sodaAddress, address _gameObjectMaker) {
        soda = ERC721(_sodaAddress);
        paymentToken = ERC20(_paymentToken);
        gameObjectMaker = IGameObjectMaker(_gameObjectMaker);
    }

    // Getters

    function isWhitelisted(uint256 _gameObjectId, address _address) public view returns (bool) {
        return whitelist[_gameObjectId][_address];
    }

    function hasUsedWhitelist(uint256 _gameObjectId, address _address) public view returns (bool) {
        return whitelistUsed[_gameObjectId][_address];
    }

    function getWhitelistMultiple(uint256 _gameObjectId, address _address) public view returns (uint256) {
        return whitelistMultiples[_gameObjectId][_address];
    }

    function needsSoda(uint256 _gameObjectId) public view returns (bool) {
        return needSoda[_gameObjectId];
    }

    function getMintCounter(uint _gameObjectId) public view returns (uint256) {
        return mintCounter[_gameObjectId];
    }

    // Setters

    function setNeedSoda(uint256 _gameObjectId, bool _value) public onlyOwner {
        needSoda[_gameObjectId] = _value;
    }

    function setGameObjectMaker(address _maker) external onlyOwner {
        gameObjectMaker = IGameObjectMaker(_maker);
    }

    function addToWhitelist(uint256 _gameObjectId, address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_gameObjectId][_addresses[i]] = true;
        }
    }

    function addWhitelistMultiple(
        uint256 _gameObjectId,
        address[] memory _addresses,
        uint256[] memory _multiples
    ) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistMultiples[_gameObjectId][_addresses[i]] = _multiples[i];
        }
    }

    function removeFromWhitelist(uint256 _gameObjectId, address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address addr = _addresses[i];
            whitelist[_gameObjectId][addr] = false;
        }
    }

    function clearUsedWhitelist(uint256 _gameObjectId, address _address) public onlyOwner {
        whitelistUsed[_gameObjectId][_address] = false;
    }

    // Manage Sale

    function openSingleSale(uint256 _gameObjectId) external onlyOwner {
        gameObjectMaker.openSingleSale(_gameObjectId);
    }

    function closeSingleSale(uint256 _gameObjectId) external onlyOwner {
        gameObjectMaker.closeSingleSale(_gameObjectId);
    }

     // Mint

    function mintForWhitelist(uint256 _gameObjectId) external {
        require(gameObjectMaker.isSaleClosed(_gameObjectId) == false, "Sale is closed");
        require(whitelist[_gameObjectId][msg.sender] == true, "sender is not on whitelist");
        require(whitelistUsed[_gameObjectId][msg.sender] == false, "sender has already used whitelist");
        if (needSoda[_gameObjectId]) {
            require(soda.balanceOf(msg.sender) > 0, "You need a Soda to mint");
        }
        whitelistUsed[_gameObjectId][msg.sender] = true;

        uint256 amount = 1;
        if (whitelistMultiples[_gameObjectId][msg.sender] > 0) {
            amount = amount * whitelistMultiples[_gameObjectId][msg.sender];
        }

        address recipient = msg.sender;
       
        gameObjectMaker.mint(recipient, _gameObjectId, amount);
        mintCounter[_gameObjectId] = mintCounter[_gameObjectId] + amount;
    }
   
    function mintForToken(
        uint256 _gameObjectId,
        uint256 gameObjectAmount,
        uint256 paymentAmount
    ) external {

        require(
            gameObjectMaker.isSaleClosed(_gameObjectId) == false, 
            "Sale is closed"
        );

        if (needSoda[_gameObjectId]) {
            require(soda.balanceOf(msg.sender) > 0, "You need a Soda to mint");
        }

        require(
            paymentAmount == gameObjectAmount * gameObjectMaker.getMintPrice(_gameObjectId),
            "Purchase: Incorrect payment"
        );

        require(
            gameObjectMaker.exists(_gameObjectId),
            "MintForEther: gameObject does not exist"
        );

        require(
            gameObjectMaker.isPaidWithToken(_gameObjectId) == true,
            "MintForToken: can't use token to pay for this gameObject"
        );

        require(
            paymentToken.transferFrom(msg.sender, address(this), paymentAmount),
            "Transfer of token could not be made"
        );

        address recipient = msg.sender;
        gameObjectMaker.mint(recipient, _gameObjectId, gameObjectAmount);
        mintCounter[_gameObjectId] = mintCounter[_gameObjectId] + gameObjectAmount;
    }

    // Withdraw

    function withdraw() public payable onlyOwner {
        uint256 bal = address(this).balance;
        require(payable(msg.sender).send(bal));
    }

    function withdrawMintToken() public payable onlyOwner {
        uint256 bal = paymentToken.balanceOf(address(this));
        paymentToken.transfer(msg.sender, bal);
    }

    function withdrawToken(address _tokenAddress) public payable onlyOwner {
        ERC20 token = ERC20(_tokenAddress);
        uint256 bal = token.balanceOf(address(this));
        token.transfer(msg.sender, bal);
    }
}
