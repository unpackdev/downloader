// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./BunnyBabies.sol";
import "./ERC721Tradable.sol";

contract BunnyBabiesFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    string public baseURI = "https://bunnies.crocpot.io/factory/";

    uint256 TOTAL_SUPPLY = 10000;

    uint256 NUM_OPTIONS = 2;
    uint256 SINGLE_BUNNY_OPTION = 0;
    uint256 MULTIPLE_BUNNY_OPTION = 1;
    uint256 MIN_BUNNIES_IN_MULTIPLE_OPTION = 4;

    /// Temporary discount prices
    uint256 public priceSingle = .025 ether;
    uint256 public priceMultiple = .125 ether;

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;

        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "Bunny Baby Bundles";
    }

    function symbol() override external pure returns (string memory) {
        return "BBB";
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

        BunnyBabies bunnyBabies = BunnyBabies(nftAddress);
        if (_optionId == SINGLE_BUNNY_OPTION) {
            bunnyBabies.mintTo(_toAddress);
        } else if (_optionId == MULTIPLE_BUNNY_OPTION) {
            uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 4;
            uint256 count = MIN_BUNNIES_IN_MULTIPLE_OPTION + rand;
            for (
                uint256 i = 0;
                i < count;
                i++
            ) {
                bunnyBabies.mintTo(_toAddress);
            }
        }
    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }

        BunnyBabies bunnyBabies = BunnyBabies(nftAddress);
        uint256 bunnyBabiesSupply = bunnyBabies.totalSupply();

        uint256 numItemsAllocated = 0;
        if (_optionId == SINGLE_BUNNY_OPTION) {
            numItemsAllocated = 1;
        } else if (_optionId == MULTIPLE_BUNNY_OPTION) {
            numItemsAllocated = MIN_BUNNIES_IN_MULTIPLE_OPTION;
        }
        return bunnyBabiesSupply < (TOTAL_SUPPLY - numItemsAllocated);
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

    /**
     * Allow an airdrop an item for each address in an array (low-gas mint)
     */
    function airdrop(address[] calldata recipients) public onlyOwner {
        unchecked {
            BunnyBabies bunnyBabies = BunnyBabies(nftAddress);
            for (uint256 i = 0; i < recipients.length; i++) {
                bunnyBabies.mintTo(recipients[i]);
            }
        }
    }

    function updatePrice(uint256 _priceSingle, uint256 _priceMultiple) public onlyOwner {
        priceSingle = _priceSingle;
        priceMultiple = _priceMultiple;
    }

    function mintOneWithDiscount() public payable{
        require(canMint(SINGLE_BUNNY_OPTION));

        require(priceSingle <= msg.value, "Insufficient ETH");

        (bool _success,) = owner().call{value: msg.value}("");
        require(_success);

        BunnyBabies bunnyBabies = BunnyBabies(nftAddress);
        bunnyBabies.mintTo(_msgSender());
    }

    function mintMultipleWithDiscount() public payable {
        require(canMint(MULTIPLE_BUNNY_OPTION));

        require(priceMultiple <= msg.value, "Insufficient ETH");

        (bool _success,) = owner().call{value: msg.value}("");
        require(_success);

        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 4;
        uint256 count = MIN_BUNNIES_IN_MULTIPLE_OPTION + rand;
        BunnyBabies bunnyBabies = BunnyBabies(nftAddress);
        for (
            uint256 i = 0;
            i < count;
            i++
        ) {
            bunnyBabies.mintTo(_msgSender());
        }
    }
}