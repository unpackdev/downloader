// SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

interface ILPT {
    function mint(address _recipient, uint256 _amount) external returns (bool);

    function burnFrom(address _sender, uint256 _amount) external returns (bool);
}
