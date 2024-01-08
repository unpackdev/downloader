// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "./OwnableUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC1155DefaultApproval.sol";
import "./ERC1155Lazy.sol";
import "./HasContractURI.sol";

abstract contract ERC1155Base is Initializable, OwnableUpgradeable, ERC1155DefaultApproval,
ERC1155BurnableUpgradeable, ERC1155Lazy, HasContractURI {

    string public name;
    string public symbol;

    function setDefaultApproval(address operator, bool hasApproval) external onlyOwner {
        _setDefaultApproval(operator, hasApproval);
    }

    function isApprovedForAll(address _owner, address _operator) public override(ERC1155Upgradeable, ERC1155DefaultApproval) view returns (bool) {
        return ERC1155DefaultApproval.isApprovedForAll(_owner, _operator);
    }

    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual override(ERC1155Upgradeable, ERC1155Lazy) {
        ERC1155Lazy._mint(account, id, amount, data);
    }

    // Initializer instead of constructor
    function __ERC1155Base_init(string memory _name, string memory _symbol,
        string memory _baseURI, string memory _contractURI) public initializer {
        // OwnableUpgradeable
        __Context_init_unchained();
        // OwnableUpgradeable
        __Ownable_init_unchained();
        // ERC1155DefaultApproval
        __ERC1155DefaultApproval_init();
        // ERC1155BurnableUpgradeable
        __ERC1155Burnable_init_unchained();
        // ERC1155Lazy
        __ERC1155Lazy_init(_baseURI);
        // HasContractURI
        __HasContractURI_init_unchained(_contractURI);
        name = _name;
        symbol = _symbol;
    }

    function uri(uint id) external view override(ERC1155BaseURI, ERC1155Upgradeable) virtual returns (string memory) {
        return _tokenURI(id);
    }
    uint256[50] private __gap;
}
