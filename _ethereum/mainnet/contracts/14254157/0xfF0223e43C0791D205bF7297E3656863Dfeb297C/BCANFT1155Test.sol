// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Context.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./ERC2981PerTokenRoyalties.sol";
import "./BCANFT1155Factory.sol";


contract BCANFT1155Test is BCANFT1155Factory, ERC2981PerTokenRoyalties {
//    uint256 immutable maxSupply;
    string private _uri;

    constructor(string memory uri_, address recipient, uint256 value) BCANFT1155Factory(uri_) {
        _uri = uri_;
        _setTokenRoyalty(recipient, value);
    }

    function mintTo(address to, uint256 id, uint256 amount, bytes memory data) public override  {
        _mint(to, id, amount, data);
    }

    function mintAndTransferTo(address to, uint256 id, uint256 amount, bytes memory data) public {
        //TODO: direct mintTo toAddress,
        address from = owner();
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        //TODO: check id exist or not?
        //FIXME: check amount <= balance
        _mint(from, id, amount, data);
        safeTransferFrom(from, to, id, amount, data);
    }

    function setTokenRoyalty(address recipient, uint256 value) public  {
        _setTokenRoyalty(recipient, value);
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    function setURI(string memory newuri) public virtual {
        _uri = newuri;
    }
    
    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
//    function _beforeTokenTransfer(
//        address operator,
//        address from,
//        address to,
//        uint256[] memory ids,
//        uint256[] memory amounts,
//        bytes memory data
//    ) internal virtual override {
//        //safeTransferFrom do the following check
////        require(
////            from == _msgSender() || isApprovedForAll(from, _msgSender()),
////            "ERC1155: caller is not owner nor approved"
////        );
//        //if not exit
//        _mintBatch(to, ids, amounts, data);
//    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
