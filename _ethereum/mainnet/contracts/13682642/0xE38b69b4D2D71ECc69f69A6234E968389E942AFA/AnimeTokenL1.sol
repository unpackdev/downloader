// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.11;

import "./aeERC20.sol";
import "./ICustomToken.sol";
import "./L1CustomGateway.sol";
import "./L1GatewayRouter.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./AccessControlUpgradeable.sol";

contract AnimeTokenL1 is aeERC20, ICustomToken, AccessControlUpgradeable {
    address public bridge;
    address public router;
    bool private shouldRegisterGateway;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address _bridge, address _router) public {
        bridge = _bridge;
        router = _router;
        aeERC20._initialize("AnimeToken", "ANX", uint8(18));
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(string("AccessControl: account is missing role "));
        }
    }

    function balanceOf(address account)
        public
        view
        override(ERC20Upgradeable, ICustomToken)
        returns (uint256)
    {
        return ERC20Upgradeable.balanceOf(account);
    }

    /// @dev we only set shouldRegisterGateway to true when in `registerTokenOnL2`
    function isArbitrumEnabled() external view override returns (uint8) {
        require(shouldRegisterGateway, "NOT_EXPECTED_CALL");
        return uint8(0xa4b1);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(ERC20Upgradeable, ICustomToken) returns (bool) {
        return ERC20Upgradeable.transferFrom(sender, recipient, amount);
    }

    function registerTokenOnL2(
        address l2CustomTokenAddress,
        uint256 maxSubmissionCostForCustomBridge,
        uint256 maxSubmissionCostForRouter,
        uint256 maxGas,
        uint256 gasPriceBid,
        address creditBackAddress
    ) public override {
        // we temporarily set `shouldRegisterGateway` to true for the callback in registerTokenToL2 to succeed
        bool prev = shouldRegisterGateway;
        shouldRegisterGateway = true;

        L1CustomGateway(bridge).registerTokenToL2(
            l2CustomTokenAddress,
            maxGas,
            gasPriceBid,
            maxSubmissionCostForCustomBridge,
            creditBackAddress
        );

        L1GatewayRouter(router).setGateway(
            bridge,
            maxGas,
            gasPriceBid,
            maxSubmissionCostForRouter,
            creditBackAddress
        );

        shouldRegisterGateway = prev;
    }
}
