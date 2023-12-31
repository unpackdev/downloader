// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20Upgradeable.sol";
import "./IPaymentGateUpgreadeable.sol";
import "./BaseUpgradeable.sol";
import "./SafeTransfer.sol";
import "./Constants.sol";

contract PaymentGatewayUpgradeable is IPaymentGateUpgreadeable, BaseUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address roleManager_) external initializer {
        __BaseUpgradeable_init_unchained(roleManager_);
    }

    receive() external payable {}

    fallback() external payable {}

    function execute(
        PaymentInfo calldata paymentInfo_,
        Operation calldata exchange_,
        Operation memory afterExchange_
    ) external payable {
        address proxy = address(this);

        if (paymentInfo_.paymentInToken != address(0)) {
            SafeTransferLib.safeTransferFrom(
                paymentInfo_.paymentInToken,
                _msgSender(),
                proxy,
                paymentInfo_.paymentInAmount
            );
        } else {
            require(msg.value >= paymentInfo_.paymentInAmount, "IB");
        }

        if (paymentInfo_.paymentInToken != paymentInfo_.paymentOutToken) {
            if (paymentInfo_.paymentInToken != address(0)) {
                SafeTransferLib.safeApprove(paymentInfo_.paymentInToken, exchange_.to, paymentInfo_.paymentInAmount);
            }
            _call(exchange_);
        }

        if (paymentInfo_.paymentOutToken != address(0)) {
            SafeTransferLib.safeApprove(
                paymentInfo_.paymentOutToken,
                afterExchange_.to,
                IERC20Upgradeable(paymentInfo_.paymentOutToken).balanceOf(proxy)
            );
        }

        afterExchange_.value = uint96(address(this).balance);
        _call(afterExchange_);
    }

    function withdraw(address token_, uint256 amount_) external onlyRole(OPERATOR_ROLE) {
        if (token_ == address(0)) {
            SafeTransferLib.safeTransferETH(msg.sender, amount_);
        } else {
            SafeTransferLib.safeTransfer(token_, msg.sender, amount_);
        }
    }
}
