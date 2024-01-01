//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC721Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

error InvalidInput();
error MaxSupplyReached();

contract Gen1PassHolders is
    ERC721Upgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    UUPSUpgradeable
{
    string internal baseURI;
    string public hiddenURI;

    uint256 public MAX_SUPPLY;
    uint256 public numberAirdropped;

    bool public revealed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) public initializer {
        __ERC721_init("GEN1 Pass Holders", "GEN1PASS");
        __ERC2981_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _transferOwnership(_owner);

        MAX_SUPPLY = 500;
        baseURI = "";
        hiddenURI = "https://beaigen1.s3.amazonaws.com/nft/metadata/pre_reveal.json";
    }

    // =========================================================================
    //                              Token Logic
    // =========================================================================

    function airdrop(
        address[] calldata owners,
        uint256[] calldata tokenIds
    ) external onlyOwner {
        uint256 size = owners.length;
        if (tokenIds.length != size) {
            revert InvalidInput();
        }
        if (numberAirdropped + size > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        for (uint256 i = 0; i < size;) {
            _mint(owners[i], tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        unchecked {
            numberAirdropped += size;
        }
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setHiddenURI(string memory _hiddenURI) external onlyOwner {
        hiddenURI = _hiddenURI;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!revealed) {
            return hiddenURI;
        }

        return super.tokenURI(tokenId);
    }

    function setSupply(uint256 _newSupply) external onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // =========================================================================
    //                                  ERC165
    // =========================================================================

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId)
            || ERC2981Upgradeable.supportsInterface(interfaceId)
            || super.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                                 ERC2891
    // =========================================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}
