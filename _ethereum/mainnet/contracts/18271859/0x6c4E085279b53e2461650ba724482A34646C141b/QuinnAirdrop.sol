// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10 >=0.8.0 <0.9.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Context.sol";

contract QuinnAirdrop is Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) public hasBeenAirdropped;

    IERC20 public quinn;
    uint256 totalAirdropped;

    constructor(address _newToken) {
        quinn = IERC20(_newToken);
    }

    event Airdropped(address[] user, uint256[] amounts);

    receive() external payable {}

    function AirdropQuinn(
        address[] memory users,
        uint256[] memory amounts
    ) public onlyOwner {
        require(
            users.length == amounts.length,
            "Users and amounts arrays should must have the same length"
        );

        uint256 i = 0;
        while (i < users.length) {
            if (hasBeenAirdropped[users[i]]) {
                unchecked {
                    ++i;
                }
            } else {
                quinn.safeTransfer(users[i], amounts[i]);
                hasBeenAirdropped[users[i]] = true;
                unchecked {
                    ++i;
                }
            }
        }
        emit Airdropped(users, amounts);
    }

    function RecoverToken(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(0), "Invalid address");
        require(_amount > 0, "Invalid amount");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}
