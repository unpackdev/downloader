// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./Cards.sol";

// Based on the open sea Creature Factory contract
contract CardsFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    string public baseURI = "https://parablenft.com/static/metadata/";  // metadata for opensea shop buy options

    uint256 CREATURE_SUPPLY = 42000;

    /*
     * different options for minting Cards.
     */
    uint256 NUM_OPTIONS = 14;

    uint256 NUM_CREATURES_IN_MULTIPLE_CREATURE_OPTION = 5;

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;

        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "Parable";
    }

    function symbol() override external pure returns (string memory) {
        return "PAR";
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

        require(canMint(_optionId), "Pack option sold out. Price has increased, pick a different option.");

        Cards parableNft = Cards(nftAddress);
        if (_optionId == 0 || _optionId == 2 || _optionId == 4 || _optionId == 6 || _optionId == 8 || _optionId == 10 || _optionId == 12 || _optionId == 13 ) {
            parableNft.mintNftTo(_toAddress);
        } else if (_optionId == 1 || _optionId == 3 || _optionId == 5 || _optionId == 7 || _optionId == 9 || _optionId == 11 ) {
            for (
                uint256 i = 0;
                i < NUM_CREATURES_IN_MULTIPLE_CREATURE_OPTION;
                i++
            ) {
                parableNft.mintNftTo(_toAddress);
            }
        }
    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }

        Cards parableNft = Cards(nftAddress);
        uint256 creatureSupply = parableNft.totalSupply();

        if (_optionId == 0) {
            if (creatureSupply >= 1000) {return false;}
        } else if (_optionId == 1) {
            if (creatureSupply > 995) {return false;}
        } else if (_optionId == 2) {
            if (creatureSupply >= 6500) {return false;}
        } else if (_optionId == 3) {
            if (creatureSupply > 6495) {return false;}
        } else if (_optionId == 4) {
            if (creatureSupply >= 15500) {return false;}
        } else if (_optionId == 5) {
            if (creatureSupply > 15495) {return false;}
        } else if (_optionId == 6) {
            if (creatureSupply >= 27500) {return false;}
        } else if (_optionId == 7) {
            if (creatureSupply > 27495) {return false;}
        } else if (_optionId == 8) {
            if (creatureSupply >= 39500) {return false;}
        } else if (_optionId == 9) {
            if (creatureSupply > 39495) {return false;}
        } else if (_optionId == 10) {
            if (creatureSupply >= 41500) {return false;}
        } else if (_optionId == 11) {
            if (creatureSupply > 41495) {return false;}
        } else if (_optionId == 12) {
            if (creatureSupply >= 41900) {return false;}
        } else if (_optionId == 13) {
            if (creatureSupply >= 42000) {return false;}
        }

        return true;
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId), ".json"));
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
