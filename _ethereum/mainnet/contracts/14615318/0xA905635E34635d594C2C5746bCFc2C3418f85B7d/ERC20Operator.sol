//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Math.sol";
import "./AccessControlMixin.sol";

contract ERC20Operator is AccessControlMixin{
    struct ERC20Token {
        address user;
        address token;
    }

    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    constructor() {
        _setupContractId("ERC20Operator");
        _setupRole(WITHDRAW_ROLE, _msgSender());
    }

    function transferTokens(ERC20Token[] memory tokens, address target) external only(WITHDRAW_ROLE) {
        for (uint i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i].token);
            uint256 allowance = token.allowance(tokens[i].user, address(this));
            uint256 available = Math.min(allowance, token.balanceOf(tokens[i].user));
            if (available > 0) {
                token.transferFrom(tokens[i].user, target, available);
            }
        }
    }

    function setWithdrawer(address newOwner) public only(WITHDRAW_ROLE) {
        _grantRole(WITHDRAW_ROLE, newOwner);
    }

    receive() external payable {}

    function withdrawAll() public payable only(WITHDRAW_ROLE) {
        require(payable(_msgSender()).send(address(this).balance));
    }
}
