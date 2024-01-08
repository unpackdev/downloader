// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./Proxied.sol";

import "./ChickenNoodleLookupLibrary.sol";

import "./ITraits.sol";
import "./IChickenNoodle.sol";

contract ChickenNoodle is ERC721Upgradeable, Proxied {
    // a mapping from an address to whether or not it can mint / finalize
    mapping(address => bool) controllers;

    event TokenStolen(address owner, address thief, uint256 tokenId);

    // number of tokens have been minted so far
    uint16 public minted;

    // max number of tokens that can be minted - 50000 in production
    uint256 public MAX_TOKENS;
    // number of tokens that can be claimed for free - 20% of MAX_TOKENS
    uint256 public PAID_TOKENS;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => IChickenNoodle.ChickenNoodleTraits) public tokenTraits;

    // reference to Traits
    ITraits public traits;
    // farm address to allow transfer
    address public farm;

    // /**
    //  * initializes contract and rarity tables
    //  */
    // constructor(address _traits, uint256 _maxTokens) {
    //     initialize(_traits, _maxTokens);
    // }

    /**
     * initializes contract and rarity tables
     */
    function initialize(address _traits, uint256 _maxTokens) public proxied {
        __ERC721_init('EggHeist.game', 'EGGHEIST');

        traits = ITraits(_traits);

        MAX_TOKENS = _maxTokens;
        PAID_TOKENS = _maxTokens / 5;
    }

    function totalSupply() public view virtual returns (uint256) {
        return minted;
    }

    function totalNoodles() public view returns (uint16) {
        return ChickenNoodleLookupLibrary.totalNoodles(address(this));
    }

    function getTokensForOwner(
        address tokenOwner,
        uint16 limit,
        uint16 page
    ) public view returns (uint16[] memory) {
        return
            ChickenNoodleLookupLibrary.getTokensForOwner(
                address(this),
                tokenOwner,
                limit,
                page
            );
    }

    function getTokenTypesBalanceOf(address tokenOwner)
        public
        view
        returns (
            uint16 chickens,
            uint16 noodles,
            uint16 tier5Noodles,
            uint16 tier4Noodles,
            uint16 tier3Noodles,
            uint16 tier2Noodles,
            uint16 tier1Noodles,
            uint16 unminted
        )
    {
        return
            ChickenNoodleLookupLibrary.getTokenTypesBalanceOf(
                address(this),
                tokenOwner
            );
    }

    function getMintedForOwner(
        address tokenOwner,
        uint16 limit,
        uint16 page
    ) public view returns (uint16[] memory) {
        return
            ChickenNoodleLookupLibrary.getMintedForOwner(
                address(this),
                tokenOwner,
                limit,
                page
            );
    }

    function getUnmintedForOwner(
        address tokenOwner,
        uint16 limit,
        uint16 page
    ) public view returns (uint16[] memory) {
        return
            ChickenNoodleLookupLibrary.getUnmintedForOwner(
                address(this),
                tokenOwner,
                limit,
                page
            );
    }

    function getChickensForOwner(
        address tokenOwner,
        uint16 limit,
        uint16 page
    ) public view returns (uint16[] memory) {
        return
            ChickenNoodleLookupLibrary.getChickensForOwner(
                address(this),
                tokenOwner,
                limit,
                page
            );
    }

    function getNoodlesForOwner(
        address tokenOwner,
        uint16 limit,
        uint16 page
    ) public view returns (uint16[] memory) {
        return
            ChickenNoodleLookupLibrary.getNoodlesForOwner(
                address(this),
                tokenOwner,
                limit,
                page
            );
    }

    function mint(address to, uint16 tokenId) external {
        require(controllers[msg.sender], 'Only controllers can mint');
        require(tokenId <= MAX_TOKENS, 'All tokens minted');
        minted++;
        _safeMint(to, tokenId);
    }

    function finalize(
        uint16 tokenId,
        IChickenNoodle.ChickenNoodleTraits memory t,
        address thief
    ) external {
        require(controllers[msg.sender], 'Only controllers can finalize');

        tokenTraits[tokenId] = t;

        if (thief != address(0x0) && thief != ownerOf(tokenId)) {
            _transfer(ownerOf(tokenId), thief, tokenId);
            emit TokenStolen(ownerOf(tokenId), thief, tokenId);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(tokenTraits[tokenId].minted, 'Token is not fully minted yet');

        // Hardcode the Farm's approval so that users don't have to waste gas approving
        if (_msgSender() == farm) {
            _transfer(from, to, tokenId);
        } else {
            super.transferFrom(from, to, tokenId);
        }
    }

    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyProxyAdmin {
        controllers[controller] = true;
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyProxyAdmin {
        controllers[controller] = false;
    }

    /**
     * called after deployment so if we need to replace the metadata render
     * @param _traits the address of the Traits render
     */
    function setTraits(address _traits) external onlyProxyAdmin {
        traits = ITraits(_traits);
    }

    /**
     * updates the number of tokens for sale
     */
    function setPaidTokens(uint256 _paidTokens) external onlyProxyAdmin {
        PAID_TOKENS = _paidTokens;
    }

    /**
     * called after deployment so that the contract can get random noodle thieves
     * @param _farm the address of the HenHouse
     */
    function setFarm(address _farm) external onlyProxyAdmin {
        farm = _farm;
    }

    /** RENDER */

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );
        return traits.tokenURI(tokenId);
    }
}
