// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}
