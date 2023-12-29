// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RegistryClient.sol";
import "./IEthlasFees.sol";
import "./OFTCore.sol";
import "./SafeERC20.sol";

/**
 * @dev Based on LayerZero OmnichainFungibleToken
 *
 * Use this contract only on the BASE CHAIN. It locks tokens on source,
 * on outgoing send(), and unlocks tokens when receiving from other chains.
 *
 */
contract ElsProxyBasedOFT is OFTCore, RegistryClient {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;
    address public ethlasWallet;
    string public ethlasFeesId;

    constructor(
        address _regAddr,
        address _ethlasWallet,
        string memory _ethlasFeesId,
        address _lzEndpoint,
        address _proxyToken
    ) OFTCore(_lzEndpoint) {
        setAddr(_regAddr);
        ethlasWallet = _ethlasWallet;
        ethlasFeesId = _ethlasFeesId;
        token = IERC20(_proxyToken);
    }

    function circulatingSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        unchecked {
            return token.totalSupply() - token.balanceOf(address(this));
        }
    }

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint256 _amount
    ) internal virtual override {
        require(_from == _msgSender(), "Owner is not send caller");
        token.safeTransferFrom(_from, address(this), _amount);
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint256 _amount
    ) internal virtual override {
        token.safeTransfer(_toAddress, _amount);
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) public payable virtual override {
        require(_refundAddress == ethlasWallet, "refund must be ethlas wallet");

        (uint256 nativeFee, ) = estimateSendFee(
            _dstChainId,
            _toAddress,
            _amount,
            false,
            _adapterParams
        );

        address eFeesAddr = lookupContractAddr(ethlasFeesId);
        require(eFeesAddr != address(0), "fees address not found");

        IEthlasFees eFees = IEthlasFees(eFeesAddr);

        uint256 ethlasFee = eFees.getFee(_dstChainId, _amount, nativeFee);
        uint256 pSlip = eFees.percentSlip();

        require(msg.value >= nativeFee, "Insufficient fee amount sent");
        uint256 eFeeShare = msg.value - nativeFee;

        if (eFeeShare < ethlasFee) {
            uint256 percentUnder = 100 - (100 * eFeeShare) / ethlasFee;
            require(percentUnder <= pSlip, "insufficlient ethlas fee amount");
        }

        super.sendFrom(
            _from,
            _dstChainId,
            _toAddress,
            _amount,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }
}
