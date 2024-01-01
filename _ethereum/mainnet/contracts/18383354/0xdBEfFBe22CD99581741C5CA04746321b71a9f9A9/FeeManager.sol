// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";

abstract contract FeeManager is Initializable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private _treasury;
    address private _token;
    uint256 private _fee;

    event FeePaid(address indexed from, uint256 amount);
    event FeeRefunded(address indexed from, uint256 amount);
    event FeeReleased(uint256 amount);
    event FeeUpdated(address indexed from, address token, uint256 fee);
    event TreasuryUpdated(address indexed from, address treasury);

    modifier chargeFee() {
        if (_fee != 0) {
            IERC20Upgradeable(_token).transferFrom(msg.sender, address(this), _fee);
            emit FeePaid(msg.sender, _fee);
        }
        _;
    }

    modifier releaseFee() {
        if (_fee != 0 && _treasury != address(0)) {
            IERC20Upgradeable(_token).transfer( _treasury, _fee);
            emit FeeReleased(_fee);
        }
        _;
    }

    function __FeeManager_init() internal onlyInitializing {}


    function refundFee(address party) internal {
        if (_fee != 0) {
            IERC20Upgradeable(_token).transfer(party, _fee / 4 * 3);
            if (_treasury != address(0)) {
                IERC20Upgradeable(_token).transfer(_treasury, _fee - (_fee / 4 * 3));
                emit FeeReleased(_fee - (_fee / 4 * 3));
            }
            emit FeeRefunded(msg.sender, _fee / 4 * 3);
        }
    }

    function feeToken() external view returns (address) {
        return _token;
    }

    function userFee() external view returns (uint256) {
        return _fee;
    }

    function feeTreasury() external view returns (address) {
        return _treasury;
    }

    function _setFee(uint256 fee) internal {
        _fee = fee;
        emit FeeUpdated(msg.sender, _treasury, fee);
    }

    function _setFeeToken(address token) internal {
        _token = token;
        emit FeeUpdated(msg.sender, token, _fee);
    }

    function _setFeeTreasury(address treasury) internal {
        _treasury = treasury;
        emit TreasuryUpdated(msg.sender, treasury);
    }

    /**
      * @notice Approve the fee token to be spent by this contract. This is an override added because companies like
      * Circle use extremely outdated contracts that do not check for the match of from == msg.sender in transferFrom
      * calls
     */
    function _setFeeTokenSelfApproval() internal {
        IERC20Upgradeable(_token).approve(address(this), type(uint256).max);
    }

    uint256[47] private __gap;
}
