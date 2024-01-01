// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./StakingBankStaticNotSupported.sol";

/// @dev Because we are using PoA in UMB oracle, staked balance does not matter. What's matter is, if signer is
/// validator or not. In this case  we can optimise `StakingBank` and make it static for better gas performance.
abstract contract StakingBankStatic is StakingBankStaticNotSupported {
    uint256 public constant ONE = 1e18;

    uint256 public immutable NUMBER_OF_VALIDATORS; // solhint-disable-line var-name-mixedcase
    uint256 public immutable TOTAL_SUPPLY; // solhint-disable-line var-name-mixedcase

    constructor(uint256 _validatorsCount) {
        NUMBER_OF_VALIDATORS = _validatorsCount;
        TOTAL_SUPPLY = _validatorsCount * ONE;

        _assertValidSetup(_validatorsCount);
    }

    function balances(address _validator) external view returns (uint256) {
        return _isValidator(_validator) ? ONE : 0;
    }

    function verifyValidators(address[] calldata _validators) external view returns (bool) {
        for (uint256 i; i < _validators.length;) {
            if (!_isValidator(_validators[i])) return false;
            unchecked { i++; }
        }

        return true;
    }

    function getNumberOfValidators() external view returns (uint256) {
        return NUMBER_OF_VALIDATORS;
    }

    function getAddresses() external view returns (address[] memory) {
        return _addresses();
    }

    function getBalances() external view returns (uint256[] memory allBalances) {
        allBalances = new uint256[](NUMBER_OF_VALIDATORS);

        for (uint256 i; i < NUMBER_OF_VALIDATORS;) {
            allBalances[i] = ONE;

            unchecked {
                // we will not have enough data to overflow
                i++;
            }
        }
    }

    function addresses(uint256 _ix) external view returns (address) {
        return _addresses()[_ix];
    }

    function validators(address _id) external view virtual returns (address id, string memory location);

    /// @dev to follow ERC20 interface
    function balanceOf(address _account) external view returns (uint256) {
        return _isValidator(_account) ? ONE : 0;
    }

    /// @dev to follow ERC20 interface
    function totalSupply() external view returns (uint256) {
        return TOTAL_SUPPLY;
    }

    /// @dev to follow Registrable interface
    function getName() external pure returns (bytes32) {
        return "StakingBank";
    }

    /// @dev to follow Registrable interface
    function register() external pure {
        // there are no requirements atm
    }

    /// @dev to follow Registrable interface
    function unregister() external pure {
        // there are no requirements atm
    }

    function _addresses() internal view virtual returns (address[] memory);

    function _isValidator(address _validator) internal view virtual returns (bool);

    function _assertValidSetup(uint256 _validatorsCount) internal view virtual{
        address[] memory list = _addresses();
        require(list.length == _validatorsCount);

        for (uint256 i; i < _validatorsCount;) {
            require(_isValidator(list[i]));

            unchecked { i ++; }
        }
    }
}
