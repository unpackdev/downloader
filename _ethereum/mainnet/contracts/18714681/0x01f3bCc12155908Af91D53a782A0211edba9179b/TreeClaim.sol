// SPDX-License-Identifer: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract TreeClaim is Ownable {

    bool public active = false;

    mapping(address => uint256) public claims;

    IERC20 immutable private TREE_TOKEN;
    
    constructor(address _addr) Ownable(msg.sender) {
        TREE_TOKEN = IERC20(_addr);
    }

    function addToClaims(address[] calldata _addrs, uint256[] calldata _claims) external onlyOwner {
        require(_addrs.length == _claims.length, "Array length mismatch");
        for (uint i = 0; i < _addrs.length; i++) {
            claims[_addrs[i]] = _claims[i];
        }
    }

    function removeFromClaims(address[] calldata _addrs) external onlyOwner {
        for (uint i = 0; i < _addrs.length; i++) {
            delete claims[_addrs[i]];
        }
    }

    function toggleClaims() external onlyOwner {
        active = !active;
    }

    function claim() external {
        require(active, "Claims aren't live");
        require(claims[msg.sender] > 0, "Not eligible to claim");
        uint256 _val = claims[msg.sender];
        claims[msg.sender] = 0;
        TREE_TOKEN.transfer(msg.sender, _val);
    }
}
