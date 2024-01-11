//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
import "./AdminManager.sol";

contract BredStrain is
    Initializable,
    ERC721AUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AdminManagerUpgradable
{
    string private _uri;

    function initialize(string memory uri) public initializer {
        __ERC721A_init("WEEDGANG.GAME - BRED STRAIN", "WG-BS");
        __Pausable_init_unchained();
        __ReentrancyGuard_init();
        __AdminManager_init();
        _uri = uri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mint(address account, uint256 quantity)
        external
        onlyAdmin
        whenNotPaused
        nonReentrant
    {
        _safeMint(account, quantity);
    }

    function batchMint(
        address[] calldata accounts,
        uint256[] calldata quantities
    ) external onlyAdmin whenNotPaused nonReentrant {
        for (uint256 i; i < accounts.length; ++i) {
            _safeMint(accounts[i], quantities[i]);
        }
    }

    function burn(uint256 id) external onlyAdmin whenNotPaused nonReentrant {
        _burn(id);
    }

    function batchBurn(uint256[] calldata tokens)
        external
        onlyAdmin
        whenNotPaused
        nonReentrant
    {
        for (uint256 i; i < tokens.length; ++i) {
            _burn(tokens[i]);
        }
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

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }
}
