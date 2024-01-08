// SPDX-License-Identifier: MIT

/**
 * @author          Yisi Liu
 * @contact         yisiliu@gmail.com
 * @author_time     01/06/2021
**/

pragma solidity >= 0.8.0;

import "./IQLF.sol";
import "./Ownable.sol";

contract QLF_Entropyfi is IQLF, Ownable {
    uint256 start_time;
    mapping(address => bool) public whitelist_list;

    constructor (uint256 _start_time) {
        start_time = _start_time;
    }

    function get_start_time() public view returns (uint256) {
        return start_time;
    }

    function set_start_time(uint256 _start_time) public onlyOwner {
        start_time = _start_time;
    }

    function isQualified(address account)
        public view
        returns (
            bool qualified
        )
    {
        if (start_time > block.timestamp) {
            return false; 
        }
        if (!whitelist_list[account]) {
            return false; 
        }
        return true;  
        
    }

    function ifQualified(address account, bytes32[] memory data)
        public
        view
        override
        returns (
            bool qualified,
            string memory errorMsg
        )
    {
        if (start_time > block.timestamp) {
            return (false, "not started"); 
        }
        if (!whitelist_list[account]) {
            return (false, "not whitelisted"); 
        }
        return (true, "");
    } 

    function add_white_list(address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelist_list[addrs[i]] = true;
        }
    }

    function remove_white_list(address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelist_list[addrs[i]] = false;
        }
    }

    function logQualified(address account, bytes32[] memory data)
        public
        override
        returns (
            bool qualified,
            string memory errorMsg
        )
    {
        if (start_time > block.timestamp) {
            return (false, "not started"); 
        }
        if (!whitelist_list[account]) {
            return (false, "not whitelisted"); 
        }
        emit Qualification(account, true, block.number, block.timestamp);
        return (true, "");
    } 

    function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
        return interfaceId == this.supportsInterface.selector || 
            interfaceId == (this.ifQualified.selector ^ this.logQualified.selector) ||
            interfaceId == this.get_start_time.selector;
    }
}