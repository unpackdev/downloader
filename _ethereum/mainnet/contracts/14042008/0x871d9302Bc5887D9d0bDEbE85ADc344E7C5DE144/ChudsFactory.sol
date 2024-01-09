// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./Chuds.sol";

contract ChudsFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    string public baseURI = "ipfs://QmUYkTWGaQSGZUaPNRWE4SAj8EgakU6GoMcKhXd2zySjk3/";

    /*
     * Enforce the existence of only 3600 Chud creatures.
    */
    uint256 CREATURE_SUPPLY = 3600;

    /*
     * Two different options for minting random Chuds.
     */
    uint256 NUM_OPTIONS = 2;
    uint256 SINGLE_CREATURE_OPTION = 1;
    uint256 MULTIPLE_CREATURE_OPTION_TWO = 2;
    uint256 NUM_CREATURES_IN_MULTIPLE_CREATURE_OPTION_TWO = 4;


    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;
   
        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "CHUDS Factory";
    }

    function symbol() override external pure returns (string memory) {
        return "CHUDS";
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
        for (uint256 i = 1; i <= NUM_OPTIONS; i++) {
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
        require(canMint(_optionId),"NFT cannot mint");

        Chuds chudCreature = Chuds(nftAddress);
        if (_optionId == SINGLE_CREATURE_OPTION) {
            chudCreature.mintTo(_toAddress);
        } else if (_optionId == MULTIPLE_CREATURE_OPTION_TWO) {
            for (
                uint256 i = 0;
                i < NUM_CREATURES_IN_MULTIPLE_CREATURE_OPTION_TWO;
                i++
                ) {
                    chudCreature.mintTo(_toAddress);
                }
        } 

    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId < 1 || _optionId > NUM_OPTIONS) {
            return false;
        }

        Chuds chudCreature = Chuds(nftAddress);
        uint256 creatureSupply = chudCreature.totalSupply();

        uint256 numItemsAllocated = 0;
        if (_optionId == SINGLE_CREATURE_OPTION) {
            numItemsAllocated = 1;
        } else if (_optionId == MULTIPLE_CREATURE_OPTION_TWO) {
            numItemsAllocated = NUM_CREATURES_IN_MULTIPLE_CREATURE_OPTION_TWO;
        }
        return creatureSupply < (CREATURE_SUPPLY - numItemsAllocated);
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId), ".json"));
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
