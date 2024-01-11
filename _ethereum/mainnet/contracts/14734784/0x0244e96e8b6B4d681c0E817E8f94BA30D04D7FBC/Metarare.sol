// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";
import "./IFactoryERC721.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title Metarare
 * Metarare - a contract for my non-fungible metarares. ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract Metarare is ERC721, ContextMixin, NativeMetaTransaction, Ownable, FactoryERC721 {
    using SafeMath for uint256;

    address private _proxyRegistryAddress;
    string private _baseURIValue;

    uint256 _numOptions;

    /**
     * @dev The constructor of the contract.
     * @param newName The name of the token.
     * @param newSymbol The symbol of the token.
     * @param baseURI The baseURI of the token.
     * @param proxyRegistryAddress The proxy registry address.
     * @param newNumOptions The number of options in the factory contract.
    */
    constructor(string memory newName, string memory newSymbol, string memory baseURI, address proxyRegistryAddress, uint256 newNumOptions) ERC721(newName, newSymbol) {

        _baseURIValue = baseURI;
        _proxyRegistryAddress = proxyRegistryAddress;
        _numOptions = newNumOptions;

        _initializeEIP712(newName);

        // notify other of the options in the factory contract (see Opensea Creatures Factory for details.)
        fireTransferEvents(address(0), owner(), 0, _numOptions);
    }

    /**
    * @dev Returns the name of the NFT/Smart Contract.
    */
    function name() override(FactoryERC721,ERC721) public view returns (string memory) {
        return ERC721.name();
    }

    /**
    * @dev Returns the symbol of the NTF.
    */
    function symbol() override(FactoryERC721,ERC721) public view returns (string memory) {
        return ERC721.symbol();
    }

    /**
     * @dev Set the proxy registry address.
     * @param proxyRegistryAddress The proxyRegstryAddress
     */
    function setBaseURI(address proxyRegistryAddress) public onlyOwner {
        _proxyRegistryAddress = proxyRegistryAddress;
    }

    /**
     * @dev Set the base URI.
     * @param baseURI The uri which is prepended to the tokenID.
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURIValue = baseURI;
    }

    /**
     * @dev Returns the token URI for a given token ID.
     * @param tokenId The token ID.
     */
    function tokenURI(uint256 tokenId) override(ERC721,FactoryERC721) public view returns (string memory) {
        return string(abi.encodePacked(_baseURIValue, Strings.toString(tokenId),".json"));
    }

    /**
     * @dev Returns the base URI.
     */
    function _baseURI() override internal view virtual returns (string memory) {
        return _baseURIValue;
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    /**
     * Implements the factory interface of OpenSea IFactoryERC721.
     */
    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    /**
     * Sets the number of the options of the factory contract.
     */
    function setNumOptions(uint newNumOptions) public onlyOwner {
        require(newNumOptions > _numOptions, "newNumOptions must be bigger than numOptions");

        // perform state changes before emitting any events
        uint256 oldMaxOptions = _numOptions;
        _numOptions = newNumOptions;

        fireTransferEvents(address(0), owner(), oldMaxOptions, newNumOptions);
    }

    /**
     * Returns the number of options of the factory contract.
     */
    function numOptions() override public view returns (uint256) {
        return _numOptions;
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address prevOwner = owner();
        super.transferOwnership(newOwner);

        // Only transfer ownership of the options in the factory (as in the OpenSea CreatureFactory Contract)
        for (uint256 i = 0; i < _numOptions; i++) {
            if (!_exists(i)) {
                emit Transfer(prevOwner, newOwner, i);
            }
        }
    }

    function fireTransferEvents(address from, address to, uint256 start, uint256 end) private {
        for (uint256 i = start; i < end; i++) {
            emit Transfer(from, to, i);
        }
    }

    function mint(uint256 tokenId, address toAddress) override public {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
       
        assert(address(proxyRegistry.proxies(owner())) == _msgSender() || owner() == _msgSender());

        require(tokenId < _numOptions, "MetaRare Sale: tokenId has to be smaller than numOptions");

        // check if the token has already been minted
        require(!_exists(tokenId),"MetaRare Sale: Token has already been minted");

        // mint the token the a specific adress
        _safeMint(toAddress, tokenId);
    }

    /**
     * @dev Implmentation based on CreatureFactory from OpenSea. Implements the IFactoryERC721 Interface.
     */
    function canMint(uint256 tokenId) override public view returns (bool) {       
        // check if the token is on the valid range
        if (tokenId >= _numOptions) {
            return false;
        }
        // check if the token has already been minted
        return !_exists(tokenId);
    }

    /**
     * @dev Implmentation based on CreatureFactory from OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(address from, address to, uint256 tokenId) override public {
        if (_exists(tokenId)) {
            ERC721.transferFrom(from, to, tokenId);
            return;
        }
        mint(tokenId, to);
    }

    /**
     * @dev Implmentation based on CreatureFactory from OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator) override public view returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (owner() == _owner && address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        return ERC721.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev Implmentation based on CreatureFactory from OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 tokenId) override public view returns (address _owner) {
        if (_exists(tokenId)) {
            return ERC721.ownerOf(tokenId);
        }
        return owner();
    }

    /**
     * Used to withdraw.
     */
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

}
