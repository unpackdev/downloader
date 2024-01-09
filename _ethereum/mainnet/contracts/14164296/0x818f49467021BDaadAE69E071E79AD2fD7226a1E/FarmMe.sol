// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract FarmMe is ERC20, Pausable, Ownable {

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

    
    mapping (address => bool) public isBlackListed;

    constructor() ERC20("FAME", "FAME") {
        _mint(msg.sender, 11e26);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit  RemovedBlackList(_clearedUser);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        require(!isBlackListed[from],"FM: Transfer from blacklist!");
        super._beforeTokenTransfer(from, to, amount);
    }
}
