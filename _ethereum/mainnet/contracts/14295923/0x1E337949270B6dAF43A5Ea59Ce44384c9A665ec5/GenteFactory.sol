// SPDX-License-Identifier: MIT
/**

 .d8888b.  888      d8b 888          888                             d8b
d88P  Y88b 888      Y8P 888          888                             Y8P
Y88b. d88P 888          888          888
 "Y88888"  88888b.  888 888888       88888b.   .d88b.  88888b.d88b.  888  .d88b.  .d8888b
.d8P""Y8b. 888 "88b 888 888          888 "88b d88""88b 888 "888 "88b 888 d8P  Y8b 88K
888    888 888  888 888 888          888  888 888  888 888  888  888 888 88888888 "Y8888b.
Y88b  d88P 888 d88P 888 Y88b.        888  888 Y88..88P 888  888  888 888 Y8b.          X88
 "Y8888P"  88888P"  888  "Y888       888  888  "Y88P"88888  888  888 888  "Y8888   88888P'
                                                     888
                                                     888
88888b.  888d888  .d88b.  .d8888b   .d88b.  88888b.  888888 .d8888b
888 "88b 888P"   d8P  Y8b 88K      d8P  Y8b 888 "88b 888    88K
888  888 888     88888888 "Y8888b. 88888888 888  888 888    "Y8888b.
888 d88P 888     Y8b.          X88 Y8b.     888  888 Y88b.       X88
88888P"  888      "Y8888   88888P'  "Y8888  888  888  "Y888  88888P'
888
888
8.d8888b.  888      d8b 888           .d8888b.                    888
d88P  Y88b 888      Y8P 888          d88P  Y88b                   888
Y88b. d88P 888          888          888    888                   888
 "Y88888"  88888b.  888 888888       888         .d88b.  88888b.  888888  .d88b.
.d8P""Y8b. 888 "88b 888 888          888  88888 d8P  Y8b 888 "88b 888    d8P  Y8b
888    888 888  888 888 888          888    888 88888888 888  888 888    88888888
Y88b  d88P 888 d88P 888 Y88b.        Y88b  d88P Y8b.     888  888 Y88b.  Y8b.
 "Y8888P"  88888P"  888  "Y888        "Y8888P88  "Y8888  888  888  "Y888  "Y8888
*/

pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./Gente.sol";

contract GenteFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    address public lootBoxNftAddress;
    string public baseURI = "https://www.lushus.art/collection/1/factory/";

    /*
     * Enforce the existence of only 100 OpenSea creatures.
     */
    uint256 GENTE_SUPPLY = 10000;

    /*
     * Three different options for minting Creatures (basic, premium, and gold).
     */
    uint256 NUM_OPTIONS = 4;
    uint256 SINGLE_GENTE_OPTION = 0;
    uint256 NICKLE_GENTE_PACK_OPTION = 1;
    uint256 DIME_GENTE_PACK_OPTION = 2;
    uint256 DUB_GENTE_PACK_OPTION = 3;

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;

        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "8bit Homies Gente Presell";
    }

    function symbol() override external pure returns (string memory) {
        return "GENTE";
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
                owner() == _msgSender() ||
                _msgSender() == lootBoxNftAddress
        );
        require(canMint(_optionId));

        Gente gente = Gente(nftAddress);
        if (_optionId == SINGLE_GENTE_OPTION) {
            gente.mintTo(_toAddress);
        } else if (_optionId == NICKLE_GENTE_PACK_OPTION) {
            for (
                uint256 i = 0;
                i < 5;
                i++
            ) {
                gente.mintTo(_toAddress);
            }
        }  else if (_optionId == NICKLE_GENTE_PACK_OPTION) {
            for (
                uint256 i = 0;
                i < 10;
                i++
            ) {
                gente.mintTo(_toAddress);
            }
        } else if (_optionId == DUB_GENTE_PACK_OPTION) {
            for (
                uint256 i = 0;
                i < 20;
                i++
            ) {
                gente.mintTo(_toAddress);
            }
        }
    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }

        Gente gente = Gente(nftAddress);
        uint256 genteSupply = gente.totalSupply();

        uint256 numItemsAllocated = 0;
        if (_optionId == SINGLE_GENTE_OPTION) {
            numItemsAllocated = 1;
        } else if (_optionId == NICKLE_GENTE_PACK_OPTION) {
            numItemsAllocated = 5;
        } else if (_optionId == DIME_GENTE_PACK_OPTION) {
            numItemsAllocated = 10;
        } else if (_optionId == DUB_GENTE_PACK_OPTION) {
            numItemsAllocated = 20;
        }
        return genteSupply < (GENTE_SUPPLY - numItemsAllocated);
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
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
