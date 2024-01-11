// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC1155D.sol";

contract WaveTestDrop is ERC1155 {
    uint256 private currentIndex = 1;

    constructor() ERC1155("https://meta.wavexaio.com/test/{id}") {}

    function testMint_139E1071() external payable {
        require(msg.sender == tx.origin);
        uint256 _currentIndex = currentIndex;
        
        emit TransferSingle(msg.sender, address(0), msg.sender, _currentIndex, 1);

        assembly {
            sstore(add(_owners.slot, _currentIndex), caller())
        }

        unchecked {
            _currentIndex++;
        }
        currentIndex = _currentIndex;
    }
}