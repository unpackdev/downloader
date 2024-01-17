/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "./RcaShieldNormalized.sol";
import "./Badger.sol";

contract RcaShieldBadger is RcaShieldNormalized {
    using SafeERC20 for IERC20Metadata;

    IBadgerTreeV2 public immutable badgerTree;

    constructor(
        string memory _name,
        string memory _symbol,
        address _uToken,
        uint256 _uTokenDecimals,
        address _governance,
        address _controller,
        IBadgerTreeV2 _badgerTree
    ) RcaShieldNormalized(_name, _symbol, _uToken, _uTokenDecimals, _governance, _controller) {
        badgerTree = _badgerTree;
    }

    function getReward(
        address[] memory tokens,
        uint256[] memory cumulativeAmounts,
        uint256 index,
        uint256 cycle,
        bytes32[] memory merkleProof,
        uint256[] memory amountsToClaim
    ) external {
        badgerTree.claim(tokens, cumulativeAmounts, index, cycle, merkleProof, amountsToClaim);
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
        uToken.safeTransferFrom(msg.sender, address(this), _normalizedUAmount(underlyingAmount));

        IERC20Metadata token = IERC20Metadata(_token);
        // normalize token amount to transfer to the user so that it can handle different decimals
        _amount = (_amount * 10**token.decimals()) / BUFFER;

        token.safeTransfer(msg.sender, _amount);
    }

    function _afterMint(uint256 _uAmount) internal override {
        // no-op since we get bToken
    }

    function _afterRedeem(uint256 _uAmount) internal override {
        // no-op since we get bToken
    }
}
