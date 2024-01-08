// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";

contract kimchipremium is ERC1155, Ownable {
    constructor() ERC1155("https://6bwevxjbtao3xxl63o73zaakpcxsgwst2fmafpuuf6ihawjn5vwa.arweave.net/8GxK3SGYHbvdftu_vIAKeK8jWlPRWAK-lC-QcFkt7Ww") {
        _mint(msg.sender, 0, 1000, "");
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
