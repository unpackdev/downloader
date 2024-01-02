// SPDX-License-Identifier: BUSL-1.1
// Starship Contract Factory
// Powered by Agora

pragma solidity 0.8.21;

contract Nukable {

    bool internal IsNuked;
    event Nuked();

    modifier IfNotNuked() {
        if(IsNuked) {
            revert("This contract has been nuked and it is not operational");
        }
        _;
    }

    function Nuke() internal {
        IsNuked = true;
        emit Nuked();
    }
    
}