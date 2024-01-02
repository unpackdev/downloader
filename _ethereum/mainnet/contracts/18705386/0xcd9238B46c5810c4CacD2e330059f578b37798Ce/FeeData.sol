// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.21;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./Constants.sol";
import "./Errors.sol";
import "./MathUtils.sol";

abstract contract FeeData is Initializable, OwnableUpgradeable {

    event FeeNumeratorUpdate(uint256 feeNumerator);
    event FixedFeeUpdate(uint256 fixedFee);
    event ClearFeeTokens();
    event SetFeeToken(address feeToken);
    event MaxHopsUpdate(uint256 maxHops);
    event MaxSwapsUpdate(uint256 maxSwaps);

    uint256 private constant MAX_FEE_NUMERATOR = 200;
    uint256 private constant MAX_FIXED_FEE = 0.005 ether;

    uint256 internal _fixedFee;
    uint256 internal _feeNumerator;
    uint256 internal _feeDenominator;
    uint256 internal _maxHops;
    uint256 internal _maxSwaps;

    mapping(address => uint256) public feeTokenMap;
    address[] public feeTokenKeys;

    function initializeFeeData(uint256 fixedFee, address[] calldata feeTokenAddresses) public onlyInitializing {
        __Ownable_init();
        _fixedFee = fixedFee;
        _feeNumerator = 20;
        _feeDenominator = 10000;
        _maxHops = 10;
        _maxSwaps = 10;
        _initializeFeeTokens(feeTokenAddresses);
    }

    function setFeeNumerator(uint256 feeNumerator) external onlyOwner {
        if (feeNumerator > MAX_FEE_NUMERATOR) revert Errors.InvalidFeeNumerator();
        _feeNumerator = feeNumerator;
        emit FeeNumeratorUpdate(_feeNumerator);
    }

    function setMaxHops(uint256 maxHops) external onlyOwner {
        _maxHops = maxHops;
        emit MaxHopsUpdate(maxHops);
    }

    function setMaxSwaps(uint256 maxSwaps) external onlyOwner {
        _maxSwaps = maxSwaps;
        emit MaxSwapsUpdate(maxSwaps);
    }

    function setFixedFee(uint256 fixedFee) external onlyOwner {
        if (fixedFee > MAX_FIXED_FEE) revert Errors.InvalidFixedFee();
        _fixedFee = fixedFee;
        emit FixedFeeUpdate(_fixedFee);
    }

    function setFeeToken(address feeTokenAddress) public onlyOwner {
        _setFeeToken(feeTokenAddress);
        emit SetFeeToken(feeTokenAddress);
    }

    function setFeeTokens(address[] calldata feeTokenAddresses) public onlyOwner {
        setFeeToken(Constants.NATIVE_ADDRESS);
        uint256 length = feeTokenAddresses.length;
        for (uint256 i; i < length; ++i) {
            setFeeToken(feeTokenAddresses[i]);
        }
    }

    function clearFeeTokens() public onlyOwner {
        uint256 length = feeTokenKeys.length;
        for (uint256 i; i < length; ++i) {
            delete feeTokenMap[feeTokenKeys[i]];
        }
        while (feeTokenKeys.length != 0) {
            feeTokenKeys.pop();
        }
        emit ClearFeeTokens();
    }

    function _initializeFeeTokens(address[] calldata feeTokenAddresses) internal {
        _setFeeToken(Constants.NATIVE_ADDRESS);
        uint256 length = feeTokenAddresses.length;
        for (uint256 i; i < length; ++i) {
            _setFeeToken(feeTokenAddresses[i]);
        }
    }

    function _setFeeToken(address feeTokenAddress) internal {
        feeTokenMap[feeTokenAddress] = 1;
        feeTokenKeys.push(feeTokenAddress);
    }
}
