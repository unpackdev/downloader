// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./Ownable.sol";
import "./GPO.sol";

contract FundsMoverGPO is Ownable {
    GPO private gpo;

    constructor(address _gpo) {
        gpo = GPO(_gpo);
    }

    function unlockMoveLock(address from, uint256 amount, address to) public onlyOwner {
        gpo.lockUnlockWallet(from, false, amount);
        gpo.transferFrom(from, to, amount);
        gpo.lockUnlockWallet(to, true, amount);
    }

    function unlockMoveGPO(address from, uint256 amount) public onlyOwner {
        gpo.lockUnlockWallet(from, false, amount);
        gpo.transferFrom(from, address(gpo), amount);
    }

}
