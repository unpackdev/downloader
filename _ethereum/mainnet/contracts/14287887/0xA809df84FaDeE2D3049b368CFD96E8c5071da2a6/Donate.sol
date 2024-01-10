// SPDX-License-Identifier: MIT
// developed by Ahoi Kapptn! - https://ahoikapptn.com

/**
     _    _           _   _  __                 _         _ 
    / \  | |__   ___ (_) | |/ /__ _ _ __  _ __ | |_ _ __ | |
   / _ \ | '_ \ / _ \| | | ' // _` | '_ \| '_ \| __| '_ \| |
  / ___ \| | | | (_) | | | . \ (_| | |_) | |_) | |_| | | |_|
 /_/   \_\_| |_|\___/|_| |_|\_\__,_| .__/| .__/ \__|_| |_(_)
                                   |_|   |_|                                                                                                             
 */

pragma solidity ^0.8.4;

import "./Ownable.sol";

contract Donate is Ownable {
    /**
     @dev events
     */
    event ReceivedETH(address, uint256);

    /**
    @dev receive ether if sent directly to this contract
    */
    receive() external payable {
        if (msg.value > 0) {
            emit ReceivedETH(msg.sender, msg.value);
        }
    }

    /**
    @dev withdraw all eth from contract to owner address
    */
    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
