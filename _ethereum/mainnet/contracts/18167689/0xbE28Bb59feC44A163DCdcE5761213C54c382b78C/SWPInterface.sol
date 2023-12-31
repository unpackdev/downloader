pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";
import "./Ownable.sol";

interface ISWP {
    function swap(address) external payable;
}

contract SWPInterface is Ownable {
    ISWP public swp;
    constructor(address _swpAddress) {
        swp = ISWP(_swpAddress);
    }

    receive() external payable {
        swp.swap{ value: msg.value }(msg.sender);
    }

    function recoverERC20(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to recover");
        token.transfer(msg.sender, balance);
    }
}