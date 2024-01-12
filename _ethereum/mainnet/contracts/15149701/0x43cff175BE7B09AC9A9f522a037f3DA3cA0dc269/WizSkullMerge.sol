// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Skull.sol";
import "./FullSkull.sol";
import "./Shroom.sol";

contract WizSkullMerge is Ownable, Pausable, ReentrancyGuard {
    event SkullMerged(address user);

    Skull private _halfSkullContract;
    FullSkull private _fullSkullContract;
    Shroom private _shroomContract;
    address private _shroomBank;

    uint256 private _shroomCost = 6669*(10**18);

    constructor(address halfSkullAddress, address fullSkullAddress, address shroomAddress) {
        _pause();

        _halfSkullContract = Skull(halfSkullAddress);
        _shroomContract = Shroom(shroomAddress);
        _fullSkullContract = FullSkull(fullSkullAddress);
        _shroomBank = _msgSender();
    }

    function skullMerge() external nonReentrant whenNotPaused {
        require(_halfSkullContract.balanceOf(_msgSender(), 0) >= 2, 'Not enough skulls to merge');
        require(_shroomContract.balanceOf(_msgSender()) > _shroomCost, 'Not enough shrooms to merge');
        _shroomContract.transferFrom(_msgSender(), _shroomBank, _shroomCost);
        _halfSkullContract.burn(_msgSender(), 0, 2);
        _fullSkullContract.mint(_msgSender(), 0, 1, "0x0");
        emit SkullMerged(_msgSender());
    }

    function changeShroomCost(uint256 cost) public onlyOwner {
        _shroomCost = cost;
    }

    function setShroomBank(address shroomBankAddress) public onlyOwner {
        _shroomBank = shroomBankAddress;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
