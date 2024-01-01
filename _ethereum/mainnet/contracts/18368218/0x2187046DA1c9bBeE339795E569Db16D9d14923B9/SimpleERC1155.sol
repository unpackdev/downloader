// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";

abstract contract SimpleERC1155 is ERC1155Supply, Ownable {
    string private baseURI;
    string private _name;
    string private _symbol;

    error Unapprovable();
    error Untransferable();

    constructor(
        string memory name_,
        string memory symbol_
    ) Ownable(msg.sender) ERC1155("") {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @notice Name of the token
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @notice Symbol of the token
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Base URI of the token
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @notice Base uri of the ERC1155
     * @param tokenId Token id to observe
     */
    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")
            );
    }

    /**
     * @dev See {ERC1155-_update}.
     */
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override {
        if (to != address(0) && from != address(0)) {
            revert Untransferable();
        }
        super._update(from, to, ids, values);
    }

    /**
     * @dev See {ERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address, bool) public virtual override(ERC1155) {
        revert Unapprovable();
    }
}
