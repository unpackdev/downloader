// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./Address.sol";

contract GameOfSnakesNFT is ERC721Tradable {
    using Address for address;

    uint256 public pricePreIco;
    uint256 public price;
    uint256 public constant preIcoSupply = 2000;
    uint256 public constant maxSupply = 10000;
    uint256 public buyLimit;
    address public operator;
    mapping(address => uint256) allowList;

    string private _baseURIPrefix;

    modifier onlyOperator() {
        require(operator == _msgSender(), "caller is not the operator");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _pricePreICO,
        uint256 _startPrice,
        uint256 _buyLimit,
        address _proxyRegistryAddress
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        _baseURIPrefix = _uri;
        pricePreIco = _pricePreICO;
        price = _startPrice;
        buyLimit = _buyLimit;
        operator = msg.sender;
        allowList[msg.sender] = 0x01;
    }

    function baseTokenURI() public view override returns (string memory) {
        return _baseURIPrefix;
    }

    function setBaseURI(string memory newUri) external onlyOwner {
        _baseURIPrefix = newUri;
    }

    function setPricePreICO(uint256 newPrice) external onlyOwner {
        pricePreIco = newPrice;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setBuyLimit(uint256 newBuyLimit) external onlyOwner {
        buyLimit = newBuyLimit;
    }

    function setOperator(address newOperator) external onlyOwner {
        operator = newOperator;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function mintNFTs(uint256 quantity) external payable {
        require((totalSupply() + quantity) <= maxSupply, 'Max supply exceeded');
        if (_msgSender() != owner()) {
            if ((totalSupply() + quantity) <= preIcoSupply) {
                require((pricePreIco * quantity) == msg.value, 'Incorrect ETH value (preIco)');
                uint256 a = allowList[_msgSender()];
                require((a & 0x01) == 1, 'sender is not allowed');
                require(((a >> 1) + quantity) <= buyLimit, 'Buy limit exceeded (preIco)');
                allowList[_msgSender()] = (((a >> 1) + quantity) << 1) | 0x01;
            } else {
                require((price * quantity) == msg.value, 'Incorrect ETH value');
                uint256 a = allowList[_msgSender()];
                require(((a >> 1) + quantity) <= buyLimit, 'Buy limit exceeded');
                allowList[_msgSender()] = (((a >> 1) + quantity) << 1);
            }
            require(!_msgSender().isContract(), 'Contracts are not allowed');
        }
        for (uint256 i = 0; i < quantity; i++) {
            uint256 newTokenId = _getNextTokenId();
            _mint(_msgSender(), newTokenId);
            _incrementTokenId();
        }
    }

    function addToAllowList(address account) external onlyOperator {
        require(allowList[account] & 0x01 == 0, "account is already allowed");
        allowList[account] |= 0x01;
    }

    function addsToAllowList(address[] calldata accounts) external onlyOperator {
        for (uint256 i = 0; i < accounts.length; i++) {
            allowList[accounts[i]] |= 0x01;
        }
    }

    function removeFromAllowList(address account) external onlyOperator {
        require(allowList[account] & 0x01 == 1, "account does not allowed");
        allowList[account] = ((allowList[account] >> 1) << 1);
    }

    function isAllowed(address account) external view returns(bool) {
        return (allowList[account] & 0x01 == 1);
    }
}
