// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./IArbL1CustomGateway.sol";
import "./IArbL1GatewayRouter2.sol";
import "./IArbL1CustomToken.sol";

contract ChemistryToken is
    ERC20,
    ERC20Burnable,
    ERC20Permit,
    ERC20Votes,
    IArbL1CustomToken
{
    address public immutable arbOneGateway;
    address public immutable arbOneRouter;
    address public immutable arbOneToken;
    bool private _shouldRegisterGateway;

    constructor() ERC20("CHEMISTRY", "CHE") ERC20Permit("CHEMISTRY") {
        arbOneGateway = 0xcEe284F754E854890e311e3280b767F80797180d;
        arbOneRouter = 0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef;
        arbOneToken = address(this);

        _mint(msg.sender, 100_000_000 * 10 ** decimals());
    }

    /// @dev we only set shouldRegisterGateway to true when in `registerTokenOnL2`
    function isArbitrumEnabled()
        external
        view
        virtual
        override
        returns (uint8)
    {
        require(_shouldRegisterGateway, "NOT_EXPECTED_CALL");
        return uint8(0xb1);
    }

    function registerTokenOnL2(
        address l2CustomTokenAddress,
        uint256 maxSubmissionCostForCustomGateway,
        uint256 maxSubmissionCostForRouter,
        uint256 maxGasForCustomGateway,
        uint256 maxGasForRouter,
        uint256 gasPriceBid,
        uint256 valueForGateway,
        uint256 valueForRouter,
        address creditBackAddress
    ) public payable virtual override {
        // we temporarily set `_shouldRegisterGateway` to true for the callback in registerTokenToL2 to succeed
        bool prev = _shouldRegisterGateway;
        _shouldRegisterGateway = true;

        IArbL1CustomGateway(arbOneGateway).registerTokenToL2{
            value: valueForGateway
        }(
            l2CustomTokenAddress,
            maxGasForCustomGateway,
            gasPriceBid,
            maxSubmissionCostForCustomGateway,
            creditBackAddress
        );

        IArbL1GatewayRouter2(arbOneRouter).setGateway{value: valueForRouter}(
            arbOneGateway,
            maxGasForRouter,
            gasPriceBid,
            maxSubmissionCostForRouter,
            creditBackAddress
        );

        _shouldRegisterGateway = prev;
    }

    function balanceOf(
        address account
    ) public view virtual override(ERC20, IArbL1CustomToken) returns (uint256) {
        return super.balanceOf(account);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override(ERC20, IArbL1CustomToken) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function _mint(
        address account,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._mint(account, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }
}
