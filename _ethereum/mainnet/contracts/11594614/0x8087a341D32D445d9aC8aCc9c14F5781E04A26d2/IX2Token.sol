// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2Token {
    function distributor() external view returns (address);
    function _totalSupply() external view returns (uint256);
    function _balanceOf(address account) external view returns (uint256);
    function market() external view returns (address);
    function getDivisor() external view returns (uint256);
    function getReward(address account) external view returns (uint256);
    function costOf(address account) external view returns (uint256);
    function mint(address account, uint256 amount, uint256 divisor) external;
    function burn(address account, uint256 amount, bool distribute) external;
    function setDistributor(address _distributor) external;
    function setInfo(string memory name, string memory symbol) external;
}
