// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";

interface IDonate {
    function signer() external view returns (address);

    function donate(IERC20 _token, uint256 _amount, bytes32 _name, bytes calldata _signature) external payable;

    function withdraw(IERC20 _token, address _to, uint _amount) external;

    function refund(IERC20 _token, address _to, uint256 _amount) external;

    function updateRecipients(address[] memory _recipients, bytes32[] memory _names) external;

    function setRecipient(address _recipient, bytes32 _name) external;

    function updateRecipient(address _recipient, bytes32 _name) external;

    function removeRecipient(bytes32 _name) external;

    function setSigner(address _signer) external;
}
