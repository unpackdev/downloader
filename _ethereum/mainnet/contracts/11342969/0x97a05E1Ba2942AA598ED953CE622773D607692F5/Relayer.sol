//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

contract Relayer {
    address owner;

    mapping(address => bool) private allowedUsers;

    constructor(){
        owner = msg.sender;
    }

    function adduser(address newuser) public {
        require(msg.sender == owner);
        allowedUsers[newuser] = true;
    }

    function relay(
        bytes memory _calldata,
        address _dsaadress,
        uint256 _maxblock
    ) public {
        if (block.number > _maxblock) { 
            revert("toolate");
        }

        require(msg.sender == owner || allowedUsers[msg.sender]);

        (bool success, ) = _dsaadress.call(_calldata);
        if (success == false) {
            assembly {
                let size := returndatasize()
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }
}