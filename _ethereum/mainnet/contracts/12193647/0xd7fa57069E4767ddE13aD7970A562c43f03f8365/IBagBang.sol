// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBagBang {
    function mintAirdrop(address _to, uint256 _amount) external;
    function mintTreasury(address _to, uint256 _amount) external;
    function mintAdvisors(address _to, uint256 _amount) external;
    function mintDev(address _to, uint256 _amount) external;
    function mintPool(address _to, uint256 _amount) external;
}
