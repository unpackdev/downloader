pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY


import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";


contract recovery is Ownable {


    
    // blackhole prevention methods
    function retrieveETH() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(""); // don't use send or xfer (gas)
        require(sent, "Failed to send Ether");
    }
    
    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }



}