// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IConverter.sol";

/**
 * @title Converter between certain assets pairs.
 */
contract Converter is IConverter, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event AccessUpdated(address indexed _account, bool _approved);

    address public constant RENCRV = address(0x49849C98ae39Fff122806C06791Fa73784FB3675);
    address public constant BADGER_RENCRV = address(0x6dEf55d2e18486B9dDfaA075bc4e4EE0B28c1545);
    address public constant SBTCCRV = address(0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3);
    address public constant BADGER_SBTCCRV = address(0xd04c48A53c111300aD41190D63681ed3dAd998eC);
    address public constant TBTCCRV = address(0x64eda51d3Ad40D56b9dFc5554E06F94e1Dd786Fd);
    address public constant BADGER_TBTCCRV = address(0xb9D076fDe463dbc9f915E5392F807315Bf940334);
    address public constant BADGER_HRENCRV = address(0xAf5A1DECfa95BAF63E0084a35c62592B774A2A87);

    // The address that is allowed to invoke the converter.
    mapping(address => bool) public approved;

    /**
     * @dev Initializes the converter contract.
     */
    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @dev Core function to handle asset conversion.
     */
    function convert(address _from, address _to, uint256 _fromAmount, uint256 _toAmount) external override {
        require(approved[msg.sender], "not approved");
        // Will update when more asset pairs are supported

        if (_from == RENCRV) {
            require(_to == BADGER_RENCRV || _to == BADGER_HRENCRV, "not supported");
        } else if (_from == SBTCCRV) {
            require(_to == BADGER_SBTCCRV, "not supported");
        } else if (_from == TBTCCRV) {
            require(_to == BADGER_TBTCCRV, "not supported");
        } else {
            revert("unsupported source token");
        }

        IERC20Upgradeable(_from).safeTransferFrom(msg.sender, address(this), _fromAmount);
        IERC20Upgradeable(_to).safeTransfer(msg.sender, _toAmount);
    }

    /**
     * @dev Updates the access of the account. Only owner can update access.
     */
    function updateAccess(address _account, bool _approved) external onlyOwner {
        approved[_account] = _approved;

        emit AccessUpdated(_account, _approved);
    }

    /**
     * @dev Withdraws asset from the converter. Only owner can withdraw.
     */
    function withdraw(address _token, uint256 _amount) external onlyOwner {
        IERC20Upgradeable(_token).safeTransfer(msg.sender, _amount);
    }
}