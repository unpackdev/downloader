// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "./ModuleBase.sol";

/**
 * @title                   PrimeDeals Module Base Fee Extension
 * @notice                  Smart contract to extend the module
                            base with a fee mechanim
 */
contract ModuleBaseWithFee is ModuleBase {
    /// Wallet that is receiving the fees
    address public feeWallet;
    /// Fee in basis points (100% = 10000)
    uint32 public feeInBasisPoints;
    // Max fee 20%
    // solhint-disable-next-line var-name-mixedcase
    uint32 public immutable MAX_FEE = 2_000;

    // Percentage precision to calculate the fee
    // solhint-disable-next-line var-name-mixedcase
    uint256 public immutable BPS = 10_000;

    /**
     * @notice              Constructor
     * @param _dealManager  The address of Dealmanager implementation
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(address _dealManager) ModuleBase(_dealManager) {}

    /**
     * @notice              This event is emitted when the fee wallet address is updated
     * @param oldFeeWallet  Address of the old fee wallet
     * @param newFeeWallet  Address of the new fee wallet
     */
    event FeeWalletChanged(
        address indexed oldFeeWallet,
        address indexed newFeeWallet
    );

    /**
     * @notice              This event is emitted when the fee is updated
     * @param oldFee        Old fee amount in basis points (1% = 100)
     * @param newFee        New fee in basis points (1% = 100) that is updated
     */
    event FeeChanged(uint32 indexed oldFee, uint32 indexed newFee);

    /**
     * @notice              Sets a new fee wallet
     * @param _feeWallet    Address of the new fee wallet
     * @dev                 The fee system will be inactive if the feeWallet
                            is set to a zero-address
     */
    function setFeeWallet(address _feeWallet)
        external
        onlyDealManagerOwner(msg.sender)
    {
        require(
            _feeWallet != address(0) && _feeWallet != address(this),
            "ModuleBaseWithFee: Error 100"
        );
        if (feeWallet != _feeWallet) {
            feeWallet = _feeWallet;
            emit FeeWalletChanged(feeWallet, _feeWallet);
        }
    }

    /**
     * @notice                      Sets a new fee
     * @param _feeInBasisPoints     Fee amount in basis points (1% = 100)
     */
    function setFee(uint32 _feeInBasisPoints)
        external
        onlyDealManagerOwner(msg.sender)
    {
        require(_feeInBasisPoints <= MAX_FEE, "ModuleBaseWithFee: Error 264");
        if (feeInBasisPoints != _feeInBasisPoints) {
            feeInBasisPoints = _feeInBasisPoints;
            emit FeeChanged(feeInBasisPoints, _feeInBasisPoints);
        }
    }

    /**
     * @notice              Pays the fee in a token and returns the remainder
     * @param _token        Token in which the transfer happens
     * @param _amount       Amount of the transfer
     * @return uint256      Remaining amount after the fee payment
     */
    function _payFeeAndReturnRemainder(address _token, uint256 _amount)
        internal
        returns (uint256)
    {
        if (feeWallet != address(0) && feeInBasisPoints > 0) {
            uint256 fee = (_amount * feeInBasisPoints) / BPS;
            _transfer(_token, feeWallet, fee);

            return _amount - fee;
        }
        return _amount;
    }

    /**
     * @notice                  Transfers a token amount with automated fee payment
     * @param _token            Token in which the transfer happens
     * @param _to               Target of the transfer
     * @param _amount           Amount of the transfer
     * @return amountAfterFee   The amount minus the fee
     */
    function _transferWithFee(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256 amountAfterFee) {
        amountAfterFee = _payFeeAndReturnRemainder(_token, _amount);
        _transfer(_token, _to, amountAfterFee);
    }

    /**
     * @notice                  Transfers a token amount from someone with automated fee payment
     * @param _token            Token in which the transfer happens
     * @param _from             Source of the transfer
     * @param _to               Target of the transfer
     * @param _amount           Amount of the transfer
     * @return amountAfterFee   The amount minus the fee
     */
    function _transferFromWithFee(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256 amountAfterFee) {
        // if the transfer from does not touch this contract, we first
        // need to transfer it here, pay the fee, and then pass it on
        // if that is not the case, we can do the regular transferFrom
        if (_to != address(this)) {
            _transferFrom(_token, _from, address(this), _amount);
            amountAfterFee = _transferWithFee(_token, _to, _amount);
        } else {
            _transferFrom(_token, _from, _to, _amount);
            amountAfterFee = _payFeeAndReturnRemainder(_token, _amount);
        }
    }

    /**
     * @notice              Modifier that validates that the msg.sender
                            is the DealManager contract
     * @param _sender       Msg.sender of the function that is called
     */
    modifier onlyDealManagerOwner(address _sender) {
        require(_sender == dealManager.owner(), "ModuleBaseWithFee: Error 221");
        _;
    }
}
