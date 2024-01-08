// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

/**
 * @title Pigeon Gang contract
 * @dev Extends openzeppelin ERC721 implementation
 */
contract PigeonGang is ContextMixin, ERC721Enumerable, NativeMetaTransaction {
    using SafeMath for uint256;

    uint256 public pigeonPrice = 0.06 ether;
    uint256 public pigeonSupply = 200;
    uint256 public pigeonPerWallet = 5;
    uint256 public pigeonPerTx = 2;
    uint256 public currentPledge = 0;

    bool public whitelistEnabled = false;

    mapping(address => bool) private _whitelist;
    mapping(address => uint256) public pledged;
    mapping(address => uint256) public claimed;

    address private _contractOwner;

    modifier contractOwnerOnly() {
        require(_contractOwner == _msgSender(), "PigeonGang: Caller is not the contract owner");
        _;
    }

    constructor() ERC721("Pigeon Gang", "PGN") {
        _setOwner(_msgSender());
        _initializeEIP712("Pigeon Gang");
    }

    /**
     * @dev Pledge for the purchase
     */
    function pledge(uint256 _amount) external payable {
        require((_amount + pledged[_msgSender()] + claimed[_msgSender()]) <= pigeonPerWallet, "PigeonGang: Each address can only purchase up to 5 pigeons.");
        require(_amount <= pigeonPerTx, "PigeonGang: Each address can only purchase up to 2 pigeons per transaction.");
        require(currentPledge.add(_amount) <= pigeonSupply, "PigeonGang: Purchase would exceed pigeons supply");
        require(pigeonPrice.mul(_amount) <= msg.value, "PigeonGang: Pigeon price is not correct");
        if (whitelistEnabled == true) {
            require(_whitelist[_msgSender()], "PigeonGang: Not on whitelist");
        }

        pledged[_msgSender()] += _amount;
        currentPledge += _amount;
    }

    /**
     * @dev Pigeons can be claimed anytime
     */
    function claim() external {
        uint256 supply = totalSupply();
        
        for (uint256 i = 0; i < pledged[_msgSender()]; i++) {
            _safeMint(_msgSender(), supply + i);
        }

        claimed[_msgSender()] += pledged[_msgSender()];
        pledged[_msgSender()] = 0;
    }

    /**
     * @dev Mints specific amount of pigeons to the address
     */
    function mint(uint256 _amount) public payable {
        uint256 supply = totalSupply();

        require((_amount + pledged[_msgSender()] + claimed[_msgSender()]) <= pigeonPerWallet, "PigeonGang: Each address can only purchase up to 5 pigeons.");
        require(_amount <= pigeonPerTx, "PigeonGang: Each address can only purchase up to 2 pigeons per transaction.");
        require(supply.add(_amount) <= pigeonSupply, "PigeonGang: Purchase would exceed pigeons supply");
        require(pigeonPrice.mul(_amount) <= msg.value, "PigeonGang: Pigeon price is not correct");
        if (whitelistEnabled == true) {
            require(_whitelist[_msgSender()], "PigeonGang: Not on whitelist");
        }

        uint256 i;

        for (i = 0; i < _amount; i++) {
            if (supply + i < pigeonSupply) {
                _safeMint(_msgSender(), supply + i);
            }
        }

        claimed[_msgSender()] += i;
    }

    /**
     * @dev Airdrops pigeons to the address
     * Can only be called by the current owner.
     */
    function airdropPigeons(uint256 _amount, address _recipient) public contractOwnerOnly {
        uint256 supply = totalSupply();

        require(supply.add(_amount) <= pigeonSupply, "PigeonGang: Airdrop would exceed pigeons supply");

        for (uint256 i = 0; i < _amount; i++) {
            if (supply + i < pigeonSupply) {
                _safeMint(_recipient, supply + i);
            }
        }
    }

    /**
     * @dev Airdrops one pigeon to many addresses
     * Can only be called by the current owner.
     */
    function airdropPigeonsToMany(address[] memory _recipients) external contractOwnerOnly {
        uint256 supply = totalSupply();

        require(supply.add(_recipients.length) <= pigeonSupply, "PigeonGang: Airdrop would exceed pigeons supply");

        for (uint256 i = 0; i < _recipients.length; i++) {
          airdropPigeons(1, _recipients[i]);
        }
    }

    /**
     * @dev Adds addresses to whitelist
     * Can only be called by the current owner.
     */
    function addToWhitelist(address[] memory _addresses) public contractOwnerOnly {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _whitelist[_addresses[i]] = true;
        }
    }

    /**
     * @dev Removes addresses to whitelist
     * Can only be called by the current owner.
     */
    function popFromWhitelist(address[] memory _addresses) public contractOwnerOnly {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _whitelist[_addresses[i]] = false;
        }
    }

    /**
     * @dev Returns true if the address is on whitelist
     */
    function isOnWhitelist(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    /**
     * @dev Flips whitelist state
     * Can only be called by the current owner.
     */
    function flipWhitelistState() public contractOwnerOnly {
        whitelistEnabled = !whitelistEnabled;
    }

    /**
     * @dev Sets a new price for the pigeon
     * Can only be called by the current owner.
     */
    function setPigeonPrice(uint256 _pigeonPrice) public contractOwnerOnly {
        pigeonPrice = _pigeonPrice;
    }

    /**
     * @dev Sets value of pigeon per wallet limit
     * Can only be called by the current owner.
     */
    function setPigeonPerWallet(uint256 _amount) public contractOwnerOnly {
        pigeonPerWallet = _amount;
    }

    /**
     * @dev Sets value of pigeon per transaction limit
     * Can only be called by the current owner.
     */
    function setPigeonPerTx(uint256 _amount) public contractOwnerOnly {
        pigeonPerTx = _amount;
    }

    /**
     * @dev Increments value of pigeons supply
     * Can only be called by the current owner.
     */
    function resupplyPigeons(uint256 _pigeonSupply) public contractOwnerOnly {
        pigeonSupply = totalSupply() + _pigeonSupply;
    }

    /**
     * @dev Withdraw specific amount from the balance.
     * Can only be called by the current owner.
     */
    function withdraw(address payable _to, uint256 _amount) public contractOwnerOnly {
        _to.transfer(_amount);
    }

    function baseTokenURI() public pure returns (string memory) {
        return "https://pigeongang.herokuapp.com/api/";
    }

    function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    /**
     * @dev Transfers ownership of the contract to a new address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual contractOwnerOnly {
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        _contractOwner = newOwner;
    }

    /**
     * Changes the sender of the transaction to a "0x00..." address
     */
    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    /**
     * Declaring fallback and recieve functions when using "payable" keyword in contract, since it is neccessary since solidity 0.6.0
     */
    fallback() external payable {}

    receive() external payable {}
}
