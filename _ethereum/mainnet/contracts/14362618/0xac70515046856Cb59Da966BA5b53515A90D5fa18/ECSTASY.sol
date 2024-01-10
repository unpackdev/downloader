// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";

contract ECSTASY is ERC1155, Ownable, ERC1155Burnable {
    uint256 public constant TOKEN = 0;
    constructor()
        ERC1155("ipfs://QmfBM23AChVTm5fkL33ypYTLjQsaPaK28KitL4seV9LueD")
    {
        _mint(msg.sender, 0, 10**5, "");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
    {
        require(balanceOf(account, id) < 1, 'can only mint once');
        _mint(account, id, amount, data);

    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
}
