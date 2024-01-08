// SPDX-License-Identifier: MIT

/**
 * @author          Yisi Liu
 * @contact         yisiliu@gmail.com
 * @author_time     01/06/2021
**/

pragma solidity >= 0.8.0;

import "./IQLF.sol";
import "./Ownable.sol";

contract QLF is IQLF, Ownable {
    uint256 public start_time;
    mapping(address => bool) black_list;

    constructor (uint256 _start_time) {
        start_time = _start_time;
    }

    function get_start_time() public view returns (uint256) {
        return start_time;
    }

    function set_start_time(uint256 _start_time) public onlyOwner {
        start_time = _start_time;
    }

    function ifQualified(address account, bytes32[] memory data)
        public
        pure
        override
        returns (
            bool qualified,
            string memory errorMsg
        )
    {
        return (true, "");
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
            black_list[account] = true;
            return (false, "not started"); 
        }
        if (black_list[account]) {
            return (false, "blacklisted"); 
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
