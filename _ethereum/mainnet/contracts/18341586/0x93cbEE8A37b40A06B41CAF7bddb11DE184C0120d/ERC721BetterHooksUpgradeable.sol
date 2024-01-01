// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";

contract ERC721BetterHooksUpgradeable is Initializable, ERC721Upgradeable {

    function __ERC721BetterHooksUpgradeable_init() internal onlyInitializing {
    }

    function __ERC721BetterHooksUpgradeable_init_unchained() internal onlyInitializing {
    }

    /**
     * See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
        if (from == address(0)) {
            _beforeTokenMint(to, firstTokenId, batchSize);
        } else {
            if (to == address(0)) { _beforeTokenBurn(from, firstTokenId, batchSize); }
            else { _beforeTokenSend(from, to, firstTokenId, batchSize); }
        }
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * Hook that is called before any token mint.
     * See {ERC721-_beforeTokenTransfer} for parameters.
     */
    function _beforeTokenMint(address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * Hook that is called before any token transfer between two non zero addresses.
     * See {ERC721-_beforeTokenTransfer} for parameters.
     */
    function _beforeTokenSend(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * Hook that is called before any token burn.
     * See {ERC721-_beforeTokenTransfer} for parameters.
     */
    function _beforeTokenBurn(address from, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[10] private __gap;

}
