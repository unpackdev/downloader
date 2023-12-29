// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ITokenMinter.sol";
import "./IClaimCallback.sol";
import "./ITokenLocker.sol";

contract DropMinter is IClaimCallback{

    address public immutable convexproxy;
    address public immutable cvxprisma;
    address public immutable airdrop;
    address public immutable locker;
    event ConvertDrop(address indexed _address, uint256 _amount);

    constructor(address _proxy, address _cvxprisma, address _drop, address _locker){
        convexproxy = _proxy;
        cvxprisma = _cvxprisma;
        airdrop = _drop;
        locker = _locker;
    }

    function claimCallback(address _claimant, address _receiver, uint256 _amount) external returns (bool success){
        require(msg.sender == airdrop, "!drop");
        require(_receiver == convexproxy, "!receiver");
        _amount *= ITokenLocker(locker).lockToTokenRatio();
        ITokenMinter(cvxprisma).mint(_claimant, _amount);
        emit ConvertDrop(_claimant,_amount);
        return true;
    }

}