// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./BaseContract.sol";
import "./Utils.sol";
import "./IWhitelist.sol";
import "./IWithdrawTransfer.sol";

contract WithdrawTransfer is
    BaseContract,
    IWithdrawTransfer,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Role definitions
    bytes32 public constant WITHDRAW_OPERATOR_ROLE =
        keccak256("WITHDRAW_OPERATOR_ROLE");

    // State variables
    /// @dev the `Whitelist` contract address where the whitelisted tokens are stored.
    address public s_whitelist;

    mapping(string => bool) private s_executedWithdrawRequest;

    // reserved for possible future storages
    uint256[50] private __gap;

    function initialize(address whitelist, address defaultAdmin) public initializer {
        __BaseContract_init(defaultAdmin);
        __Withdraw_init(whitelist);
    }

    function __Withdraw_init(address whitelist) internal onlyInitializing {
        __Withdraw_init_unchained(whitelist);
    }

    function __Withdraw_init_unchained(
        address whitelist
    ) internal onlyInitializing {
        s_whitelist = whitelist;

        _grantRole(WITHDRAW_OPERATOR_ROLE, _msgSender());
    }

    receive() external payable {}

    modifier onlyUnexecutedRequest(string memory requestId) {
        _onlyUnexecutedRequest(requestId);
        _;
    }

    function _onlyUnexecutedRequest(string memory requestId) private view {
        require(
            !s_executedWithdrawRequest[requestId],
            "WithdrawTransfer: Request has already been executed"
        );
    }

    function withdrawTransfers(
        WithdrawRequest[] memory withdrawRequests
    )
        external
        payable
        onlyRole(WITHDRAW_OPERATOR_ROLE)
        whenNotPaused
        nonReentrant
    {
        for (uint256 i = 0; i < withdrawRequests.length; i++) {
            _withdrawTransfer(withdrawRequests[i]);
        }

        emit Withdraws(withdrawRequests);
    }

    function _withdrawTransfer(
        WithdrawRequest memory withdrawRequest
    ) internal onlyUnexecutedRequest(withdrawRequest.requestId) {
        s_executedWithdrawRequest[withdrawRequest.requestId] = true;
        _transferFund(
            withdrawRequest.fromHotWallet,
            withdrawRequest.receiverAddress,
            withdrawRequest.tokenAddress,
            withdrawRequest.amount
        );
    }

    function _transferFund(
        address sender,
        address recipient,
        address token,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            // Handle native token
            if (recipient == address(this)) {
                // send native token to contract
                require(
                    msg.value == amount,
                    "WithdrawTransfer: native token amount unmatched"
                );
            } else if (sender == address(this)) {
                // Send from this contract
                (bool success, ) = recipient.call{value: amount}("");
                require(success, "WithdrawTransfer: transfer failed");
            }
        } else {
            // check whitelisted token
            bool t_isWhitelistedToken = IWhitelist(s_whitelist)
                .isWhitelistedToken(token);

            if(!t_isWhitelistedToken) {
                revert(
                    string(
                        abi.encodePacked(
                            "DepositCollector: token ",
                            StringsUpgradeable.toHexString(token),
                            " is not whitelisted"
                        )
                    )
                );
            }
            //Handle ERC20
            if (sender == address(this)) {
                IERC20Upgradeable(token).safeTransfer(recipient, amount);
            } else {
                IERC20Upgradeable(token).safeTransferFrom(
                    sender,
                    recipient,
                    amount
                );
            }
        }
    }
}
