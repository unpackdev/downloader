pragma solidity >=0.6.6;

import "./EXCV.sol";

contract TestEXCV is EXCV {
    function testMint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}