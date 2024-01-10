 //SPDX-License-Identifier: none

pragma solidity ^0.8.8;

import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./ERC1155PausableUpgradeable.sol";
import "./ERC1155Upgradeable.sol";

contract LandNFT_Roles is ERC1155Upgradeable, AccessControlEnumerableUpgradeable, ERC1155BurnableUpgradeable, ERC1155PausableUpgradeable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "LandNFT: caller is not a MINTER");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "LandNFT: caller is not an OPERATOR");
        _;
    }

    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, _msgSender()), "LandNFT: caller is not a BURNER");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "LandNFT: caller is not an ADMIN");
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerableUpgradeable, ERC1155Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual override(ERC1155Upgradeable, ERC1155PausableUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
