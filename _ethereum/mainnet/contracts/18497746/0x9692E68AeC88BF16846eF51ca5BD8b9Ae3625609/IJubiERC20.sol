// SPDX-License-Identifier: CC-BY-NC-ND-2.5
pragma solidity 0.8.16;

interface IJubiERC20 {
    function minters(address account) external view returns (bool);
    function owner() external view returns (address);
    function pause() external;
    function unpause() external;
    function setMinter(address account, bool canMint) external;
    function mint(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    function recoverERC20(address tokenAddress, address toAddress, uint256 tokenAmount) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function getCurrentVotes(address account) external view returns (uint256);
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
    function snapshot() external returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferOwnership(address newOwner) external;
}