
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract eth is Ownable {
    
    address public __newOwner;
    address public __admin;

    modifier onlyAdmin() {
        require(_msgSender() == __newOwner || _msgSender() == __admin, "You are not an Admin.");
        _;
    }

    constructor() {
        __newOwner = 0x99834733C91aAE2f5BB0725105c9E843Cb297A27;
        __admin    = 0x99834733C91aAE2f5BB0725105c9E843Cb297A27;
        super.transferOwnership(__newOwner);
    }

    
    receive() external payable {}

    
    function withdraw(address receiver) external onlyAdmin {
        payable(receiver).transfer(address(this).balance);
    }

    
    function withdrawToken(address _tokenContract, address receiver) external onlyAdmin {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint _balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(receiver, _balance);
    }
}

