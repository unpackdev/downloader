pragma solidity 0.8.18;

import "./SafeERC20.sol";
import "./Initializable.sol";
import "./emitter.sol";

contract Disburse is Initializable {
    using SafeERC20 for IERC20;

    address private _emitter;

    function initialize(address emitter) external initializer {
        _emitter = emitter;
    }

    function disburseNative(
        address[] calldata recipients,
        uint256[] calldata values
    ) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            payable(recipients[i]).transfer(values[i]);

        uint256 balance = address(this).balance;
        if (balance > 0) payable(msg.sender).transfer(balance);

        ClaimEmitter(_emitter).disburseNative(recipients, values);
    }

    function disburseERC20(
        IERC20 token,
        address[] calldata recipients,
        uint256[] calldata values
    ) external {
        uint256 len = recipients.length;

        for (uint256 i; i < len; ) {
            token.safeTransferFrom(msg.sender, recipients[i], values[i]);

            unchecked {
                ++i;
            }
        }

        ClaimEmitter(_emitter).disburseERC20(
            address(token),
            recipients,
            values
        );
    }
}
