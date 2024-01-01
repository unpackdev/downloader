// ##deployed index: 17
// ##deployed at: 2023/11/06 18:37:41
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IBurnToken.sol";

contract BurnToken is IBurnToken, ERC20, Ownable {

    uint256 public constant MAX_SUPPLY = 1000000000 * 10 ** 18;
    // user address => LockData
    mapping(address => LockData) private lockDataList;

    struct LockData {
        uint256 amount;
        uint256 releasedAt;
    }

    constructor() ERC20('BurnYou', 'BURN'){}

    function mint(address _to, uint256 _amount, uint256 _released_at) external onlyOwner {
        require(_to != address(0), 'BurnToken: mint to the zero address');
        require(_amount > 0, 'BurnToken: mint amount must be greater than 0');
        require(totalSupply() + _amount <= MAX_SUPPLY, 'BurnToken: mint amount exceeds max supply');

        _mint(_to, _amount);

        if (_released_at > block.timestamp) {
            require(lockDataList[_to].amount == 0, 'BurnToken: Lock data is existed, please change a new wallet');
            lockDataList[_to] = LockData(_amount, _released_at);
        }
    }

    function getLockData(address _user) external view returns (uint256, uint256) {
        return (lockDataList[_user].amount, lockDataList[_user].releasedAt);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal override {
        uint256 balance = balanceOf(_from);

        LockData storage lockData = lockDataList[_from];

        if (lockData.amount > 0 && lockData.releasedAt < block.timestamp) {
            lockData.amount = 0;
            lockData.releasedAt = 0;
        }

        if (lockData.amount > 0) {
            require(balance - lockData.amount >= _amount, 'BurnToken: Your token is locked');
        }

        super._transfer(_from, _to, _amount);
    }
}
