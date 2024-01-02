// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ERC1155Upgradeable.sol";
import "./ERC1155PausableUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./ERC1155URIStorageUpgradeable.sol";
import "./BaseUpgradeable.sol";
import "./Constants.sol";

contract ERC1155v2Upgradeable is BaseUpgradeable, ERC1155Upgradeable, ERC1155PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, ERC1155URIStorageUpgradeable {
    mapping(uint256 id => uint256) private _totalMinted;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address roleManager_, string memory uri_) public initializer {
        __BaseUpgradeable_init(roleManager_);
        __ERC1155_init(uri_);
        __ERC1155Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
    }

    function uri(uint256 id) public view override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable) returns (string memory) {
        return super.uri(id);
    }

    function setURI(string memory newuri) public onlyRole(OPERATOR_ROLE) {
        _setBaseURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
        _totalMinted[id] += amount;
    }

    function totalMinted(uint256 id) external view returns (uint256) {
        return _totalMinted[id];
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);

        uint256 length = ids.length;

        for (uint i = 0; i < length; ) {
            unchecked {
                _totalMinted[ids[i]] += amounts[i];
                ++i;
            }
        }
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal override(ERC1155Upgradeable, ERC1155PausableUpgradeable, ERC1155SupplyUpgradeable) {
        super._update(from, to, ids, values);
    }
}
