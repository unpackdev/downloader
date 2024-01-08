// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./Token.sol";

/**
 * @title The Mike Tyson NFT Collection by Cory Van Lew 
 * An NFT powered by Ether Cards - https://ether.cards
 */

contract TokenFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    uint256      public       HG2G = 42;

    address public proxyRegistryAddress;
    address public nftAddress;
    string  public baseURI = "https://client-metadata.ether.cards/api/tyson/collection/";

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;

        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "The Mike Tyson NFT Collection Sale";
    }

    function symbol() override external pure returns (string memory) {
        return "TNFT";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function numOptions() override public view returns (uint256) {
        Token token = Token(nftAddress);
        return token.numSeries();
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < numOptions(); i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function mint(uint256 _optionId, address _toAddress) override public {

        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() ||
                owner() == _msgSender() 
        );
        Token token = Token(nftAddress);
        require(_optionId < numOptions(), "Series does not exist");
        require(token.available(_optionId) > 0, "No more tokens available in this series");
        
        token.mintTo(_toAddress,_optionId);

    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        Token token = Token(nftAddress);
        if (_optionId >= numOptions()) {
            return false;
        }
        return token.available(_optionId) > 0;
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    function setBaseURI(string memory _base) external onlyOwner {
        baseURI = _base;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }
}
