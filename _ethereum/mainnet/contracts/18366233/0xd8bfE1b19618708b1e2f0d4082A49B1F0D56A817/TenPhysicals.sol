// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./AdminManagerUpgradable.sol";

contract TenPhysicals is
    Initializable,
    OwnableUpgradeable,
    ERC1155SupplyUpgradeable,
    ERC2981Upgradeable,
    AdminManagerUpgradable
{
    string public constant name = "TEN PHYSICALS";

    function initialize(
        string calldata uri_,
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_
    ) external initializer {
        __Ownable_init(msg.sender);
        __ERC1155_init_unchained(uri_);
        __ERC1155Supply_init_unchained();
        __ERC2981_init();
        __AdminManager_init_unchained();
        _setDefaultRoyalty(royaltyReceiver_, royaltyFeeNumerator_);
    }

    function adminMint(
        address[] calldata accounts_,
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    ) external onlyAdmin {
        uint256 accountsLength = accounts_.length;
        require(accountsLength == tokenIds_.length, "Bad request");
        require(accountsLength == amounts_.length, "Bad request");
        for (uint256 i; i < accountsLength; i++) {
            _mint(accounts_[i], tokenIds_[i], amounts_[i], "");
        }
    }

    function setURI(string memory uri_) external onlyAdmin {
        _setURI(uri_);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
