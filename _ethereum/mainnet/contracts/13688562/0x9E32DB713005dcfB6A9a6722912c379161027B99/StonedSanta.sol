// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title StonedSanta
 * StonedSanta - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract StonedSanta is ERC721, ContextMixin, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;

    address proxyRegistryAddress;
    string private _baseTokenURI;
    string constant name1 = "Stoned Santa";
    string constant symbol1 = "SNT";

    mapping(uint256 => bool) public _distributed;
    address private _preMintReceiver = 0x5e6CF45E44f03D1ee20d76e288D6f92368678185;
    address payable private _nftFund = payable(0x9e808c0FfB7ce205a8DA114419338b11b6134BaA);
    address payable private _developer = payable(0x0a310fa4FbCEe430f7CC3b06AB1B1e08f8cE7689);
    address private _collectionOwner = 0xA4168d8991656d58Cd0c2A0a037C0C3595C169c9;

    uint256 public constant MAX_SUPPLY = 20000;

    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(
        address _proxyRegistryAddress
    ) ERC721(name1, symbol1) {

        require(msg.sender == _preMintReceiver);
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(name1);
        
        setBaseTokenURI("ipfs://QmVMA8RFWVu2S1tKuBWee8ou2sCjbZF2feht1DGG548KGn/");
        transferOwnership(_collectionOwner);

        
        mintAllNFT();

    }

    /**
     * @dev Mints all tokens
     */
    function mintAllNFT() internal {
        ERC721._balances[_preMintReceiver] = MAX_SUPPLY;
        emit ConsecutiveTransfer(1, MAX_SUPPLY, address(0), _preMintReceiver);
    }

    function _afterTokenTransfer(address, address, uint256 tokenId) internal override {
        if(!_distributed[tokenId]) {
            _distributed[tokenId] = true;
        }
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = ERC721._owners[tokenId];
        if (!_distributed[tokenId] && tokenId > 0 && tokenId <= MAX_SUPPLY) {
            owner = _preMintReceiver;
        }
        require(owner != address(0), "Stoned Santa: owner query for nonexistent token");
        return owner;
    }

    function _exists(uint256 tokenId) internal view override returns (bool) {
        if (!_distributed[tokenId]) {
            return tokenId <= MAX_SUPPLY && tokenId > 0;
        } else {
            return ERC721._owners[tokenId] != address(0);
        }
    }

    function buySanta(uint id)
        public
        payable
    {
        require(id > 0 && id <= MAX_SUPPLY, "Invalid NFT id");
        require(!_distributed[id], "NFT has already been purchased");
        require(getPrice(id) == msg.value, "Ether value sent is not correct");

        _transfer(_preMintReceiver, msg.sender, id);
    }

    function getPrice(uint id)
        public
        pure
        returns (uint256 price)
    {
        require(id > 0 && id <= MAX_SUPPLY, "Invalid NFT id");

        if (id <= 500) {
            return 0; 
        } else if (id <= 2500) {
            return 0.03 ether;
        } else if (id <= 4000) {
            return 0.04 ether;
        } else if (id <= 5000) {
            return 0.05 ether;
        } else if (id <= 6000) {
            return 0.06 ether;
        } else if (id <= 7500) {
            return 0.07 ether;
        } else if (id <= 10000) {
            return 0.08 ether;
        } else if (id <= 12500) {
            return 0.1 ether;
        } else if (id <= 15000) {
            return 0.2 ether;
        } else if (id <= 17500) {
            return 0.3 ether;
        } else if (id <= 19986) {
            return 1 ether;
        } else if (id <= MAX_SUPPLY) {
            return 10 ether;
        }
    }

    function withdraw()
        public
        onlyOwner
    {
        address payable receiver = payable(owner());
        uint balance = address(this).balance;
        uint256 ownerAmount = balance * 85 / 100;
        uint256 fundAmount = balance * 10 / 100;
        uint256 devAmount = balance - ownerAmount - fundAmount;
        bool sent; 
        (sent,) = receiver.call{value: ownerAmount }("");
        require(sent, "Failed to send Ether");
        (sent,) = _nftFund.call{value: fundAmount }("");
        require(sent, "Failed to send Ether");
        (sent,) = _developer.call{value: devAmount }("");
        require(sent, "Failed to send Ether");
    } 

    function setBaseTokenURI(string memory _url) public onlyOwner {
        _baseTokenURI = _url;
    }

    function freezeMetadata(uint256 tokenId) external onlyOwner {
        require(bytes(baseTokenURI()).length != 0);
        emit PermanentURI(string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId))), tokenId);
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}
