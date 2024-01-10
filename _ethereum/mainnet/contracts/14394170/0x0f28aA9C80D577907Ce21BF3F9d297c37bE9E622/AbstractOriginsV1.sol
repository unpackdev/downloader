// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

abstract contract AbstractOriginsV1 is Pausable, ERC1155Supply, ERC1155Burnable, Ownable {

    string contractName;
    string contractSymbol;

    function setPaused(bool state) external onlyOwner() {
        state ? _pause() : _unpause();
    }   

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }    

    function name() public view returns (string memory) {
        return contractName;
    }

    function symbol() public view returns (string memory) {
        return contractSymbol;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}