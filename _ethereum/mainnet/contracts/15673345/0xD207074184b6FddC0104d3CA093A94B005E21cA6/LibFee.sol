// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./EnumerableSet.sol";

library LibFee {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 constant FEE_PRECISION = 100_000;
    bytes32 constant FEE_STORAGE_POSITION =
        keccak256("com.enterdao.landworks.fee");

    event SetTokenPayment(address indexed _token, bool _status);
    event SetFee(address indexed _token, uint256 _fee);

    struct FeeStorage {
        // Supported tokens as a form of payment
        EnumerableSet.AddressSet tokenPayments;
        // Protocol fee percentages for tokens
        mapping(address => uint256) feePercentages;
        // Assets' rent fees
        mapping(uint256 => mapping(address => uint256)) assetRentFees;
        // Protocol fees for tokens
        mapping(address => uint256) protocolFees;
    }

    function feeStorage() internal pure returns (FeeStorage storage fs) {
        bytes32 position = FEE_STORAGE_POSITION;

        assembly {
            fs.slot := position
        }
    }

    function clearAccumulatedRent(uint256 _assetId, address _token)
        internal
        returns (uint256)
    {
        LibFee.FeeStorage storage fs = feeStorage();

        uint256 amount = fs.assetRentFees[_assetId][_token];
        fs.assetRentFees[_assetId][_token] = 0;

        return amount;
    }

    function clearAccumulatedProtocolFee(address _token)
        internal
        returns (uint256)
    {
        LibFee.FeeStorage storage fs = feeStorage();

        uint256 amount = fs.protocolFees[_token];
        fs.protocolFees[_token] = 0;

        return amount;
    }

    function setFeePercentage(address _token, uint256 _feePercentage) internal {
        LibFee.FeeStorage storage fs = feeStorage();
        require(
            _feePercentage < FEE_PRECISION,
            "_feePercentage exceeds or equal to feePrecision"
        );
        fs.feePercentages[_token] = _feePercentage;

        emit SetFee(_token, _feePercentage);
    }

    function setTokenPayment(address _token, bool _status) internal {
        FeeStorage storage fs = feeStorage();
        if (_status) {
            require(fs.tokenPayments.add(_token), "_token already added");
        } else {
            require(fs.tokenPayments.remove(_token), "_token not found");
        }

        emit SetTokenPayment(_token, _status);
    }

    function supportsTokenPayment(address _token) internal view returns (bool) {
        return feeStorage().tokenPayments.contains(_token);
    }

    function totalTokenPayments() internal view returns (uint256) {
        return feeStorage().tokenPayments.length();
    }

    function tokenPaymentAt(uint256 _index) internal view returns (address) {
        return feeStorage().tokenPayments.at(_index);
    }

    function protocolFeeFor(address _token) internal view returns (uint256) {
        return feeStorage().protocolFees[_token];
    }

    function assetRentFeesFor(uint256 _assetId, address _token)
        internal
        view
        returns (uint256)
    {
        return feeStorage().assetRentFees[_assetId][_token];
    }

    function feePercentage(address _token) internal view returns (uint256) {
        return feeStorage().feePercentages[_token];
    }
}
