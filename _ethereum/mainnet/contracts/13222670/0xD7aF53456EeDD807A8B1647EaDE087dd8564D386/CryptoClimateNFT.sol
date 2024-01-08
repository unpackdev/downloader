// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";

contract CryptoClimateNFT is ERC1155, Ownable {
    constructor() ERC1155("https://524hk7yupnu25zieqmslkmu6ccbp7r7eoxj6ajty7ne3cfx7xpva.arweave.net/7rh1fxR7aa7lBIMktTKeEIL_x-R10-AmePtJsRb_u-o") {
        _mint(msg.sender, 0, 100, "");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
}
