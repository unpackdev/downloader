// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ImportsManager.sol";
import "./IVestingControllerERC721.sol";

/// @title Rand.network ERC721 Investors NFT contract
/// @author @adradr - Adrian Lenard
/// @notice Holds NFTs for early investors
/// @dev Interacts with Rand VestingController

contract InvestorsNFT is
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    ImportsManager
{
    // Events
    event BaseURIChanged(string baseURI);
    event ContractURIChanged(string contractURI);

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    string public baseURI;
    CountersUpgradeable.Counter internal _tokenIdCounter;
    enum TokenLevel {
        BLACK,
        GOLD,
        RED,
        BLUE
    } // Priority order: 0 - Black, 1 - Gold, 2 - Red, 3 - Blue
    mapping(uint256 => TokenLevel) internal _tokenLevel;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Initializer allow proxy scheme
    /// @dev for upgradability its necessary to use initialize instead of simple constructor
    /// @param _erc721_name Name of the token like `Rand Vesting Controller ERC721`
    /// @param _erc721_symbol Short symbol like `vRND`
    /// @param _registry is the address of address registry

    function initialize(
        string calldata _erc721_name,
        string calldata _erc721_symbol,
        IAddressRegistry _registry
    ) public initializer {
        __ERC721_init(_erc721_name, _erc721_symbol);
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __ImportsManager_init();

        REGISTRY = _registry;

        address _multisigVault = REGISTRY.getAddressOf(REGISTRY.MULTISIG());
        address _vcAddress = REGISTRY.getAddressOf(
            REGISTRY.VESTING_CONTROLLER()
        );
        _grantRole(DEFAULT_ADMIN_ROLE, _multisigVault);
        _grantRole(PAUSER_ROLE, _multisigVault);
        _grantRole(MINTER_ROLE, _multisigVault);
        _grantRole(MINTER_ROLE, _vcAddress);

        // Increment counter to start from 1
        _tokenIdCounter.increment();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Mints a new NFT for an investor
    /// @dev Only the VestingController can mint NFTs
    /// @param to is the address of the investor
    /// @param tokenLevel is the level of the NFT
    /// @return tokenId of the NFT
    function mintInvestmentNFT(
        address to,
        TokenLevel tokenLevel
    ) external whenNotPaused onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        tokenId = _safeMint(to);
        _tokenLevel[tokenId] = tokenLevel;
        return tokenId;
    }

    function _safeMint(address to) internal returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        return tokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function burn(uint256 tokenId) public virtual override whenNotPaused {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable) {
        (
            uint256 rndTokenAmount,
            uint256 rndClaimedAmount
        ) = IVestingControllerERC721(
                REGISTRY.getAddressOf(REGISTRY.VESTING_CONTROLLER())
            ).getInvestmentInfoForNFT(tokenId);

        bool isClaimedAll = rndTokenAmount == rndClaimedAmount;
        require(
            isClaimedAll,
            "NFT: Transfer of token is prohibited until investment is totally claimed"
        );
        super._transfer(from, to, tokenId);
    }

    function setBaseURI(
        string memory newURI
    ) public whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = newURI;
        emit BaseURIChanged(baseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _tokenLevelToString(
        TokenLevel level
    ) internal pure returns (string memory) {
        if (level == TokenLevel.BLACK) {
            return "BLACK";
        } else if (level == TokenLevel.GOLD) {
            return "GOLD";
        } else if (level == TokenLevel.RED) {
            return "RED";
        } else if (level == TokenLevel.BLUE) {
            return "BLUE";
        } else {
            revert("Unknown token level");
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable) returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURIString = _baseURI();

        (
            uint256 rndTokenAmount,
            uint256 rndClaimedAmount
        ) = IVestingControllerERC721(
                REGISTRY.getAddressOf(REGISTRY.VESTING_CONTROLLER())
            ).getInvestmentInfoForNFT(tokenId);

        TokenLevel tokenLevel = _tokenLevel[tokenId];
        bool isClaimedAll = rndTokenAmount == rndClaimedAmount;

        // Return token level instead of tokenId
        return
            bytes(baseURIString).length > 0
                ? isClaimedAll
                    ? string(abi.encodePacked(baseURI, "claimed"))
                    : string(
                        abi.encodePacked(
                            baseURI,
                            _tokenLevelToString(tokenLevel)
                        )
                    )
                : "";
    }

    function contractURI() public view returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(_baseURI(), "contract_uri"))
                : "";
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
