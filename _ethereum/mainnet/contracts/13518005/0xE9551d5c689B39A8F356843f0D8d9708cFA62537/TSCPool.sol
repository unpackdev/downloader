// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./TSC.sol";

contract TscPool is Ownable {
    event Created(address indexed _creator, address _contracts);
    event AddTokenOptions(address[] _tokenOptions);
    event RemoveTokenOptions(address _token);

    mapping(address => bool) public tokenOptions;

    function setTokenOptions(address[] memory _tokenOptions) public onlyOwner {
        for (uint256 i = 0; i < _tokenOptions.length; i++) {
            tokenOptions[_tokenOptions[i]] = true;
        }
        emit AddTokenOptions(_tokenOptions);
    }

    function removeTokenOption(address _token) public {
        require(tokenOptions[_token], "TSCPool: This token is not on the list");
        tokenOptions[_token] = false;
        emit RemoveTokenOptions(_token);
    }

    function checkTokenOption(address _token) public view returns (bool) {
        return tokenOptions[_token];
    }

    function create() external returns (address) {
        TSC contracts = new TSC(address(this));
        contracts.transferOwnership(msg.sender);
        emit Created(msg.sender, address(contracts));
        return address(contracts);
    }
}
