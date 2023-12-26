// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./Pausable.sol";

contract OwnerPausable is Ownable, Pausable {
    function pause() public onlyOwner {
        Pausable._pause();
    }

    function unpause() public onlyOwner {
        Pausable._unpause();
    }
}