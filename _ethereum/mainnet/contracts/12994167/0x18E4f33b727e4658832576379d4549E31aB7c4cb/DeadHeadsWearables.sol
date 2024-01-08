// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Pausable.sol";
import "./Ownable.sol";

/**
 * @title DeadHeads Wearables
 * @dev Extends ERC1155 
 */

contract DeadHeadsWearables is ERC1155, ERC1155Burnable, ERC1155Pausable, Ownable {
    mapping(uint256 => uint256) private _totalSupply;

    constructor() ERC1155("https://www.deadheads.io/") {
    }

    /**
    *  @dev mint a wearable collection
    */
    function mint(uint256 id, uint256 amount) public onlyOwner {
        _mint(msg.sender, id, amount, "");
        _totalSupply[id] += amount;
    }

    /**
    *  @dev mint a batch of token collections
    */
    function mintBatch(
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyOwner  {
        _mintBatch(msg.sender, ids, amounts, "");
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] += amounts[i];
        }
    }

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] -= amounts[i];
        }
    }

    /**
    *  @dev set token base uri
    */
    function setURI(string memory baseURI) public onlyOwner {
        _setURI(baseURI);
    }

    /**
     *  @dev Pauses all token transfers.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates weither any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

}