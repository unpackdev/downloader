// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


import "./IWETH.sol";
import "./IERC20.sol";
import "./IOctusCallback.sol";
import "./IMultiVaultFacetWithdraw.sol";
import "./IMultiVaultFacetPendingWithdrawals.sol";
import "./IMultiVaultFacetSettings.sol";
import "./Initializable.sol";

import "./SafeERC20.sol";


contract UnwrapNativeToken is IOctusCallbackAlien, Initializable {
    IWETH wethContract;
    address multiVault;

    using SafeERC20 for IERC20;

    mapping(address => mapping(uint => bool)) pendingWithdrawals;

    modifier notZeroAddress(address addr) {
        require(addr != address(0));

        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _weth,
        address _multiVault
    ) public initializer notZeroAddress(_weth) notZeroAddress(_multiVault) {
        wethContract = IWETH(_weth);
        multiVault = _multiVault;
    }


    modifier onlyWithdrawRequestOwner(uint _withdrawRequestId) {
        require(pendingWithdrawals[msg.sender][_withdrawRequestId], "Withdraw id not exists or sender not an owner");
        _;
    }
    modifier onlyMultiVault() {
        require(msg.sender == multiVault, "Only multivault");
        _;
    }

    function setPendingWithdrawalBounty(
        uint256 _id,
        uint256 _bounty
    ) external onlyWithdrawRequestOwner(_id) {
        IMultiVaultFacetPendingWithdrawals(multiVault).setPendingWithdrawalBounty(_id, _bounty);
    }

    function cancelPendingWithdrawal(
        uint256 _id,
        uint256 _amount,
        IEverscale.EverscaleAddress memory _recipient,
        uint _expected_evers,
        bytes memory _payload,
        uint _bounty
    ) external payable onlyWithdrawRequestOwner(_id) {
        IMultiVaultFacetPendingWithdrawals(multiVault).cancelPendingWithdrawal(
            _id,
            _amount,
            _recipient,
            _expected_evers,
            _payload,
            _bounty
        );
    }

    function onAlienWithdrawalPendingCreated(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory _payload,
        uint _pendingWithdrawalId
    ) external override onlyMultiVault {
        address nativeTokenReceiver = abi.decode(_payload.callback.payload, (address));
        pendingWithdrawals[nativeTokenReceiver][_pendingWithdrawalId] = true;
    }

    function onAlienWithdrawal(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory _payload,
        uint256 withdrawAmount
    ) external override onlyMultiVault {
        address payable nativeTokenReceiver = abi.decode(_payload.callback.payload, (address));
        wethContract.withdraw(withdrawAmount);

        (bool sent, ) = nativeTokenReceiver.call{value: withdrawAmount}("");

        require(sent);
    }

    function drain(
        address recipient,
        address token,
        uint256 amount
    ) external {
        address governance = IMultiVaultFacetSettings(multiVault).governance();

        require(msg.sender == governance);

        uint256 amount_;

        if (amount == 0) {
            amount_ = IERC20(token).balanceOf(address(this));
        } else {
            amount_ = amount;
        }

        IERC20(token).safeTransfer(recipient, amount_);
    } 
}
