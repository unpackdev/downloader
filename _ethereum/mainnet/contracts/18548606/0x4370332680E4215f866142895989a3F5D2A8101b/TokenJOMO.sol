//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./console.sol";
import "./ERC20.sol";
import "./errors.sol";
import "./TokenBHP.sol";

contract TokenJOMO is ERC20 {
    uint64 public constant BLOCK_REWARD = 1000000000000;
    address private immutable tokenBHPAddress;
    mapping(address => uint64) private lastBlockUpdate;

    constructor(string memory _name, string memory _symbol, address _tokenBHPAddress)
    ERC20(_name, _symbol)
    {
        tokenBHPAddress = _tokenBHPAddress;
    }

    function mintRewards(address _userAddress) external {
        if (msg.sender != tokenBHPAddress) {
            revert("JOMO: Only TokenBHP can update rewards");
        }

        if (lastBlockUpdate[_userAddress] > 0) {
            TokenBHP _tokenBHP = TokenBHP(tokenBHPAddress);
            uint64 _blocksDiff = uint64(block.number) - lastBlockUpdate[_userAddress];
            uint256 _userBalance = _tokenBHP.balanceOf(_userAddress);
            uint256 _govAmount = (uint256(_blocksDiff) * uint256(BLOCK_REWARD) * _userBalance) / 10 ** 18;

            _mint(_userAddress, _govAmount);
        }

        lastBlockUpdate[_userAddress] = uint64(block.number);
    }

    function _update(address _from, address _to, uint256 _value)
    internal
    override(ERC20)
    {
        if (_from == address(0)) {
            super._update(_from, _to, _value);
        } else {
            revert("JOMO: Token is not transferable");
        }
    }

}