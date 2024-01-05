//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";
contract StarChainToken is ERC20{
  constructor(uint256 initialSupply) ERC20("StarChain Token", "SCT") {
        _mint(msg.sender, initialSupply * (10**uint256(decimals()))
	);
    }
}
