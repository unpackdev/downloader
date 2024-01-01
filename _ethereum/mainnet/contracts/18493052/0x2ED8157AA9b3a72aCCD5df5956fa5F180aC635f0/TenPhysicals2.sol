//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./SupplyUpgradable.sol";
import "./AdminMintUpgradable.sol";
import "./BalanceLimitUpgradable.sol";
import "./AdminManagerUpgradable.sol";
import "./PriceUpgradable.sol";

contract TenPhysicals2 is
    Initializable,
    OwnableUpgradeable,
    ERC1155SupplyUpgradeable,
    ERC2981Upgradeable,
    AdminManagerUpgradable,
    SupplyUpgradable,
    BalanceLimitUpgradable,
    PriceUpgradable
{
    function initializeV2(uint256 maxSupply_) public reinitializer(2) {
        __Supply_init_unchained(maxSupply_);
        __BalanceLimit_init_unchained();
        setPrice(1, 0.039 ether);
    }

    enum Stage {
        Disabled,
        Public
    }

    Stage public stage;

    function publicMint(uint256 amount_) external payable {
        require(stage == Stage.Public, "Public sale not enabled");
        uint8 _stage = uint8(Stage.Public);
        _increaseBalance(_stage, msg.sender, amount_);
        _callMint(msg.sender, amount_);
        _handlePayment(amount_ * price(_stage));
    }

    function setStage(Stage stage_) external onlyAdmin {
        stage = stage_;
    }

    function _callMint(
        address account_,
        uint256 amount_
    ) internal onlyInSupply(amount_) {
        require(tx.origin == msg.sender, "No bots");
        _mint(account_, 1, 1, "");
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

    function _currentSupply() internal view override returns (uint256) {
        return totalSupply();
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

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
