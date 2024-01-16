//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./OpenSeaGasFreeListing.sol";
import "./SupplyUpgradable.sol";
import "./AdminMintUpgradable.sol";
import "./WhitelistUpgradable.sol";
import "./BalanceLimitUpgradable.sol";
import "./UriManagerUpgradable.sol";
import "./RoyaltiesUpgradable.sol";
import "./PriceUpgradable.sol";
import "./CustomPaymentSplitterUpgradeable.sol";

contract TwoStage is
    Initializable,
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable,
    SupplyUpgradable,
    AdminMintUpgradable,
    WhitelistUpgradable,
    BalanceLimitUpgradable,
    UriManagerUpgradable,
    RoyaltiesUpgradable,
    PriceUpgradable,
    CustomPaymentSplitterUpgradeable
{
    enum Stage {
        Disabled,
        Whitelist,
        Public
    }

    Stage public stage;

    function isApprovedForAll(address owner_, address operator_)
        public
        view
        virtual
        override(ERC721AUpgradeable)
        returns (bool)
    {
        return
            super.isApprovedForAll(owner_, operator_) ||
            OpenSeaGasFreeListing.isApprovedForAll(owner_, operator_);
    }

    function whitelistMint(uint256 amount_, bytes32[] calldata proof_)
        external
        payable
        onlyWhitelisted(uint8(Stage.Whitelist), msg.sender, proof_)
    {
        require(stage == Stage.Whitelist, "Whitelist sale not enabled");
        uint8 _stage = uint8(Stage.Whitelist);
        _increaseBalance(_stage, msg.sender, amount_);
        _callMint(msg.sender, amount_);
        _handlePayment(amount_ * price(_stage));
    }

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

    function _callMint(address account_, uint256 amount_)
        private
        onlyInSupply(amount_)
    {
        require(tx.origin == msg.sender, "No bots");
        _safeMint(account_, amount_);
    }

    function _adminMint(address account_, uint256 amount_) internal override {
        _callMint(account_, amount_);
    }

    function _currentSupply() internal view override returns (uint256) {
        return totalSupply();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        return _buildUri(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(RoyaltiesUpgradable, ERC721AUpgradeable)
        returns (bool)
    {
        return
            RoyaltiesUpgradable.supportsInterface(interfaceId) ||
            ERC721AUpgradeable.supportsInterface(interfaceId);
    }
}