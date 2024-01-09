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
}

contract GameObjectEthMinter is Ownable {

    uint256 public constant WHITE_LIST_LAND_AMOUNT = 10;

    ERC721 soda;
    IGameObjectMaker gameObjectMaker;
    uint256 whitelistLandAmount;
    bool needSoda;

    mapping(address => bool) private whitelist;
    mapping(address => bool) private whitelistUsed;
    mapping(address => uint8) private whitelistMultiples;

    constructor(address _sodaAddress, address _gameObjectMaker) {
        needSoda = true;
        soda = ERC721(_sodaAddress);
        gameObjectMaker = IGameObjectMaker(_gameObjectMaker);
        whitelistLandAmount = WHITE_LIST_LAND_AMOUNT;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function getWhitelistMultiple(address _address) public view returns (uint8) {
        return whitelistMultiples[_address];
    }

    function hasUsedWhitelist(address _address) public view returns (bool) {
        return whitelistUsed[_address];
    }

    // Setters

    function setNeedSoda(bool _needSoda) external onlyOwner {
        needSoda = _needSoda;
    }

    function setGameObjectMaker(address _maker) external onlyOwner {
        gameObjectMaker = IGameObjectMaker(_maker);
    }

    function setSodaAddress(address _address) external onlyOwner {
        soda = ERC721(_address);
    }

    // Manage Sale

    function openSingleSale(uint256 _gameObjectId) external onlyOwner {
        gameObjectMaker.openSingleSale(_gameObjectId);
    }

    function closeSingleSale(uint256 _gameObjectId) external onlyOwner {
        gameObjectMaker.closeSingleSale(_gameObjectId);
    }

    function openSale(uint256[] calldata _gameObjectIds) external onlyOwner {
        gameObjectMaker.openSale(_gameObjectIds);
    }

    function closeSale(uint256[] calldata _gameObjectIds) external onlyOwner {
        gameObjectMaker.closeSale(_gameObjectIds);
    }

    function addToWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function addWhitelistMultiple(
        address[] memory _addresses,
        uint8[] memory multiples
    ) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistMultiples[_addresses[i]] = multiples[i];
        }
    }

    function removeFromWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address addr = _addresses[i];
            whitelist[addr] = false;
        }
    }

    function clearUsedWhitelist(address _address) public onlyOwner {
        whitelistUsed[_address] = false;
    }

    // Mint

    function mintForWhitelist() public {
        require(gameObjectMaker.isSaleClosed(0) == false, "Sale is closed");
        require(whitelist[msg.sender] == true, "sender is not on whitelist");
        require(whitelistUsed[msg.sender] == false, "sender has already used whitelist");
        whitelistUsed[msg.sender] = true;

        uint8 amount = 10;
        if (whitelistMultiples[msg.sender] > 0) {
            amount = amount * whitelistMultiples[msg.sender];
        }

        address recipient = msg.sender;
        uint256 gameObjectId = 0;
        // assumes common land has id 0
        gameObjectMaker.mint(recipient, gameObjectId, amount);
    }

    function mintForEther(uint256 gameObjectId, uint256 amount) external payable {
        require(
            gameObjectMaker.isSaleClosed(gameObjectId) == false, 
            "Sale is closed"
        );

        if (needSoda) {
            require(soda.balanceOf(msg.sender) > 0, "You need a Soda to mint");
        }

        require(
            msg.value == amount * gameObjectMaker.getMintPrice(gameObjectId),
            "Purchase: Incorrect payment"
        );

        require(
            gameObjectMaker.exists(gameObjectId),
            "MintForEther: gameObject does not exist"
        );

        require(
            gameObjectMaker.isPaidWithToken(gameObjectId) == false,
            "MintForEther: can't use ether to pay for this gameObject"
        );

        address recipient = msg.sender;

        gameObjectMaker.mint(recipient, gameObjectId, amount);
    }

    // Withdraw

    function withdraw() public payable onlyOwner {
        uint256 bal = address(this).balance;
        require(payable(msg.sender).send(bal));
    }

    function withdrawToken(address _tokenAddress) public payable onlyOwner {
        ERC20 token = ERC20(_tokenAddress);
        uint256 bal = token.balanceOf(address(this));
        token.transfer(msg.sender, bal);
    }
}
