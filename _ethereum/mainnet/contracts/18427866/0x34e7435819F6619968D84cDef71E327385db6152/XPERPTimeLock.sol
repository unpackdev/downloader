// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
//____  ____________________________________________
//\   \/  /\______   \_   _____/\______   \______   \
// \     /  |     ___/|    __)_  |       _/|     ___/
// /     \  |    |    |        \ |    |   \|    |
///___/\  \ |____|   /_______  / |____|_  /|____|
//      \_/                  \/         \/
// xperp team timelock contract
// https://xperp.tech

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

/// @notice This contract is used to lock the team tokens until fixed unchangeable time
contract XPERPTimeLock {
    uint256 private constant ENTERED = 1;
    uint256 private constant NOT_ENTERED = 0;

    /// @notice xperp token contract
    IERC20 public xperpToken;
    /// @notice team address
    address public teamAddress;
    /// @notice unlock time, it is set to 12th November 2023 00:00:00 UTC
    uint256 public unlockTime;
    uint256 private reentrancyStatus;

    constructor(IERC20 _token, address _teamAddress) {
        xperpToken = _token;
        teamAddress = _teamAddress;
        // Set unlock time to 12th November 2023 00:00:00 UTC
        unlockTime = 1699747200;
    }

    /// @notice Deposit the xperp tokens to the contract, approve the xperp contract to spend the tokens on behalf of teamAddress before calling this function
    function deposit(uint256 _amount) external {
        require(msg.sender == teamAddress, "Only the team can deposit tokens");
        require(block.timestamp < unlockTime, "Tokens are unlocked");
        require(xperpToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
    }

    /// @notice Withdraw the xperp tokens from the contract
    function withdraw() external {
        if (reentrancyStatus == ENTERED)
            revert("ReentrancyGuard: reentrant call");
        reentrancyStatus = ENTERED;
        require(msg.sender == teamAddress, "Only the team can withdraw tokens");
        require(block.timestamp >= unlockTime, "Tokens are locked");
        uint256 balance = xperpToken.balanceOf(address(this));
        require(xperpToken.transfer(teamAddress, balance), "Transfer failed");
        reentrancyStatus = NOT_ENTERED;
    }

    /// @notice Recover the eth sent by mistake to the contract
    function recoverEth() external {
        require(msg.sender == teamAddress, "Only the team can recover eth");
        payable(teamAddress).transfer(address(this).balance);
    }

    /// @notice Recover the erc20 tokens sent by mistake to the contract, xperp can't be recovered using this function
    function recoverERC20ExceptForXperp(address _tokenAddress, uint256 _amount) external {
        require(msg.sender == teamAddress, "Only the team can recover tokens sent by mistake");
        require(_tokenAddress != address(xperpToken), "Cannot recover the token which is locked");
        IERC20(_tokenAddress).transfer(teamAddress, _amount);
    }

}
