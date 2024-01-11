// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Initializable.sol";

import "./CountersUpgradeable.sol";

import "./AccessControlUpgradeable.sol";

import "./ERC165CheckerUpgradeable.sol";

import "./DirectSale.sol";

import "./AuctionSale.sol";

import "./Core.sol";

error Marketplace_Only_Admin_Can_Access();

error Marketplace_Not_Valid_Contract_To_Add();

enum TokenStandard {
    ERC721,
    ERC1155
}

contract Marketplace is
    Initializable,
    DirectSale,
    AuctionSale,
    AccessControlUpgradeable
{
    using ERC165CheckerUpgradeable for address;
    event RegisterContract(
        address contractAddress,
        TokenStandard tokenStandard
    );

    event SetAdmin(address account);

    event SetDissrupPayment(address dissrupPayout);

    event RevokeAdmin(address account);

    uint256[1000] private ______gap;

    function initialize(address dissrupPayout) public initializer {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        super._setDissrupPayment(dissrupPayout);
    }

    function addContractAllowlist(address contractAddress) external onlyAdmin {
        TokenStandard tokenStandard;
        // 0x80ac58cd == ERC721
        if (contractAddress.supportsInterface(bytes4(0x80ac58cd))) {
            tokenStandard = TokenStandard.ERC721;

            // 0xd9b67a26 == ERC1155
        } else if (contractAddress.supportsInterface(bytes4(0xd9b67a26))) {
            tokenStandard = TokenStandard.ERC1155;
        } else {
            revert Marketplace_Not_Valid_Contract_To_Add();
        }

        super._addContractAllowlist(contractAddress);

        emit RegisterContract(contractAddress, tokenStandard);
    }

    function setDissrupPayment(address dissrupPayout) external onlyAdmin {
        super._setDissrupPayment(dissrupPayout);

        emit SetDissrupPayment(dissrupPayout);
    }

    function setAdmin(address account) external onlyAdmin {
        _setupRole(DEFAULT_ADMIN_ROLE, account);

        emit SetAdmin(account);
    }

    function revokeAdmin(address account) external onlyAdmin {
        require(msg.sender != account, "Cannot remove yourself!");

        _revokeRole(DEFAULT_ADMIN_ROLE, account);

        emit RevokeAdmin(account);
    }

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert Marketplace_Only_Admin_Can_Access();
        }
        _;
    }
}
