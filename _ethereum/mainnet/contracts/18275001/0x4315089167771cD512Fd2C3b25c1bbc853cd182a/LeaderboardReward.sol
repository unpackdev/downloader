// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC20.sol";
import "./ERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

contract LeaderboardReward is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant OPERATION_ROLE = keccak256("OPERATION_ROLE");

    string public name;

    mapping(address => bool) public supportedTokens;

    event LogSendReward(address token, address[] users, uint256[] amounts, string leaderboardName);

    constructor(string memory _name) {
        name = _name;
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(OPERATION_ROLE, OWNER_ROLE);
        _setupRole(OWNER_ROLE, msg.sender);
    }

    function totalSend(uint256[] memory amounts) internal pure returns (uint256) {
        uint256 length = amounts.length;
        uint256 totalAmount;
        for (uint256 i = 0; i < length; i++) {
            totalAmount += amounts[i];
        }
        return totalAmount;
    }

    function sendReward(
        address token,
        address[] memory recipients,
        uint256[] memory amounts,
        string calldata leaderboardName
    ) external onlyRole(OPERATION_ROLE) {
        require(supportedTokens[token], "unsupported token");
        require(recipients.length > 0, "recipients length invalid");
        require(recipients.length == amounts.length, "recipients length and amounts length are not same");

        uint256 length = recipients.length;
        uint256 totalToSend = totalSend(amounts);
        uint256 currentTokenBalance = IERC20(token).balanceOf(msg.sender);
        require(currentTokenBalance >= totalToSend, "Not enough balance");

        for (uint256 i = 0; i < length; i++) {
            uint256 amount = amounts[i];
            require(amount > 0, "amount invalid");

            IERC20(token).safeTransferFrom(msg.sender, recipients[i], amount);
        }

        emit LogSendReward(token, recipients, amounts, leaderboardName);
    }

    //====== ADMIN FUNCTION
    //operation function
    function setSupportToken(address token, bool status) external onlyRole(OPERATION_ROLE) {
        supportedTokens[token] = status;
    }

    // ============ EMERGENCY FUNCTION ==============

    function emergencyWithdrawERC20(address token, uint amount, address sendTo) external onlyRole(OWNER_ROLE) {
        IERC20(token).safeTransfer(sendTo, amount);
    }

    function emergencyWithdrawNative(uint amount, address payable sendTo) external onlyRole(OWNER_ROLE) {
        (bool success, ) = sendTo.call{ value: amount }("");
        require(success, "withdraw failed");
    }

    function emergencyWithdrawERC721(address sendTo, address token, uint tokenId) external onlyRole(OWNER_ROLE) {
        ERC721(token).transferFrom(address(this), sendTo, tokenId);
    }

    receive() external payable {}
}
