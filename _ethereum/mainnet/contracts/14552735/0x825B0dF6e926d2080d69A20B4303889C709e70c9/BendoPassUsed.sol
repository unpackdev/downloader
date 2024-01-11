//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./ERC1155.sol";
import "./Ownable.sol";

contract BendoPassUsed is ERC1155, Ownable {

    address public murasaiContract;
    uint8 public immutable ID_BOX = 1;

    string public name = "Bendo Pass Opened";
    string public symbol = "MuraPassOpened";


    constructor(string memory _uri, address _murasaiContract) ERC1155(_uri) {
        murasaiContract = _murasaiContract;
    }

    modifier onlyMurasaiContract() {
        require(_msgSender() == murasaiContract);
        _;
    }

    function updateMurasaiContract(address _murasaiContract) public onlyOwner {
        murasaiContract = _murasaiContract;
    }

    function openTheBox(address theOne, uint amount) public onlyMurasaiContract {
        _mint(theOne, ID_BOX, amount, "");
    }

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }
}