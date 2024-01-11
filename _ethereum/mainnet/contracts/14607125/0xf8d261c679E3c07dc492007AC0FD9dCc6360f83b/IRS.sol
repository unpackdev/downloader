// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1

pragma solidity ^0.8.0;

// ╔═╗─╔╦═══╦════╗╔════╦═══╦═╗╔═╗╔═══╦═══╦═══╦══╦═══╦═══╗
// ║║╚╗║║╔══╣╔╗╔╗║║╔╗╔╗║╔═╗╠╗╚╝╔╝║╔═╗║╔══╣╔══╩╣╠╣╔═╗║╔══╝
// ║╔╗╚╝║╚══╬╝║║╚╝╚╝║║╚╣║─║║╚╗╔╝─║║─║║╚══╣╚══╗║║║║─╚╣╚══╗
// ║║╚╗║║╔══╝─║║────║║─║╚═╝║╔╝╚╗─║║─║║╔══╣╔══╝║║║║─╔╣╔══╝
// ║║─║║║║────║║────║║─║╔═╗╠╝╔╗╚╗║╚═╝║║──║║──╔╣╠╣╚═╝║╚══╗
// ╚╝─╚═╩╝────╚╝────╚╝─╚╝─╚╩═╝╚═╝╚═══╩╝──╚╝──╚══╩═══╩═══╝
// Not Financial Advice: The avoidance of taxes is the only intellectual pursuit that still carries any reward. - John Maynard Keynes
// NFT Tax Office is not a real tax office.

import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract IRS is Ownable, ERC20Burnable {
    
    mapping(address => bool) public minters;

    constructor() ERC20("Tax-Returns", "IRS") {}

     function addMinter(address _minter) public onlyOwner {
        minters[_minter] = true;
        emit MinterAdded(_minter);
    }

    function removeMinter(address _minter) public onlyOwner {
        minters[_minter] = false;
        emit MinterRemoved(_minter);
    }

    function mint(address to, uint256 amount) public {
        require(minters[msg.sender], "Error - Only approved minter can mint tokens");
        _mint(to, amount);
    }

    event MinterAdded(address minter);
    event MinterRemoved(address minter);
}