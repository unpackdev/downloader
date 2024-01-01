// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC1155.sol";
import "./Ownable.sol";

contract MetawinMillionaireMarketing is ERC1155, Ownable {

    string public name = "Metawin Millionaire Marketing";

    event Mint(address indexed account, uint256 id, uint256 amount);
    constructor(address initialOwner) ERC1155("https://ivory-actual-moth-667.mypinata.cloud/ipfs/QmQhoewrHURbCN5aWdsDxLVF9na7GxiRV9AHqZPkRR94ix") Ownable(initialOwner) {
        _mint(initialOwner, 1, 1, "");
        emit Mint(initialOwner, 1, 1);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mintMultipleToAddresses(address[] memory addresses) public onlyOwner {
        for (uint256 i; i < 400;) {
            _mint(addresses[i], 1, 1, "");
            emit Mint(addresses[i], 1, 1);
            unchecked {
                ++i; 
            }
        }
    }
}
