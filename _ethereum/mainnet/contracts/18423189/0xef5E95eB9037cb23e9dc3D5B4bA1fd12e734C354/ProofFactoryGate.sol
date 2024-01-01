// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ProofFactoryFees.sol";

import "./IUniswapV2Router02.sol";
import "./IProofFactoryTokenCutter.sol";
import "./IProofFactoryGate.sol";

import "./ProofFactoryTokenCutter.sol";

contract ProofFactoryGate is Ownable, IProofFactoryGate {
    using SafeERC20 for IERC20;

    address public proofFactory;
    modifier onlyFactory() {
        require(msg.sender == proofFactory, "only factory");
        _;
    }

    constructor() {}

    function updateProofFactory(
        address _proofFactory
    ) external override onlyOwner {
        require(_proofFactory != address(0), "zero ProofFactory address");
        proofFactory = _proofFactory;
    }

    function createToken(
        IProofFactory.TokenParam memory tokenParam_,
        address _routerAddress,
        address _proofAdmin,
        address _owner
    ) external override onlyFactory returns (address) {
        //create token
        ProofFactoryFees.allFees memory fees = ProofFactoryFees.allFees(
            tokenParam_.initialReflectionFee,
            tokenParam_.initialReflectionFeeOnSell,
            tokenParam_.initialLpFee,
            tokenParam_.initialLpFeeOnSell,
            tokenParam_.initialDevFee,
            tokenParam_.initialDevFeeOnSell
        );
        ProofFactoryTokenCutter newToken = new ProofFactoryTokenCutter();
        address newTokenAddress = address(newToken);

        IProofFactoryTokenCutter(newTokenAddress).setBasicData(
            IProofFactoryTokenCutter.BaseData(
                tokenParam_.tokenName,
                tokenParam_.tokenSymbol,
                tokenParam_.initialSupply,
                tokenParam_.percentToLP,
                _owner,
                tokenParam_.devWallet,
                tokenParam_.reflectionToken,
                _routerAddress,
                _proofAdmin,
                tokenParam_.antiSnipeDuration
            ),
            fees
        );

        IProofFactoryTokenCutter(newTokenAddress).updateProofFactory(
            proofFactory
        );

        uint256 balance = IERC20(newTokenAddress).balanceOf(address(this));
        IERC20(newTokenAddress).safeTransfer(proofFactory, balance);

        return newTokenAddress;
    }

    receive() external payable {}
}
