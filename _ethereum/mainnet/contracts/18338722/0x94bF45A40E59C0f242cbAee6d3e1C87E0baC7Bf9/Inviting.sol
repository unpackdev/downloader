// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./AccessControlEnumerable.sol";
import "./ReentrancyGuard.sol";

/**
 * @title Inviting Contract
 * @author BEBE-TEAM
 * @notice In this contract user can bind inviter
 */
contract Inviting is AccessControlEnumerable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IERC20 public BEBE;
    address public receivingAddr;

    uint256 public price = 1e15;
    uint256[3] public ratio = [1e8 * 1e18, 1e7 * 1e18, 5e6 * 1e18];

    mapping(address => address) public userInviter;

    event BindInviter(address indexed user, address inviter);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    /**
     * @dev Set Addrs
     */
    function setAddrs(
        address _BEBE,
        address _receivingAddr
    ) external onlyRole(MANAGER_ROLE) {
        BEBE = IERC20(_BEBE);
        receivingAddr = _receivingAddr;
    }

    /**
     * @dev Set Data
     */
    function setData(
        uint256 _price,
        uint256[3] calldata _ratio
    ) external onlyRole(MANAGER_ROLE) {
        price = _price;
        ratio = _ratio;
    }

    /**
     * @dev Manager Modify Inviters
     */
    function managerModifyInviters(
        address[] calldata users,
        address[] calldata inviters
    ) external onlyRole(MANAGER_ROLE) {
        for (uint256 i = 0; i < users.length; i++) {
            userInviter[users[i]] = inviters[i];

            if (userInviter[inviters[i]] != address(0)) {
                BEBE.safeTransfer(userInviter[inviters[i]], ratio[2]);
            }

            BEBE.safeTransfer(inviters[i], ratio[1]);
            BEBE.safeTransfer(users[i], ratio[0]);

            emit BindInviter(users[i], inviters[i]);
        }
    }

    /**
     * @dev Claim Token
     */
    function claimToken(
        address token,
        address user,
        uint256 amount
    ) external onlyRole(MANAGER_ROLE) {
        IERC20(token).safeTransfer(user, amount);
    }

    /**
     * @dev bind Inviter
     */
    function bindInviter(address inviter) external payable nonReentrant {
        require(inviter != address(0), "The inviter cannot be empty");
        require(inviter != msg.sender, "The inviter cannot be yourself");
        require(
            userInviter[msg.sender] == address(0),
            "You already have a inviter"
        );
        require(
            userInviter[inviter] != msg.sender,
            "The inviter of the inviter cannot be yourself"
        );

        require(msg.value == price, "Price mismatch");
        payable(receivingAddr).transfer(price);

        userInviter[msg.sender] = inviter;

        if (userInviter[inviter] != address(0)) {
            BEBE.safeTransfer(userInviter[inviter], ratio[2]);
        }

        BEBE.safeTransfer(inviter, ratio[1]);
        BEBE.safeTransfer(msg.sender, ratio[0]);

        emit BindInviter(msg.sender, inviter);
    }
}
