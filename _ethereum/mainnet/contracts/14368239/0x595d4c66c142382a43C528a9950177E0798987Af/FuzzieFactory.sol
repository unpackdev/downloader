// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./Fuzzie.sol";

contract FuzzieFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;

    string _name = "MetaFuzzies Sale";
    string baseTokenUri = 'ipfs://Qmc3iUWNzubMw9oibzzCUp6Eak38UcTpkHu6aQBZCpTNYN/';
    string contractUri = 'ipfs://QmWyajC5HmoBgxe38nk2wnuyXiwHzH1ppBT48aJYLpyeCU';

    /*
     * Three different options for minting Fuzzies (basic, premium, and gold).
     */
    uint256 NUM_OPTIONS = 2;
    uint256 SINGLE_FUZZIE_OPTION = 0;
    uint256 FUZZIE_PACK = 1;
    uint256 FUZZIES_IN_PACK = 5;

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;

        fireTransferEvents(address(0), owner());
    }

    function name() override external view returns (string memory) {
        return _name;
    }

    function symbol() override external pure returns (string memory) {
        return "MFUZZ";
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
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() ||
                owner() == _msgSender()
        );
        require(canMint(_optionId));

        Fuzzie metaFuzzie = Fuzzie(nftAddress);
        if (_optionId == SINGLE_FUZZIE_OPTION) {
            metaFuzzie.factoryMint(_toAddress);
        } else if (_optionId == FUZZIE_PACK) {
            for (
                uint256 i = 0;
                i < FUZZIES_IN_PACK;
                i++
            ) {
                metaFuzzie.factoryMint(_toAddress);
            }
        }
    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }

        Fuzzie metaFuzzie = Fuzzie(nftAddress);
        uint256 fuzziesMinted = metaFuzzie.totalSupply();
        uint256 maxSupply = metaFuzzie.maxSupply();

        uint256 numItemsAllocated = 0;
        if (_optionId == SINGLE_FUZZIE_OPTION) {
            numItemsAllocated = 1;
        } else if (_optionId == FUZZIE_PACK) {
            numItemsAllocated = FUZZIES_IN_PACK;
        }
        return fuzziesMinted < (maxSupply - numItemsAllocated);
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseTokenUri, Strings.toString(_optionId), ".json"));
    }

    function setBaseTokenURI(string memory _newBaseToken) public onlyOwner {
        baseTokenUri = _newBaseToken;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractUri = _contractURI;
    }

    function setName(string memory _newName) public onlyOwner {
        _name = _newName;
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
