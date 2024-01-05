// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Pausable.sol";
import "./Ownable.sol";

contract BIXToken is ERC20Pausable, Ownable{

    string public version = "2.0";
    uint256 private _INIT_SUPPLY = 235972808.27 * (10**18);

    // constructor
    constructor() ERC20("BIX Token v2","BIX", 18) {
         _mint(_msgSender(), _INIT_SUPPLY);
    }


    function burn(uint256 amount) public returns (bool){
        _burn(_msgSender(), amount);
        return true;
    }

    function mint(address account, uint256 amount) public  onlyOwner  returns (bool){
        _mint(account, amount);
        return true;
    }

    function pause() public onlyOwner returns (bool) {
        _pause();
        return true;
    }

    function unpause() public onlyOwner returns (bool) {
        _unpause();
        return true;
    }

    function lock(address account) public onlyOwner returns (bool) {
        _lock(account);
        return true;
    }

    function unlock(address account) public onlyOwner returns (bool) {
        _unlock(account);
        return true;
    }
   
}