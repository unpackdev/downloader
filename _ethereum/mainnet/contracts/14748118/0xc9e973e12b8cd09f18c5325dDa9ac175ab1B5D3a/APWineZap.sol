// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;
import "./SafeERC20Upgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./Initializable.sol";

import "./IController.sol";
import "./IAMMRouterV1.sol";
import "./IFutureVault.sol";
import "./IRegistry.sol";
import "./IAMMRegistry.sol";
import "./IERC20.sol";
import "./IAMM.sol";
import "./IZapDepositor.sol";
import "./IDepositorRegistry.sol";
import "./ILPToken.sol";

contract APWineZap is Initializable, ERC1155HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20;
    uint256 internal constant UNIT = 10**18;
    uint256 internal constant MAX_UINT256 =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    IAMMRegistry public registry;
    IController public controller;
    IAMMRouterV1 public router;
    IDepositorRegistry public depositorRegistry;

    ILPToken public lpToken;

    modifier isValidAmm(IAMM _amm) {
        require(
            registry.isRegisteredAMM(address(_amm)),
            "AMMRouter: invalid amm address"
        );
        _;
    }

    event RegistrySet(IAMMRegistry _registry);
    event AllTokenApprovalUpdatedForAMM(IAMM _amm);
    event FYTApprovalUpdatedForAMM(IAMM _amm);
    event UnderlyingApprovalUpdatedForDepositor(
        IAMM _amm,
        IZapDepositor _zapDepositor
    );

    event ZappedInScaledToUnderlying(
        address _sender,
        IAMM _amm,
        uint256 _initialUnderlyinValue,
        uint256 _underlyingEarned,
        bool _sellAllFYTs
    );

    event ZappedInToPT(
        address _sender,
        IAMM _amm,
        uint256 _amount,
        uint256 totalPTAmount
    );

    function initialize(
        IController _controller,
        IAMMRouterV1 _router,
        IDepositorRegistry _depositorRegistry,
        ILPToken _lpToken
    ) public virtual initializer {
        registry = _depositorRegistry.registry();
        controller = _controller;
        router = _router;
        depositorRegistry = _depositorRegistry;
        lpToken = _lpToken;
    }

    /**
     * @notice Zap to deposit in protocol and get back the amount of PT that is corresponding to the underlying amount deposited, selling the rest of the FYTs against underlying
     * @param _amm the amm to interact with
     * @param _amount the amount of underlying to deposit
     * @param _inputs 0.minUnderlyingOut 1.deadline
     * @param _referralRecipient referral recipient address if any
     * @param _sellAllFYTs if true, will sell fyt against underlying
     * @return the amount of underlying at the end
     */
    function zapInScaledToUnderlying(
        IAMM _amm,
        uint256 _amount,
        uint256[] calldata _inputs,
        address _referralRecipient,
        bool _sellAllFYTs
    ) public isValidAmm(_amm) returns (uint256) {
        address underlyingAddress = _amm.getUnderlyingOfIBTAddress();
        uint256 ibtAmount =
            depositorRegistry
                .ZapDepositorsPerAMM(address(_amm))
                .depositInProtocolFrom(underlyingAddress, _amount, msg.sender);

        return
            _zapInScaledToUnderlyingWithIBT(
                _amm,
                ibtAmount,
                _inputs,
                _referralRecipient,
                _sellAllFYTs
            );
    }

    /**
     * @notice Zap to deposit in protocol and get back the amount of PT that is corresponding to the underlying amount deposited, selling the rest of the FYTs against underlying
     * @param _amm the amm to interact with
     * @param _amount the amount of IBT to deposit
     * @param _inputs 0.minUnderlyingOut 1.deadline
     * @param _referralRecipient referral recipient address if any
     * @param _sellAllFYTs if true, will sell fyt against underlying
     * @return the amount of underlying at the end
     */
    function zapInScaledToUnderlyingWithIBT(
        IAMM _amm,
        uint256 _amount,
        uint256[] calldata _inputs,
        address _referralRecipient,
        bool _sellAllFYTs
    ) public isValidAmm(_amm) returns (uint256) {
        IERC20(_amm.getIBTAddress()).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        ); // get IBT from caller
        return
            _zapInScaledToUnderlyingWithIBT(
                _amm,
                _amount,
                _inputs,
                _referralRecipient,
                _sellAllFYTs
            );
    }

    /**
     * @notice Zap to deposit in protocol and get back the amount of PT that is corresponding to the underlying amount deposited, selling the rest of the FYTs against underlying
     * @param _amm the amm to interact with
     * @param _amount the amount of IBT to deposit
     * @param _inputs 0.minUnderlyingOut 1.deadline
     * @param _referralRecipient referral recipient address if any
     * @param _sellAllFYTs if true, will sell fyt against underlying
     * @return the amount of underlying at the end
     */
    function _zapInScaledToUnderlyingWithIBT(
        IAMM _amm,
        uint256 _amount,
        uint256[] calldata _inputs,
        address _referralRecipient,
        bool _sellAllFYTs
    ) internal returns (uint256) {
        IFutureVault future = IFutureVault(_amm.getFutureAddress());

        uint256[] memory underlyingAndPTForAmount = new uint256[](2);

        underlyingAndPTForAmount[0] = future.convertIBTToUnderlying(_amount); // underlying value
        underlyingAndPTForAmount[1] = future.getPTPerAmountDeposited(_amount); // ptBalance

        controller.deposit(address(future), _amount); // deposit IBT in future

        uint256 underlyingEarned;

        if (_sellAllFYTs) {
            if (underlyingAndPTForAmount[0] != underlyingAndPTForAmount[1]) {
                underlyingEarned = _executeFYTToScaledSwaps(
                    _amm,
                    underlyingAndPTForAmount,
                    _inputs,
                    _referralRecipient
                );
            } else {
                underlyingEarned = underlyingAndPTForAmount[0];
            }
        } else {
            underlyingEarned = _executeFYTToScaledUnderlyingSwaps(
                _amm,
                underlyingAndPTForAmount,
                _inputs,
                _referralRecipient
            );
        }

        IERC20(future.getPTAddress()).safeTransfer(
            msg.sender,
            underlyingAndPTForAmount[0]
        );
        emit ZappedInScaledToUnderlying(
            msg.sender,
            _amm,
            underlyingAndPTForAmount[0],
            underlyingEarned,
            _sellAllFYTs
        );

        return underlyingEarned;
    }

    /**
     * @notice Zap to deposit in protocol and sell all FYTs against PTs
     * @param _amm the amm to interact with
     * @param _amount the amount of underlying to deposit
     * @param _inputs 0.minPTAmountOut 1.deadline
     * @param _referralRecipient referral recipient address if any
     * @return the amount of PTs at the end
     */
    function zapInToPT(
        IAMM _amm,
        uint256 _amount,
        uint256[] calldata _inputs,
        address _referralRecipient
    ) public isValidAmm(_amm) returns (uint256) {
        address underlyingAddress = _amm.getUnderlyingOfIBTAddress();

        uint256 ibtReceived =
            depositorRegistry
                .ZapDepositorsPerAMM(address(_amm))
                .depositInProtocolFrom(underlyingAddress, _amount, msg.sender);
        return
            _zapInToPTWithIBT(_amm, ibtReceived, _inputs, _referralRecipient);
    }

    /**
     * @notice Zap to deposit in protocol and sell all FYTs against PTs
     * @param _amm the amm to interact with
     * @param _amount the amount of IBT to deposit
     * @param _inputs 0.minPTAmountOut 1.deadline
     * @param _referralRecipient referral recipient address if any
     * @return the amount of PTs at the end
     */
    function zapInToPTWithIBT(
        IAMM _amm,
        uint256 _amount,
        uint256[] calldata _inputs,
        address _referralRecipient
    ) public isValidAmm(_amm) returns (uint256) {
        IERC20(_amm.getIBTAddress()).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        ); // get IBT from caller

        return _zapInToPTWithIBT(_amm, _amount, _inputs, _referralRecipient);
    }

    /**
     * @notice Zap to deposit in protocol and sell all FYTs against PTs
     * @param _amm the amm to interact with
     * @param _amount the amount of IBT to deposit
     * @param _inputs 0.minPTAmountOut 1.deadline
     * @param _referralRecipient referral recipient address if any
     * @return the amount of PTs at the end
     */
    function _zapInToPTWithIBT(
        IAMM _amm,
        uint256 _amount,
        uint256[] calldata _inputs,
        address _referralRecipient
    ) internal returns (uint256) {
        IFutureVault future = IFutureVault(_amm.getFutureAddress());

        controller.deposit(address(future), _amount); // deposit IBT in future and get corresponding PT and FYT.

        uint256 PTBalance =
            IERC20(future.getPTAddress()).balanceOf(address(this));

        uint256 totalPTAmount =
            _executeFYTToPTSwap(_amm, PTBalance, _inputs, _referralRecipient);

        IERC20(future.getPTAddress()).safeTransfer(msg.sender, PTBalance);

        emit ZappedInToPT(msg.sender, _amm, _amount, totalPTAmount);

        return totalPTAmount;
    }

    /**
     * @notice Getter for the underlying amount that can be obtained at the end of the zapInScaledToUnderlying
     * @param _amm the amm to interact with
     * @param _ibtAmountIn the amount of IBT to deposit
     * @return the amount of the underlying after the zap
     */
    function getUnderlyingOutFromZapScaledToUnderlying(
        IAMM _amm,
        uint256 _ibtAmountIn
    ) external view returns (uint256) {
        IFutureVault future = IFutureVault(_amm.getFutureAddress());

        uint256 underlyingValue = future.convertIBTToUnderlying(_ibtAmountIn); // underlying value
        uint256 ptBalance = future.getPTPerAmountDeposited(_ibtAmountIn); // ptBalance

        uint256[] memory pairPath = new uint256[](1);
        pairPath[0] = 1;
        uint256[] memory tokenPath = new uint256[](2);
        tokenPath[0] = 1;
        tokenPath[1] = 0;
        uint256 fytUsedForPT =
            router.getAmountIn(
                _amm,
                pairPath,
                tokenPath,
                underlyingValue - (ptBalance)
            );

        uint256 fytLeftForUnderlying = ptBalance - (fytUsedForPT);

        pairPath = new uint256[](2);
        tokenPath = new uint256[](4);
        pairPath[0] = 1;
        pairPath[1] = 0;
        tokenPath[0] = 1;
        tokenPath[1] = 0;
        tokenPath[2] = 0;
        tokenPath[3] = 1;

        uint256 underlyingOut =
            router.getAmountOut(
                _amm,
                pairPath,
                tokenPath,
                fytLeftForUnderlying
            );
        return underlyingOut;
    }

    /**
     * @notice Getter for the PT amount that can be obtained at the end of the zapInToPT
     * @param _amm the amm to interact with
     * @param _ibtAmountIn the amount of IBT to deposit
     * @return the amount of the PT after the zap
     */
    function getPTOutFromZapToPT(IAMM _amm, uint256 _ibtAmountIn)
        external
        view
        returns (uint256)
    {
        IFutureVault future = IFutureVault(_amm.getFutureAddress());
        uint256 PTBalance = future.getPTPerAmountDeposited(_ibtAmountIn); // ptAndFytBalance
        uint256[] memory pairPath = new uint256[](1);
        pairPath[0] = 1;
        uint256[] memory tokenPath = new uint256[](2);
        tokenPath[0] = 1;
        tokenPath[1] = 0;
        uint256 PTTraded =
            router.getAmountOut(_amm, pairPath, tokenPath, PTBalance);
        return PTTraded + (PTBalance);
    }

    /**
     * @notice internal fonction to swap the FYT balance to PT
     * @param _amm the amm to interact with
     * @param _PTBalance the initial PT balance
     * @param _inputs 0. minAmountOut 1. deadline timestamp
     * @param _referralRecipient the referall recipient address if any
     * @return the total amount of the PT after the zap
     */
    function _executeFYTToPTSwap(
        IAMM _amm,
        uint256 _PTBalance,
        uint256[] memory _inputs,
        address _referralRecipient
    ) internal returns (uint256) {
        uint256[] memory pairPath = new uint256[](1);
        pairPath[0] = 1;
        uint256[] memory tokenPath = new uint256[](2);
        tokenPath[0] = 1;
        tokenPath[1] = 0;
        uint256 PTEarned =
            router.swapExactAmountIn(
                _amm,
                pairPath, // e.g. [0, 1] -> will swap on pair 0 then 1
                tokenPath, // e.g. [1, 0, 0, 1] -> will swap on pair 0 from token 1 to 0, then swap on pair 1 from token 0 to 1.
                _PTBalance,
                _inputs[0] > _PTBalance ? _inputs[0] - (_PTBalance) : 0,
                msg.sender,
                _inputs[1],
                _referralRecipient
            ); // swap all FYTs against more PTs

        return PTEarned + (_PTBalance);
    }

    /**
     * @notice Swap FYT to have PT balance equal the underlying value deposited, and swap the remaining FYT to underlying
     * @param _amm the amm to interact with
     * @param _underlyingAndPTForAmount 0. the underlying value of the ibt deposited 1. the obtained PT amount with the amount deposited
     * @param _inputs 0. minAmountOut 1. deadline timestamp
     * @param _referralRecipient the referall recipient address if any
     * @return the total underlying amount after the swaps
     */
    function _executeFYTToScaledSwaps(
        IAMM _amm,
        uint256[] memory _underlyingAndPTForAmount,
        uint256[] memory _inputs,
        address _referralRecipient
    ) internal returns (uint256) {
        uint256[] memory pairPath = new uint256[](1);
        pairPath[0] = 1;
        uint256[] memory tokenPath = new uint256[](2);
        tokenPath[0] = 1;
        tokenPath[1] = 0;

        uint256 PTstoSwap;
        {
            uint256 newPTs =
                router.swapExactAmountIn(
                    _amm,
                    pairPath,
                    tokenPath,
                    _underlyingAndPTForAmount[1],
                    0,
                    msg.sender,
                    _inputs[1],
                    _referralRecipient
                ); // swap against PT

            if (IERC20(_amm.getFYTAddress()).balanceOf(address(this)) == 0)
                return 0;

            PTstoSwap =
                newPTs -
                (_underlyingAndPTForAmount[0] - _underlyingAndPTForAmount[1]);
        }

        uint256 underlyingOut =
            router.swapExactAmountIn(
                _amm,
                pairPath,
                tokenPath,
                PTstoSwap,
                _inputs[0],
                msg.sender,
                _inputs[1],
                _referralRecipient
            ); // swap against underlying
        return underlyingOut;
    }

    /**
     * @notice Swap FYT to have PT balance equal the underlying value deposited, and send te remaining FYTs to the caller
     * @param _amm the amm to interact with
     * @param _underlyingAndPTForAmount 0. the underlying value of the ibt deposited 1. the obtained PT amount with the amount deposited
     * @param _inputs 0. minAmountOut 1. deadline timestamp
     * @param _referralRecipient the referall recipient address if any
     * @return the remaining FYTs amount after the swap
     */
    function _executeFYTToScaledUnderlyingSwaps(
        IAMM _amm,
        uint256[] memory _underlyingAndPTForAmount,
        uint256[] memory _inputs,
        address _referralRecipient
    ) internal returns (uint256) {
        uint256[] memory pairPath = new uint256[](1);
        pairPath[0] = 1;
        uint256[] memory tokenPath = new uint256[](2);
        tokenPath[0] = 1;
        tokenPath[1] = 0;
        uint256 fytSold =
            router.swapExactAmountOut(
                _amm,
                pairPath,
                tokenPath,
                _underlyingAndPTForAmount[1],
                _underlyingAndPTForAmount[0] - (_underlyingAndPTForAmount[1]),
                msg.sender,
                _inputs[1],
                _referralRecipient
            ); // swap extra fyt to get an amount of pt = underlyingValue
        uint256 FYTsLeft = _underlyingAndPTForAmount[1] - (fytSold);
        IERC20(_amm.getFYTAddress()).transfer(msg.sender, FYTsLeft);
        return FYTsLeft;
    }

    function _getUnderlyingAndDepositToProtocol(IAMM _amm, uint256 _amount)
        internal
        returns (uint256)
    {
        address underlyingAddress = _amm.getUnderlyingOfIBTAddress();
        IERC20(underlyingAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        ); // get IBT from caller

        return
            depositorRegistry
                .ZapDepositorsPerAMM(address(_amm))
                .depositInProtocol(underlyingAddress, _amount);
    }

    function updateAllTokensApprovalForAMM(IAMM _amm)
        external
        isValidAmm(_amm)
    {
        IFutureVault future = IFutureVault(_amm.getFutureAddress());

        IERC20 ibt = IERC20(future.getIBTAddress());
        ibt.safeIncreaseAllowance(
            address(controller),
            MAX_UINT256 - (ibt.allowance(address(this), address(_amm)))
        ); // Approve controller for IBT

        IERC20 pt = IERC20(future.getPTAddress());
        pt.safeIncreaseAllowance(
            address(router),
            MAX_UINT256 - (pt.allowance(address(this), address(router)))
        ); // Approve router for PT
        pt.safeIncreaseAllowance(
            address(_amm),
            MAX_UINT256 - (pt.allowance(address(this), address(_amm)))
        ); // Approve amm for PT

        IERC20 underlying = IERC20(_amm.getUnderlyingOfIBTAddress());

        underlying.safeIncreaseAllowance(
            address(_amm),
            MAX_UINT256 - (underlying.allowance(address(this), address(_amm)))
        );

        IERC20 fyt =
            IERC20(future.getFYTofPeriod(future.getCurrentPeriodIndex()));
        fyt.safeIncreaseAllowance(
            address(router),
            MAX_UINT256 - (fyt.allowance(address(this), address(router)))
        ); // Approve router for FYT
        emit FYTApprovalUpdatedForAMM(_amm);
        emit AllTokenApprovalUpdatedForAMM(_amm);
    }

    function updateFYTApprovalForAMM(IAMM _amm) external isValidAmm(_amm) {
        IFutureVault future = IFutureVault(_amm.getFutureAddress());
        IERC20 fyt =
            IERC20(future.getFYTofPeriod(future.getCurrentPeriodIndex()));
        fyt.safeIncreaseAllowance(
            address(router),
            MAX_UINT256 - (fyt.allowance(address(this), address(router)))
        ); // Approve router for FYT
        emit FYTApprovalUpdatedForAMM(_amm);
    }

    function updateUnderlyingApprovalForDepositor(IAMM _amm)
        external
        isValidAmm(_amm)
    {
        IZapDepositor zapDepositor =
            depositorRegistry.ZapDepositorsPerAMM(address(_amm));
        IERC20 underlying = IERC20(_amm.getUnderlyingOfIBTAddress());
        underlying.safeIncreaseAllowance(
            address(zapDepositor),
            MAX_UINT256 -
                (underlying.allowance(address(this), address(zapDepositor)))
        );

        emit UnderlyingApprovalUpdatedForDepositor(_amm, zapDepositor);
    }
}
