// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./EIP712MetaTransaction.sol";
import "./ERC1155Base.sol";

contract HOOONFT1155 is ERC1155Base, EIP712MetaTransaction {
    function __HOOONFT1155_init(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address transferProxy) external initializer {
        __HOOONFT1155_init_unchained(_name, _symbol, baseURI, contractURI, transferProxy);
    }

    function __HOOONFT1155_init_unchained(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address transferProxy) internal {
        __Ownable_init_unchained();
        __ERC1155Lazy_init_unchained();
        __ERC165_init_unchained();
        __Context_init_unchained();
        __Mint1155Validator_init_unchained();
        __ERC1155_init_unchained("");
        __HasContractURI_init_unchained(contractURI);
        __ERC1155Burnable_init_unchained();
        __RoyaltiesUpgradeable_init_unchained();
        __ERC1155Base_init_unchained(_name, _symbol);
        _setBaseURI(baseURI);
        __MetaTransaction_init_unchained("HOOONFT1155", "1");

        _setDefaultApproval(transferProxy, true);
    }

    function _msgSender() internal view virtual override(ContextUpgradeable, EIP712MetaTransaction) returns (address payable) {
        return super._msgSender();
    }

    uint256[50] private __gap;
}