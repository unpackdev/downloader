// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface ISwitchSigner {
    function checkUser(address _user) external view returns (bool);
    function verify(uint _mode, address _user, address _singer, bytes32 _message, bytes memory _signature) external view returns (bool);
    function mverify(uint _mode, address _user, address _singer, bytes32 _message, bytes[] memory _signatures) external view returns (bool);
}
