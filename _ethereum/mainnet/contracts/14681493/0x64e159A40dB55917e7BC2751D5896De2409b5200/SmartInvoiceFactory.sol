// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Clones.sol";
import "./ISmartInvoiceFactory.sol";
import "./ISmartInvoice.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./console.sol";

contract SmartInvoiceFactory is ISmartInvoiceFactory, Ownable {
    using SafeERC20 for IERC20;

    uint256 public invoiceCount = 0;
    mapping(uint256 => address) internal _invoices;
    mapping(address => uint256) public resolutionRates;

    enum RATES {
        ARB_RATE,
        DAO_RATE,
        NATIVE_CONVERSION_RATE,
        RESOLVER_TYPE
    }

    event LogNewInvoice(
        uint256 indexed index,
        address invoice,
        uint256[] amounts,
        uint256 conversionMulNative,
        uint256 daoRate
    );
    event UpdateResolutionRate(
        address indexed resolver,
        uint256 indexed resolutionRate,
        bytes32 details
    );

    event UpdateMinDaoRate(uint256 indexed minDaoRate);
    event UpdateConversionMulNative(uint256 indexed conversionMulNative);

    address public immutable implementation;
    address public immutable wrappedNativeToken;
    uint256 public conversionMulNative;
    uint256 public minDaoRate;

    constructor(
        address _implementation,
        address _wrappedNativeToken,
        uint256 _conversionMulNative,
        uint256 _minDaoRate
    ) {
        require(_implementation != address(0), "invalid implementation");
        require(
            _wrappedNativeToken != address(0),
            "invalid wrappedNativeToken"
        );
        implementation = _implementation;
        wrappedNativeToken = _wrappedNativeToken;
        conversionMulNative = _conversionMulNative;
        minDaoRate = _minDaoRate;
    }

    function calcDaoTokenAmount(
        uint256 daoRate,
        uint256 nativeConversionRate,
        uint256[] calldata _amounts
    ) internal pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            total = total + _amounts[i];
        }
        uint256 daoFee = (daoRate == 0) ? 0 : total / daoRate; // calculates dao fee )
        uint256 converted = daoFee * nativeConversionRate;

        return converted;
    }

    function _init(
        address _invoiceAddress,
        address _client,
        address _provider,
        address _dao,
        address _daoToken,
        address _resolver,
        address _token,
        uint256[] calldata _amounts,
        uint256 _terminationTime,
        uint256[4] calldata _rates,
        bytes32 _details
    ) internal {
        {
            uint256 resolutionRate = resolutionRates[_resolver];
            if (resolutionRate != 0) {
                require(
                    _rates[uint256(RATES.ARB_RATE)] == resolutionRate,
                    "Res rate must match set rate"
                );
            }
        }
        //LT as the rate is a divisor so smaller is
        require(
            _rates[uint256(RATES.DAO_RATE)] <= minDaoRate,
            "Must send at least min amount to DAO and must be positive and nonzero"
        );
        require(
            _rates[uint256(RATES.NATIVE_CONVERSION_RATE)] ==
                conversionMulNative,
            "Must send native conversion rate equal to factory"
        );

        ISmartInvoice(_invoiceAddress).init(
            _client,
            _provider,
            _dao,
            _daoToken,
            _resolver,
            _token,
            _amounts,
            _terminationTime,
            _rates,
            _details,
            wrappedNativeToken
        );

        uint256 converted = calcDaoTokenAmount(
            _rates[uint256(RATES.DAO_RATE)],
            _rates[uint256(RATES.NATIVE_CONVERSION_RATE)],
            _amounts
        );

        if (converted > 0) {
            require(
                IERC20(_daoToken).balanceOf(_dao) >= converted,
                "Insufficent funds in dao"
            );
            require(
                IERC20(_daoToken).allowance(_dao, address(this)) >= converted,
                "Insufficent allowance for spending dao tokens"
            );
            IERC20(_daoToken).safeTransferFrom(
                _dao,
                _invoiceAddress,
                converted
            );
        }

        uint256 invoiceId = invoiceCount;
        _invoices[invoiceId] = _invoiceAddress;
        invoiceCount = invoiceCount + 1;

        emit LogNewInvoice(
            invoiceId,
            _invoiceAddress,
            _amounts,
            _rates[uint256(RATES.NATIVE_CONVERSION_RATE)],
            _rates[uint256(RATES.DAO_RATE)]
        );
    }

    function create(
        address _client,
        address _provider,
        address _dao,
        address _daoToken,
        address _resolver,
        address _token,
        uint256[] calldata _amounts,
        uint256 _terminationTime,
        uint256[4] calldata _rates,
        bytes32 _details
    ) external override returns (address) {
        address invoiceAddress = Clones.clone(implementation);

        _init(
            invoiceAddress,
            _client,
            _provider,
            _dao,
            _daoToken,
            _resolver,
            _token,
            _amounts,
            _terminationTime,
            _rates,
            _details
        );

        return invoiceAddress;
    }

    function predictDeterministicAddress(bytes32 _salt)
        external
        view
        override
        returns (address)
    {
        return Clones.predictDeterministicAddress(implementation, _salt);
    }

    function createDeterministic(
        address _client,
        address _provider,
        address _dao,
        address _daoToken,
        address _resolver,
        address _token,
        uint256[] calldata _amounts,
        uint256 _terminationTime,
        uint256[4] calldata _rates,
        bytes32 _details,
        bytes32 _salt
    ) external override returns (address) {
        address invoiceAddress = Clones.cloneDeterministic(
            implementation,
            _salt
        );

        _init(
            invoiceAddress,
            _client,
            _provider,
            _dao,
            _daoToken,
            _resolver,
            _token,
            _amounts,
            _terminationTime,
            _rates,
            _details
        );

        return invoiceAddress;
    }

    function getInvoiceAddress(uint256 _index) public view returns (address) {
        return _invoices[_index];
    }

    function updateResolutionRate(uint256 _resolutionRate, bytes32 _details)
        external
    {
        resolutionRates[msg.sender] = _resolutionRate;
        emit UpdateResolutionRate(msg.sender, _resolutionRate, _details);
    }

    function updateNativeRate(uint256 _conversionMulNative) external onlyOwner {
        conversionMulNative = _conversionMulNative;
        emit UpdateConversionMulNative(_conversionMulNative);
    }

    function updateMinDaoRate(uint256 _minDaoRate) external onlyOwner {
        minDaoRate = _minDaoRate;
        emit UpdateMinDaoRate(_minDaoRate);
    }
}
