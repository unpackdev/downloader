// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./CryptoKangaroo.sol";

contract CryptoKangarooFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    string public baseURI = "https://ipfs.io/ipfs/bafkreiehamt47n2h43abrspermqs3zpsnkgvfiz4hqk5hkni35npbvztea";

    /*
     * Enforce the existence of only 100 OpenSea creatures. 
     */
    uint256 CRYPTOKANGAROO_SUPPLY = 2000;

    /*
     * Three different options for minting Creatures (basic, premium, and gold).
     */
    uint256 NUM_OPTIONS = 1;
    uint256 SINGLE_OPTION = 0;

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;
        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "Crypto Kangaroo Item Sale";
    }

    function symbol() override external pure returns (string memory) {
        return "CryptoKangarooFactory";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function numOptions() override public view returns (uint256) {
        return NUM_OPTIONS;
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function mint(uint256 _optionId, address _toAddress) override public {
        // Must be sent from the owner proxy or owner 
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() ||
                owner() == _msgSender()
        );
        require(canMint(_optionId));
        CryptoKangaroo ck = CryptoKangaroo(nftAddress);
        ck.mintTo(_toAddress);
    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }
        CryptoKangaroo ck = CryptoKangaroo(nftAddress);
        uint256 birdSupply = ck.totalSupply();
        return birdSupply < (CRYPTOKANGAROO_SUPPLY - 1);
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        // return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
        return baseURI;
    }

    /**
     * Hack to get things to work automatically on OpenSea. 
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
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
    function ownerOf(uint256) public view returns (address _owner) {
        return owner();
    }
}
