// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract Token_Igor is ERC20, Ownable {
    address private stakeModule;
    
    event newStakeModule(address newStakeModule);

    constructor() ERC20("Oasis", "OAS") {}

    function mint(address to, uint256 amount) public {
        require(msg.sender == owner() || msg.sender == stakeModule, "no auth");
        _mint(to, amount);
    }

    function setStakeModule(address _StakeModule) public onlyOwner() {
        stakeModule = _StakeModule;
        emit newStakeModule(_StakeModule);
    }

    function getStakeModule() external view returns(address) {
        return stakeModule;
    }

}