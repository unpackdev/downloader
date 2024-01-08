pragma solidity ^0.7.5;


import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";


contract recovery is Ownable {
    // blackhole prevention methods
    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
}