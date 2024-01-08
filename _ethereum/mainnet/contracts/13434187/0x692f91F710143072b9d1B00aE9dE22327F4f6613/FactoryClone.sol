// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Clones.sol";
import "./Pausable.sol";
import "./IFactoryClone.sol";
import "./ERC721Preset.sol";

//  .d8888b.
// d88P  "88b
// Y88b. d88P
//  "Y8888P"
// .d88P88K.dNFT
// 888"  Y888P"
// Y88b .d8888b
//  "Y8888P" Y88b
// ａｍｐｅｒｓａｎｄ

contract FactoryClone is Ownable, Pausable, IFactoryClone {
    /**
     * ERROR code handle
     * CRC32 encode
     * 736d4bef FactoryClone: price not correct
     * 17854c4f ERC721Preset: require eth more than 0
     */
    mapping(address => TokenBag) tokenList;
    address immutable _tokenImplementation;

    struct FactoryInfo {
        uint256 _fees;
        uint256 _createPrice;
        address _feesAddres;
    }

    struct TokenBag {
        address[] tokenAddress;
    }

    FactoryInfo private factory;

    constructor() {
        factory._fees = 5;
        factory._feesAddres = 0x1508a9abf38a6Ca3E7B13cD3cb3DAC5F73aA22FB;
        _tokenImplementation = address(new ERC721Preset());
    }

    function createToken(ERC721Preset.tokenInfo calldata token)
        external
        payable
        whenNotPaused
        returns (address)
    {
        require(msg.value >= createPrice(), "736d4bef");
        address clone = Clones.clone(_tokenImplementation);
        ERC721Preset(clone).initialize(token, _msgSender());
        emit TokenCreated(
            token._name,
            token._symbol,
            token._baseTokenURI,
            address(clone)
        );
        tokenList[_msgSender()].tokenAddress.push(address(clone));
        return address(clone);
    }

    function getTokenAddress(address _address)
        public
        view
        virtual
        returns (address[] memory)
    {
        return tokenList[_address].tokenAddress;
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function withdrawAll() public payable onlyOwner {
        require(address(this).balance > 0, "17854c4f");
        payable(msg.sender).transfer(address(this).balance);
    }

    function fees() public view virtual override returns (uint256) {
        return factory._fees;
    }

    function setFees(uint256 price) public onlyOwner {
        factory._fees = price;
        emit FeesUpdated(price);
    }

    function feesAddress() public view virtual override returns (address) {
        return factory._feesAddres;
    }

    function setFeesAddress(address to) public onlyOwner {
        factory._feesAddres = to;
        emit FeesAddressChanged(to);
    }

    function createPrice() public view returns (uint256) {
        return factory._createPrice;
    }

    function setCreatePrice(uint256 price) public onlyOwner {
        factory._createPrice = price;
        emit createPriceUpdated(price);
    }
}
