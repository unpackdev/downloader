// SPDX-License-Identifier: MIT

/// @title The Salty Pirate Crew mint contract

// SECURITY CONCERNS + BUG BOUNTIES:
// Please message us on discord: https://discord.com/invite/K3dtVHdEDT 

// Warning: This contract should NOT be interacted with. This is the logic contract.
// Mints in this contract are NOT stored on the main architecture and will not be acknowledged.
// All calls should be made through the proxy address. See openzeppelin docs for more information.  

pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./PaymentSplitterUpgradeable.sol";

contract SaltyPirateCrew is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable, PaymentSplitterUpgradeable {
    uint256 public constant maxSupply = 10000;
    uint256 public constant price = 60000000000000000;
    uint256 public giftBuffer;
    string public baseURI;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address[] memory payees, uint256[] memory shares, string memory baseURI_) initializer public {
        __ERC721_init("SaltyPirateCrew", "SPC");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __PaymentSplitter_init(payees, shares);
        baseURI = baseURI_;
        giftBuffer = 100;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function giftDecrement() internal {
        giftBuffer = giftBuffer-1;
    }

    // Mint function uses OpenZeppelin's mint functions to ensure safety.
    // Requires ensure that minting is 1-5. Does not allow to mint beyond the gift buffer.
    function mint(uint256 mintAmount) public payable whenNotPaused {
        require(mintAmount > 0, "Can't mint 0");
        require(mintAmount + _tokenIdCounter.current() <= maxSupply - giftBuffer, "Minting more than max supply");
        require(mintAmount < 6, "Max mint is 5");
        require(msg.value == price * mintAmount, "wrong price");

        for(uint i = 0; i < mintAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    // Gift function that will send the address passed the gift amount
    function gift(uint256 giftAmount, address to) public onlyOwner {
        require(giftAmount > 0, "Mint != 0");
        require(giftAmount + _tokenIdCounter.current() <= maxSupply, "Gift > Max");

        for(uint i = 0; i < giftAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            giftDecrement();
            _safeMint(to, tokenId);
        } 
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Changes the base URI
    function _setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}