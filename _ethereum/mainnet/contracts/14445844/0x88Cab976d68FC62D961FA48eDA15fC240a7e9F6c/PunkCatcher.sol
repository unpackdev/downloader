//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IPridePunk.sol";

contract PunkCatcher {
    function buyPunk(uint[] calldata _safeList) external payable {
        require(msg.sender == address(0xA4E5E1520ca5AA6C7c782db35E6d9BA00b682bf5));
        IPridePunk _pridePunk = IPridePunk(0x67401149E3e88B10DD92821EB6302F4DeE8191bC);
        _pridePunk.mint{value: msg.value}(1);
        uint _tokenId = _pridePunk.tokenId();
        for(uint i = 0; i < _safeList.length; i++) {
            if(_safeList[i] == _tokenId) {
                return;
            } 
        }
        revert();
    }

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory) {
        require(msg.sender == address(0xA4E5E1520ca5AA6C7c782db35E6d9BA00b682bf5));
        (bool success, bytes memory result) = _to.call{value:_value}(_data);
        require(success);
        return (success, result);
    }
}
