//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Counters.sol";
import "./PausableUpgradeable.sol";
import "./AdminManager.sol";

contract BredStrain is
    Initializable,
    ERC721Upgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AdminManagerUpgradable
{
    event Breed(
        uint256 indexed strainId,
        uint256 indexed seedId,
        uint32 size,
        uint32 thc,
        uint32 terpenes
    );

    using Counters for Counters.Counter;

    struct CoreTraits {
        uint32 size;
        uint32 thc;
        uint32 terpenes;
        uint32 deathTime;
    }

    Counters.Counter private _idCounter;

    uint256 public bredSupply;
    string private _uri;
    mapping(uint256 => CoreTraits) private _coreTraits;

    function initialize(string memory uri) public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained("WEEDGANG.GAME - BRED STRAIN", "WG-BS");
        __Pausable_init_unchained();
        __ReentrancyGuard_init();
        __AdminManager_init();
        _uri = uri;
    }

    function breedMint(
        address account,
        uint256 seedId,
        CoreTraits memory traits
    ) external onlyAdmin whenNotPaused {
        _idCounter.increment();
        uint256 id = _idCounter.current();
        _coreTraits[id] = traits;
        _safeMint(account, id);
        bredSupply++;

        emit Breed(id, seedId, traits.size, traits.thc, traits.terpenes);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function setUri(string memory uri) external onlyAdmin {
        _uri = uri;
    }

    function coreTraits(uint256 id) external view returns (CoreTraits memory) {
        return _coreTraits[id];
    }

    function burn(uint256 id) external onlyAdmin whenNotPaused {
        _burn(id);
        bredSupply--;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }
}
