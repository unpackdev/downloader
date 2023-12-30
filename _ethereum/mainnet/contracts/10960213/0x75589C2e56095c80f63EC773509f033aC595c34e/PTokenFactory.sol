// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./PToken.sol";

contract PTokenFactory {
    mapping (address => PToken) userPTokens;

    event NewPToken(PToken token);

    function createPToken(
        string memory _name,
        string memory _symbol,
        uint256 _cost,
        uint256 _supply,
        address _acceptedERC20
    ) public {
        require(address(userPTokens[msg.sender]) == address(0), "PToken: User token already exists");

        userPTokens[msg.sender] = new PToken(_name, _symbol, _cost, _supply, _acceptedERC20);
        userPTokens[msg.sender].transferOwnership(msg.sender);

        emit NewPToken(userPTokens[msg.sender]);
    }
}
