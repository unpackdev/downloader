/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "./RcaShieldNormalized.sol";
import "./Aave.sol";

contract RcaShieldAave is RcaShieldNormalized {
    using SafeERC20 for IERC20Metadata;

    IIncentivesController public immutable incentivesController;

    constructor(
        string memory _name,
        string memory _symbol,
        address _uToken,
        uint256 _uTokenDecimals,
        address _governance,
        address _controller,
        IIncentivesController _incentivesController
    ) RcaShieldNormalized(_name, _symbol, _uToken, _uTokenDecimals, _governance, _controller) {
        incentivesController = _incentivesController;
    }

    function getReward() external {
        address[] memory assets = new address[](1);
        assets[0] = address(uToken);
        uint256 amount = incentivesController.getRewardsBalance(assets, address(this));
        incentivesController.claimRewards(assets, amount, address(this));
    }

    function purchase(
        address _token,
        uint256 _amount, // token amount to buy
        uint256 _tokenPrice,
        bytes32[] calldata _tokenPriceProof,
        uint256 _underlyingPrice,
        bytes32[] calldata _underlyinPriceProof
    ) external {
        require(_token != address(uToken), "cannot buy underlying token");
        controller.verifyPrice(_token, _tokenPrice, _tokenPriceProof);
        controller.verifyPrice(address(uToken), _underlyingPrice, _underlyinPriceProof);
        uint256 underlyingAmount = (_amount * _tokenPrice) / _underlyingPrice;
        if (discount > 0) {
            underlyingAmount -= (underlyingAmount * discount) / DENOMINATOR;
        }

        IERC20Metadata token = IERC20Metadata(_token);
        // normalize token amount to transfer to the user so that it can handle different decimals
        _amount = (_amount * 10**token.decimals()) / BUFFER;

        token.safeTransfer(msg.sender, _amount);
        uToken.safeTransferFrom(msg.sender, address(this), _normalizedUAmount(underlyingAmount));
    }

    function _afterMint(uint256 _uAmount) internal override {
        // no-op since we get aToken
    }

    function _afterRedeem(uint256 _uAmount) internal override {
        // no-op since we get aToken
    }
}
