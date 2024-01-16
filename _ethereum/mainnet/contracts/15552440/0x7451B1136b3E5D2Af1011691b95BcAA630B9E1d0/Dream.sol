// SPDX-License-Identifier: MIT
/**
* created by yiyi on 17 Sep,2022, after the merge.
* I hope everyone who accidently saw this contract will have their dreams true and a peaceful life.
* anyone is able to mint dream token,10 million supply.
*/
import "./Ownable.sol";
import "./ERC20.sol";
pragma solidity ^0.8.8;
contract dream is ERC20,Ownable{
    uint public max_supply =10000000*1e18;

    constructor() ERC20("Dream", "dream") {
        _mint(msg.sender, 2025*1e18);
    }
    receive() external payable{}
    fallback() external payable{}
    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
    function mint(uint256 amount) external{
        require(amount*1e18+totalSupply()<max_supply,"exceed total supply");
        _mint(msg.sender, amount*1e18);
    }
}