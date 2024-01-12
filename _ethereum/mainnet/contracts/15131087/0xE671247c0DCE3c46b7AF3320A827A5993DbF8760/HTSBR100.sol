// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";

contract HTSBR100 is
    UUPSUpgradeable,
    ERC20Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC20BurnableUpgradeable
{
    bytes32 public BURNER_ROLE;
    bytes32 public MINTER_ROLE;

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function initialize() public initializer {
        __ERC20_init(
            "Royalties Musicais - Maiores Hits do Brasil #01",
            "HTSBR100"
        );
        address contract_owner = _msgSender();
        uint256 total_supply = 550 * (10**12);

        MINTER_ROLE = keccak256("MINTER_ROLE");
        BURNER_ROLE = keccak256("BURNER_ROLE");

        _setupRole(MINTER_ROLE, contract_owner);
        _setupRole(BURNER_ROLE, contract_owner);
        _setupRole(DEFAULT_ADMIN_ROLE, contract_owner);

        _mint(contract_owner, total_supply);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
