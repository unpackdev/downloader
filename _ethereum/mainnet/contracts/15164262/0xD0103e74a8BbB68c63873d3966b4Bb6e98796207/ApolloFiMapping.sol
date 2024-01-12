// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";

contract ApolloFiMapping is Ownable {

    IERC20 public oldApo;
    IERC20 public newApo;

    address public mappingAddress;

    event Exchange(address _user, uint256 _amount);

    constructor(
        address _oldApo,
        address _newApo,
        address _mappingAddress
    ) {
        oldApo = IERC20(_oldApo);
        newApo = IERC20(_newApo);
        mappingAddress = _mappingAddress;
    }

    function setApoAddress(address _old, address _new) external onlyOwner {
        oldApo = IERC20(_old);
        newApo = IERC20(_new);
    }

    function exchange(uint256 _amount) external {
        require(oldApo.balanceOf(msg.sender) >= _amount, "ApolloFiMapping: token not enough");

        bool success = oldApo.transferFrom(msg.sender, mappingAddress, _amount);

        require(success, "ApolloFiMapping: exchange failed");

        newApo.transferFrom(mappingAddress, msg.sender, _amount);

        emit Exchange(msg.sender, _amount);
    }
}
