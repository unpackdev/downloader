// SPDX-License-Identifier: MIT

/**
___________                  _________
\__    ___/___   ____   ____ \_   ___ \_____ _______  ______
  |    | /  _ \ /  _ \ /    \/    \  \/\__  \\_  __ \/  ___/
  |    |(  <_> |  <_> )   |  \     \____/ __ \|  | \/\___ \
  |____| \____/ \____/|___|  /\______  (____  /__|  /____  >
                           \/        \/     \/           \/
*/

pragma solidity ^0.8.0;

import "./IMintable.sol";
import "./Bytes.sol";
import "./ERC721.sol";
import "./Ownable.sol";

/**
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract ToonCars is ERC721, Ownable, IMintable {
    string private _baseURIextended;

    address public constant imx = 0x5FDCCA53617f4d2b9134B29090C87D01058e27e9;

    constructor() ERC721("ToonCars", "Toon") {}

    modifier onlyIMX() {
        require(msg.sender == imx, "Function can only be called by IMX");
        _;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIextended = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function mintFor(
        address to,
        uint256 amount,
        bytes calldata blob
    ) external override onlyIMX {
            require(amount == 1, "Mintable: invalid quantity");
            int256 index = Bytes.indexOf(blob, ":", 0);
            require(index >= 0, "Separator must exist");
            uint256 tokenID = Bytes.toUint(blob[1:uint256(index) - 1]);

            _mint(to, tokenID);
    }
}