// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./ERC20Pausable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract BitcoinGreenMining is
    ERC20Snapshot,
    ERC20Burnable,
    ERC20Pausable,
    Ownable
{
    address public teamAddress;
    using SafeMath for uint256; //

    constructor(uint256 initialSupply)
        public
        ERC20("Bitcoin Green Mining", "BGM")
    {
        _mint(msg.sender, initialSupply);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot, ERC20Pausable) {
        ERC20Snapshot._beforeTokenTransfer(from, to, amount);
        ERC20Pausable._beforeTokenTransfer(from, to, amount);
    }

    function setTeamAddress(address ad)
        public
        onlyOwner
        returns (bool _success)
    {
        require(address(ad) != address(0));
        teamAddress = ad;
        return true;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     **/
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unPause() public onlyOwner whenPaused {
        _unpause();
    }
}
