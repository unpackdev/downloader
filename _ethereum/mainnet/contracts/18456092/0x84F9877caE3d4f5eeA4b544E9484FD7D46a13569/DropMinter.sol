// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ITokenMinter.sol";
import "./IClaimCallback.sol";
import "./ITokenLocker.sol";

contract DropMinter is IClaimCallback{

    address public immutable cvxprisma;
    address public immutable airdrop;
    address public immutable locker;
    event ConvertDrop(address indexed _address, uint256 _amount);

    constructor(address _cvxprisma, address _drop, address _locker){
        cvxprisma = _cvxprisma;
        airdrop = _drop;
        locker = _locker;
    }

    function claimCallback(address _claimant, uint256 _amount) external returns (bool success){
        require(msg.sender == airdrop, "!auth");
        _amount *= ITokenLocker(locker).lockToTokenRatio();
        ITokenMinter(cvxprisma).mint(_claimant, _amount);
        emit ConvertDrop(_claimant,_amount);
        return true;
    }

}