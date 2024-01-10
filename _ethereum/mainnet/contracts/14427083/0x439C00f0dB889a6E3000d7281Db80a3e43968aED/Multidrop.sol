//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract Multidrop is ReentrancyGuard {
    using SafeERC20 for IERC20;

    event tokenDropped(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 amount
    );
    event ETHdropped(address indexed from, address indexed to, uint256 amount);

    modifier validList(address[] memory users, uint256[] memory values) {
        require(users.length == values.length, "Users - Invalid length");
        require(users.length > 0, "Empty calldata");
        _;
    }

    constructor() payable {}

    function sendETH(address[] memory users, uint256[] memory values)
        public
        payable
        nonReentrant
        validList(users, values)
    {
        uint256 totalETHValue = msg.value;

        // handle indexes drop
        for (uint256 i = 0; i < users.length; i++) {
            address currentUser = users[i];
            require(
                totalETHValue > 0,
                "Not enough ETH to complete this transaction"
            );
            require(currentUser != address(0), "No burning ETH");
            totalETHValue -= values[i];
            (bool sent, ) = currentUser.call{value: values[i]}("");
            require(sent, "Failed to send Ether");

            emit ETHdropped(msg.sender, currentUser, values[i]);
        }

    }

    function sendToken(
        address[] memory users,
        uint256[] memory values,
        IERC20 token
    ) public payable nonReentrant validList(users, values) {

        // handle indexes drop
        for (uint256 i = 0; i < users.length; i++) {
            token.safeTransferFrom(msg.sender, users[i], values[i]);

            emit tokenDropped(msg.sender, users[i], address(token), values[i]);
        }

    }

    // to support receiving ETH by default
    receive() external payable {}

    fallback() external payable {}
}
