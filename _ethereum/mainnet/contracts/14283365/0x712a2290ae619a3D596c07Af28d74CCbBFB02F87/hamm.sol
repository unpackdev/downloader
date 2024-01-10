// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1

pragma solidity ^0.8.0;

//    ___ ___    _____      _____      _____    .___ _______   ____  __. _________            
//   /   |   \  /  _  \    /     \    /     \   |   |\      \ |    |/ _| \_   ___ \  ____     
//  /    ~    \/  /_\  \  /  \ /  \  /  \ /  \  |   |/   |   \|      <   /    \  \/ /  _ \    
//  \    Y    /    |    \/    Y    \/    Y    \ |   /    |    \    |  \  \     \___(  <_> )   
//   \___|_  /\____|__  /\____|__  /\____|__  / |___\____|__  /____|__ \  \______  /\____/ /\ 
//         \/         \/         \/         \/              \/        \/         \/        \/ 

import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract hamm is Ownable, ERC20Burnable {
    
    mapping(address => bool) public minters;

    constructor() ERC20("hamm-ink-utility", "hamm") {}

    function addMinter(address _minter) public onlyOwner {
        minters[_minter] = true;
        emit MinterAdded(_minter);
    }

    function removeMinter(address _minter) public onlyOwner {
        minters[_minter] = false;
        emit MinterRemoved(_minter);
    }

    function mint(address to, uint256 amount) public {
        require(minters[msg.sender], "Only minter can mint");
        _mint(to, amount);
    }

    event MinterAdded(address minter);
    event MinterRemoved(address minter);
}