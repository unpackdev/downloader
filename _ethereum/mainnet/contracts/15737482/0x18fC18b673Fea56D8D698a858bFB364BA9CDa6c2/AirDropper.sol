// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract AirDropper is Ownable {

    constructor(){

    }

    function withdrawToken(address token, address to) external onlyOwner{
        IERC20 iERC20 = IERC20(token);
        uint256 balance = iERC20.balanceOf(address(this));
        require(balance > 0, "token insufficient");
        iERC20.transfer(to==address(0)?msg.sender:to, balance);
    }

    function withdraw(address to) external onlyOwner{
        uint256 balance = address(this).balance;
        payable(to==address(0)?msg.sender:to).transfer(balance);
    }

    function doAirDrop1(address token, address[] memory dests, uint256 value) public onlyOwner {

        for(uint256 i=0;i<dests.length;i++){
            IERC20(token).transfer(dests[i], value);
        }

    }

    function doAirDrop2(address token, address[] memory dests, uint256[] memory values) public onlyOwner {

        require(dests.length == values.length,
            "length not match"
        );
        for(uint256 i=0;i<dests.length;i++){
            IERC20(token).transfer(dests[i], values[i]);
        }

    }

}
