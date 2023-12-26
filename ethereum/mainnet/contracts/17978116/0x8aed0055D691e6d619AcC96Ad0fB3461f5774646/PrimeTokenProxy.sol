// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./OFTCore.sol";
import "./SafeERC20.sol";

import "./IPrimeTokenProxy.sol";

contract PrimeTokenProxy is IPrimeTokenProxy, OFTCore {
    using SafeERC20 for IERC20;

    /// @notice Prime token contract address
    IERC20 public immutable prime;

    /// @notice Disabled state of the contract through invoke echelon
    bool public isDisabled;

    /// @notice Disabled state of send from
    bool public isSendFromDisabled = true;

    constructor(address _lzEndpoint, address _proxyToken) OFTCore(_lzEndpoint) {
        prime = IERC20(_proxyToken);
    }

    receive() external payable {}

    /**
     * @dev returns the address of the ERC20 token
     */
    function token() external view override returns (address) {
        return address(prime);
    }

    /**
     * @notice Returns the circulating supply of the token.
     */
    function circulatingSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        unchecked {
            return prime.totalSupply() - prime.balanceOf(address(this));
        }
    }

    /** @notice Set the isDisabled state
     *  @param _isDisabled new isDisabled state
     */
    function setIsDisabled(bool _isDisabled) external onlyOwner {
        isDisabled = _isDisabled;
        emit IsDisabledSet(_isDisabled);
    }

    /** @notice Set send from disabled state
     *  @param _isSendFromDisabled new dend from disabled state
     */
    function setIsSendFromDisabled(
        bool _isSendFromDisabled
    ) external onlyOwner {
        isSendFromDisabled = _isSendFromDisabled;
        emit IsSendFromDisabledSet(_isSendFromDisabled);
    }

    /**
     * @notice Identical function to `send` except users can bridge using prime invokeEchelon call.
     *         This way users do not have to approve PrimeTokenProxy to spend prime and bridge their tokens.
     *         prime will be sent to a primeDestinationAddress that has already approved PrimeTokenProxy and
     *         ethDestinationAddress will be the PrimeTokenProxy contract itself so that the nativeFees required for
     *         lzSend call have already been provided to the contract before the handleInvokeEchelon call.
     * @param _from The address of the original msg.sender
     * @param _ethDestinationAddress must be address of this contract
     * @param _primeDestinationAddress original msg.sender transferred _primeDestinationAddress, we will debitFrom this address on behalf
     *                                 of the user.
     * @param _primeValue The amount of prime that was sent from the prime token contract
     * @param _data remaining params required for layerZero send
     */
    function handleInvokeEchelon(
        address _from,
        address _ethDestinationAddress,
        address _primeDestinationAddress,
        uint256,
        uint256,
        uint256 _primeValue,
        bytes memory _data
    ) public payable {
        if (isDisabled) {
            revert ContractDisabled();
        }

        if (_msgSender() != address(prime)) {
            revert InvalidCaller();
        }

        // prime contract needs to set prime/ETH destinations as this address
        if (_ethDestinationAddress != address(this)) {
            revert InvalidEthDestination(_ethDestinationAddress);
        }
        if (_primeDestinationAddress != address(this)) {
            revert InvalidPrimeAddress(_primeDestinationAddress);
        }

        (
            uint16 dstChainId,
            uint256 amount,
            address refundAddress,
            address zroPaymentAddress,
            bytes memory adapterParams
        ) = abi.decode(_data, (uint16, uint256, address, address, bytes));

        if (_primeValue != amount) {
            revert InvalidPrimePayment();
        }

        _checkAdapterParams(dstChainId, PT_SEND, adapterParams, NO_EXTRA_GAS);

        bytes memory lzPayload = abi.encode(
            PT_SEND,
            abi.encodePacked(_from),
            amount
        );
        _lzSend(
            dstChainId,
            lzPayload,
            payable(refundAddress),
            zroPaymentAddress,
            adapterParams,
            address(this).balance
        );

        emit SendToChain(dstChainId, _from, abi.encodePacked(_from), amount);
    }

    /**
     * @notice Sends prime over to the other side
     * @param _from The address that will have its tokens burned when bridging
     * @param _dstChainId The destination chain identifier
     * @param _toAddress The address that will receive the tokens
     * @param _amount Amount of tokens to bridge
     * @param _refundAddress If the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
     * @param _zroPaymentAddress The address of the ZRO token holder who would pay for the transaction
     * @param _adapterParams parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
     */
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) public payable virtual override {
        if (isSendFromDisabled) {
            revert ContractDisabled();
        }

        _send(
            _from,
            _dstChainId,
            _toAddress,
            _amount,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    /**
     * @notice Sends prime over to the other side
     * @param _from The address that will have its tokens burned when bridging
     * @param _dstChainId The destination chain identifier
     * @param _amount Amount of tokens to bridge
     * @param _refundAddress If the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
     * @param _zroPaymentAddress The address of the ZRO token holder who would pay for the transaction
     * @param _adapterParams parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
     */
    function send(
        address _from,
        uint16 _dstChainId,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) public payable virtual {
        _send(
            _from,
            _dstChainId,
            abi.encodePacked(_from),
            _amount,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    /**
     * @notice Lock user's token
     * @dev User that's getting their token locked must also be the caller
     * @param _from The address that will have its tokens locked
     * @param _amount Amount of tokens to lock
     */
    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint256 _amount
    ) internal virtual override returns (uint256) {
        if (_from != _msgSender()) {
            revert InvalidCaller();
        }
        prime.safeTransferFrom(_msgSender(), address(this), _amount);
        return _amount;
    }

    /**
     * @notice Unlock tokens for user
     * @param _toAddress The address that will have tokens unlocked for
     * @param _amount Amount of tokens to unlock
     */
    function _creditTo(
        uint16,
        address _toAddress,
        uint256 _amount
    ) internal virtual override returns (uint256) {
        prime.safeTransfer(_toAddress, _amount);
        return _amount;
    }
}
