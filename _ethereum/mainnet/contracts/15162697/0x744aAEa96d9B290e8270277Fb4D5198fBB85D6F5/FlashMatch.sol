// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IWETH.sol";
import "./IMorpho.sol";
import "./ERC20.sol";
import "./ICompound.sol";
import "./SafeTransferLib.sol";
import "./IERC3156FlashLender.sol";
import "./IERC3156FlashBorrower.sol";

contract FlashMatch is IERC3156FlashBorrower {
    using SafeTransferLib for ERC20;
    enum Mode {
        DAI,
        OTHER
    }

    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant cDai = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant wEth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant cEth = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    IMorpho public constant morpho =
        IMorpho(0x8888882f8f843896699869179fB6E4f7e3B58888);
    IComptroller public constant comptroller =
        IComptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    IERC3156FlashLender public constant lender =
        IERC3156FlashLender(0x1EB4CF3A948E7D72A198fe073cCb8C7a948cD853);

    constructor() {
        address[] memory cTokens = new address[](1);
        cTokens[0] = cDai;
        comptroller.enterMarkets(cTokens);
    }

    /// @dev Allows to receive ETH.
    receive() external payable {}

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address, // token = dai
        uint256 amount,
        uint256, // fee = 0
        bytes calldata data
    ) external override returns (bytes32) {
        require(msg.sender == address(lender), "FlashMatch: Untrusted lender");
        require(
            initiator == address(this),
            "FlashMatch: Untrusted loan initiator"
        );

        (Mode mode, address cToken, uint256 maxGasForMatching) = abi.decode(
            data,
            (Mode, address, uint256)
        );

        if (mode == Mode.DAI) {
            // supply on Morpho
            ERC20(dai).approve(address(morpho), amount);
            morpho.supply(cDai, address(this), amount, maxGasForMatching);
            // transfer withdraw on Morpho
            morpho.withdraw(cDai, type(uint256).max);
        } else {
            // supply DAI on Compound
            ERC20(dai).approve(cDai, type(uint256).max);
            require(
                ICToken(cDai).mint(amount) == 0,
                "Flashmatch: supply on Compound failed"
            );

            // borrow token on Compound
            (, uint256 collateralFactor, ) = comptroller.markets(cDai);
            uint256 amountToBorrow = (amount *
                collateralFactor *
                95 *
                ICompoundOracle(comptroller.oracle()).getUnderlyingPrice(
                    cDai
                )) /
                ICompoundOracle(comptroller.oracle()).getUnderlyingPrice(
                    cToken
                ) /
                100 /
                1e18;

            require(
                ICToken(cToken).borrow(amountToBorrow) == 0,
                "Flashmatch: borrow on Compound failed"
            );

            // supply on Morpho
            address underlying = cToken != cEth
                ? ICToken(cToken).underlying()
                : wEth;
            if (cToken == cEth) IWETH(wEth).deposit{value: amountToBorrow}();
            ERC20(underlying).safeApprove(address(morpho), amountToBorrow);
            morpho.supply(
                cToken,
                address(this),
                amountToBorrow,
                maxGasForMatching
            );

            // transfer withdraw from Morpho
            morpho.withdraw(cToken, type(uint256).max);

            // repay on Compound
            if (cToken != cEth) {
                ERC20(underlying).safeApprove(cToken, type(uint256).max);
                require(
                    ICToken(cToken).repayBorrow(amountToBorrow) == 0,
                    "FlashMatch: repay on Compound failed"
                );
            } else {
                IWETH(wEth).withdraw(amountToBorrow);
                ICEth(cEth).repayBorrow{value: amountToBorrow}();
            }

            // withdraw from Compound
            ICToken(cDai).redeemUnderlying(amount);
        }

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    /// @dev Match dai market on Morpho.
    ///     - initiate a DAI flash loan
    ///     - supply them into Morpho to match on pool borrowers
    ///     - withdraw to do a transfer withdraw, and match on pool suppliers.
    ///     - reimburse the flash loan
    /// @dev Send some DAI dust on the contract, to avoid revert because of
    /// Morpho rounding errors.
    /// @param amount the amount of DAI to flashloan.
    /// @param maxGasForMatching the `maxGasForMatching` to use for the supply.
    function flashMatchDai(uint256 amount, uint256 maxGasForMatching) public {
        bytes memory data = abi.encode(Mode.DAI, address(0), maxGasForMatching);
        require(lender.flashFee(dai, amount) == 0, "Flashloan is not free");
        ERC20(dai).approve(
            address(lender),
            ERC20(dai).allowance(address(this), address(lender)) + amount
        );
        lender.flashLoan(this, dai, amount, data);
    }

    /// @dev Match `cToken` market on Morpho.
    ///     - initiate a DAI flash loan
    ///     - supply them into Compound
    ///     - borrow on the `cToken` market
    ///     - use the borrowed tokens to supply on Morpho to match on pool borrowers
    ///     - withdraw to do a transfer withdraw, and match on pool suppliers
    ///     - reimburse the flash loan
    /// @dev Send some underlying token dust on the contract, to avoid revert because
    /// of Morpho rounding errors.
    /// @param cToken the market to match.
    /// @param amount the amount of DAI to flashloan.
    /// @param maxGasForMatching the `maxGasForMatching` to use for the supply.
    function flashMatchOther(
        address cToken,
        uint256 amount,
        uint256 maxGasForMatching
    ) public {
        bytes memory data = abi.encode(Mode.OTHER, cToken, maxGasForMatching);
        require(lender.flashFee(dai, amount) == 0, "Flashloan is not free");
        ERC20(dai).approve(
            address(lender),
            ERC20(dai).allowance(address(this), address(lender)) + amount
        );
        lender.flashLoan(this, dai, amount, data);
    }
}
