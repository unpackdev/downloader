// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";

import "./IRegistryConsumer.sol";


contract RestrictedBlackHolePrevention is Ownable {
    // blackhole prevention methods

    address public constant REGISTRY_ADDRESS = 0x1e8150050A7a4715aad42b905C08df76883f396F;
    IRegistryConsumer constant _galaxisRegistry = IRegistryConsumer(REGISTRY_ADDRESS); // Galaxis Registry contract

    
    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        require(_tracker != _galaxisRegistry.getRegistryAddress("MARKETPLACE_ACCEPTED_ERC777"),"RestrictedBlackHolePrevention : cannot retrieve Galaxis payment token");
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
}