// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Rewards is ERC20("Sky Labs", "SKY"), Ownable {
    event RewardClaimed(address indexed owner, uint256 amount);

    mapping(address => bool) public erc721Contracts;

    constructor(address _erc721ContractAddress) {
        erc721Contracts[_erc721ContractAddress] = true;
        _mint(msg.sender, 200000 ether);
    }

    function setErc721ContractAddress(address _contractAddress, bool _isAllowed) external onlyOwner {
        erc721Contracts[_contractAddress] = _isAllowed;
    }

    function mint(address _owner, uint256 _amount) external {
        require(erc721Contracts[msg.sender] == true);
        _mint(_owner, _amount);
        emit RewardClaimed(_owner, _amount);
    }

    function burnFrom(address _from, uint256 _amount) external {
        uint256 currentAllowance = allowance(_from, _msgSender());
        require(currentAllowance >= _amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(_from, _msgSender(), currentAllowance - _amount);
        }
        _burn(_from, _amount);
    }
}
