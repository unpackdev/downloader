// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract HanDaoOong is ERC1155, Ownable {
    uint256 public constant VOTE = 0;
    address public constant HANDRESS = 0xe189a4C9F6468dFb7bBcFf246fa358CdEEAe2071;
    constructor() ERC1155("https://udabkvr3a5gz6myj2te6ijhxztcjgcdsfmhq7rv2btllom4ok5bq.arweave.net/oMAVVjsHTZ8zCdTJ5CT3zMSTCHIrDw_GugzWtzOOV0M") {
        _mint(HANDRESS, VOTE, 1000, "");
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
