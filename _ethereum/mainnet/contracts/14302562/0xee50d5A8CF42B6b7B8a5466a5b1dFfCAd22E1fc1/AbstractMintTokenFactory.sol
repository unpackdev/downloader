// SPDX-License-Identifier: MIT

/*

    888b. 8888    db    .d88b 8888
    8  .8 8www   dPYb   8P    8www
    8wwP' 8     dPwwYb  8b    8
    8     8888 dP    Yb `Y88P 8888

    Yb        dP 888 8    8
    Yb  db  dP   8  8    8
    YbdPYbdP    8  8    8
    YP  YP    888 8888 8888

    888b. 888b. 8888 Yb    dP    db    888 8
    8  .8 8  .8 8www  Yb  dP    dPYb    8  8
    8wwP' 8wwK' 8      YbdP    dPwwYb   8  8
    8     8  Yb 8888    YP    dP    Yb 888 8888

                                    .d88b  8
                                    8P www 8
                                    8b  d8 8
                                    `Y88P' 8888


Visit https://www.sunflowers4ukraine.org/ for project details.
Contract Developed by https://hcode.tech/
*/

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Pausable.sol";
import "./ERC1155Supply.sol";



abstract contract AbstractMintTokenFactory is  ERC1155Pausable, ERC1155Supply, ERC1155Burnable, Ownable {
    
    string internal name_;
    string internal symbol_;
    
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }    

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }    

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }          

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override(ERC1155) {
        super._mint(account, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155) {
        super._mintBatch(to, ids, amounts, data);
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override(ERC1155) {
        super._burn(account, id, amount);
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override(ERC1155) {
        super._burnBatch(account, ids, amounts);
    }  

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }  

    function setOwner(address _addr) public onlyOwner {
        transferOwnership(_addr);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
   function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}