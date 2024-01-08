// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Clones.sol";
import "./IWrappedInvoice.sol";
import "./IWrappedInvoiceFactory.sol";
import "./ISmartInvoiceFactory.sol";

contract WrappedInvoiceFactory is IWrappedInvoiceFactory {
    uint256 public invoiceCount = 0;
    mapping(uint256 => address) internal _invoices;

    event LogNewWrappedInvoice(uint256 indexed index, address wrappedInvoice);

    address public immutable implementation;
    ISmartInvoiceFactory public immutable smartInvoiceFactory;

    constructor(address _implementation, address _smartInvoiceFactory) {
        require(_implementation != address(0), "invalid implementation");
        require(
            _smartInvoiceFactory != address(0),
            "invalid smartInvoiceFactory"
        );
        implementation = _implementation;
        smartInvoiceFactory = ISmartInvoiceFactory(_smartInvoiceFactory);
    }

    function _createSmartInvoice(SmartInvoiceInfo memory _info)
        internal
        returns (address)
    {
        return
            smartInvoiceFactory.create(
                _info.client,
                _info.provider,
                _info.resolverType,
                _info.resolver,
                _info.token,
                _info.amounts,
                _info.terminationTime,
                _info.details
            );
    }

    function _init(WrappedInvoiceInfo memory _info) internal {
        address smartInvoiceAddress =
            _createSmartInvoice(_info.smartInvoiceInfo);

        IWrappedInvoice(_info.invoiceAddress).init(
            _info.providers[0],
            _info.providers[1],
            smartInvoiceAddress,
            _info.splitFactor
        );

        uint256 invoiceId = invoiceCount;
        _invoices[invoiceId] = _info.invoiceAddress;
        invoiceCount = invoiceCount + 1;

        emit LogNewWrappedInvoice(invoiceId, _info.invoiceAddress);
    }

    function _newClone() internal returns (address) {
        return Clones.clone(implementation);
    }

    struct SmartInvoiceInfo {
        address client;
        address provider;
        uint8 resolverType;
        address resolver;
        address token;
        uint256[] amounts;
        uint256 terminationTime;
        bytes32 details;
    }

    struct WrappedInvoiceInfo {
        SmartInvoiceInfo smartInvoiceInfo;
        address invoiceAddress;
        address[] providers;
        uint256 splitFactor;
    }

    function create(
        address _client,
        address[] calldata _providers,
        uint256 _splitFactor,
        uint8 _resolverType,
        address _resolver,
        address _token,
        uint256[] calldata _amounts,
        uint256 _terminationTime,
        bytes32 _details
    ) external override returns (address) {
        require(_providers.length == 2, "invalid providers");

        address invoiceAddress = _newClone();

        SmartInvoiceInfo memory smartInvoiceInfo;

        {
            smartInvoiceInfo.client = _client;
            smartInvoiceInfo.provider = invoiceAddress;
            smartInvoiceInfo.resolverType = _resolverType;
            smartInvoiceInfo.resolver = _resolver;
            smartInvoiceInfo.token = _token;
            smartInvoiceInfo.amounts = _amounts;
            smartInvoiceInfo.terminationTime = _terminationTime;
            smartInvoiceInfo.details = _details;
        }

        WrappedInvoiceInfo memory wrappedInvoiceInfo;

        {
            wrappedInvoiceInfo.smartInvoiceInfo = smartInvoiceInfo;
            wrappedInvoiceInfo.invoiceAddress = invoiceAddress;
            wrappedInvoiceInfo.providers = _providers;
            wrappedInvoiceInfo.splitFactor = _splitFactor;
        }

        _init(wrappedInvoiceInfo);

        return invoiceAddress;
    }

    function getInvoiceAddress(uint256 _index) public view returns (address) {
        return _invoices[_index];
    }
}
