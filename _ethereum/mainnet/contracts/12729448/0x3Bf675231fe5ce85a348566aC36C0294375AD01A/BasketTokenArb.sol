// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./IUniRouter.sol";
import "./ISingleTokenJoin.sol";

contract BasketTokenArb is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    IERC20 private WRAPPED_TOKEN;
    IUniRouter private uniRouter;
    ISingleTokenJoin private poolJoiner;

    constructor(
        address wrappedNativeToken,
        address _uniRouter,
        address _poolJoiner
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());

        WRAPPED_TOKEN = IERC20(wrappedNativeToken);
        uniRouter = IUniRouter(_uniRouter);
        poolJoiner = ISingleTokenJoin(_poolJoiner);

        WRAPPED_TOKEN.approve(address(poolJoiner), type(uint256).max);
    }

    /// @dev mint basket token with native blockchain wrapped token, arb basket token for wrapped token, transfer wrapped token amount to sender.
    function arb(
        ISingleTokenJoin.JoinTokenStruct calldata _joinTokenStruct,
        uint256 expectedArbReturn,
        uint256 callerBasketTokensToUse
    ) external {
        require(hasRole(MANAGER_ROLE, msg.sender), "arb: !manager");

        require(
            _joinTokenStruct.inputToken == address(WRAPPED_TOKEN),
            "arb: !WRAPPED_TOKEN"
        );

        if (_joinTokenStruct.outputAmount > 0) {
            // transfer wrapped token to arb contract
            WRAPPED_TOKEN.safeTransferFrom(
                msg.sender,
                address(this),
                _joinTokenStruct.inputAmount
            );

            poolJoiner.joinTokenSingle(_joinTokenStruct);
        }

        if (callerBasketTokensToUse > 0) {
            IERC20(_joinTokenStruct.outputBasket).safeTransferFrom(
                msg.sender,
                address(this),
                callerBasketTokensToUse
            );
        }

        uint256 balanceOfBasketToken = IERC20(_joinTokenStruct.outputBasket)
        .balanceOf(address(this));

        _swap(
            _joinTokenStruct.outputBasket,
            balanceOfBasketToken,
            _joinTokenStruct.deadline,
            expectedArbReturn
        );

        uint256 balanceOfWeth = WRAPPED_TOKEN.balanceOf(address(this));
        WRAPPED_TOKEN.safeTransfer(msg.sender, balanceOfWeth);
    }

    /// @dev swap basket token for WRAPPED_TOKEN
    function _swap(
        address _inputBasketToken,
        uint256 _inputAmount,
        uint256 _deadline,
        uint256 _expectedArbReturn
    ) private {
        address[] memory route = new address[](2);
        route[0] = _inputBasketToken;
        route[1] = address(WRAPPED_TOKEN);

        IERC20 inputToken = IERC20(_inputBasketToken);
        inputToken.approve(address(uniRouter), _inputAmount);

        uniRouter.swapExactTokensForTokens(
            _inputAmount,
            _expectedArbReturn,
            route,
            address(this),
            _deadline
        );
    }
}
