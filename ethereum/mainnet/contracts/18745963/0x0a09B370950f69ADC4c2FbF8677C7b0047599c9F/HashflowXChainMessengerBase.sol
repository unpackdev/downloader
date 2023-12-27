/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.18;

import "./Ownable2Step.sol";
import "./Address.sol";

import "./IHashflowXChainMessenger.sol";

abstract contract HashflowXChainMessengerBase is
    IHashflowXChainMessenger,
    Ownable2Step
{
    using Address for address payable;

    uint16 public immutable hChainId;

    address public immutable router;

    mapping(uint16 => bytes) public xChainRemotes;

    constructor(uint16 _hChainId, address _router) {
        require(
            _hChainId != 0,
            'HashflowXChainMessengerBase::constructor Hashflow Chain ID cannot be 0.'
        );

        require(
            _router != address(0),
            'HashflowXChainMessengerBase::constructor Router cannot be 0 address.'
        );

        hChainId = _hChainId;
        router = _router;
    }

    /// @inheritdoc IHashflowXChainMessenger
    function updateXChainRemoteAddress(
        uint16 _hChainId,
        bytes calldata remoteAddress
    ) external override onlyOwner {
        xChainRemotes[_hChainId] = remoteAddress;

        emit UpdateXChainRemoteAddress(_hChainId, remoteAddress);
    }

    /// @inheritdoc IHashflowXChainMessenger
    function withdrawFunds() external onlyOwner {
        payable(_msgSender()).sendValue(address(this).balance);
    }

    function _generateTradePayload(
        XChainQuote memory quote,
        address caller,
        bytes32 permissionedRelayer,
        bytes32 dstContract,
        bytes memory dstContractCalldata
    ) internal pure returns (bytes memory) {
        XChainTradePayload memory pld;
        pld.dstChainId = quote.dstChainId;
        pld.txid = quote.txid;
        pld.srcPool = bytes32(uint256(uint160(quote.srcPool)));
        pld.dstPool = quote.dstPool;
        pld.dstExternalAccount = quote.dstExternalAccount;
        pld.quoteToken = quote.quoteToken;
        pld.dstTrader = quote.dstTrader;
        pld.quoteTokenAmount = quote.quoteTokenAmount;
        pld.permissionedRelayer = permissionedRelayer;
        pld.srcCaller = bytes32(uint256(uint160(caller)));
        pld.dstContract = dstContract;
        pld.dstContractCalldata = dstContractCalldata;

        return abi.encode(pld);
    }
}
