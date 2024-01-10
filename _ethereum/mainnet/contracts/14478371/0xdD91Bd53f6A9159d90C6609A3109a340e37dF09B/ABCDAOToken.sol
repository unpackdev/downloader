// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";

contract ABCDAOToken is ERC20, Ownable {
    constructor() public ERC20("Atlanta Blockchain Center DAO", "ABCDAO") {
        /* 
            mint 2019 population of Metro Atlanta according to 
            Metro Atlanta Chamber report
            https://www.metroatlantachamber.com/resources/reports-and-information/executive-profile
        */
        _mint(msg.sender, 6089815 * (10**uint256(decimals())));
    }

    function mint(address account, uint256 amount) public onlyOwner {
        /*
            allow DAO to increase supply by way of multisig voting. ABCDAO token 
            inflation to represent % of population growth of Metro Atlanta
        */
        _mint(account, amount);
    }
}
