// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./MarchandDeGlace.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./Address.sol";

// BE CAREFUL: DOT NOT CHANGE THE ORDER OF INHERITED CONTRACT
// solhint-disable-next-line max-states-count
contract MarchandDeGlaceMock is MarchandDeGlace {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Mock properties
    EnumerableSet.AddressSet private _whales;
    EnumerableSet.AddressSet private _dolphins;

    // !!!!!!!! ADD NEW PROPERTIES HERE !!!!!!

    // solhint-disable no-empty-blocks
    constructor(
        uint256 _totalGelCap,
        uint256 _poolOneGelCap,
        IERC20 _gel,
        address _signer
    ) MarchandDeGlace(_totalGelCap, _poolOneGelCap, _gel, _signer) {}

    // solhint-enable no-empty-blocks

    // solhint-disable-next-line function-max-lines
    function reset(
        uint256 _poolOneStartTime,
        uint256 _poolTwoStartTime,
        uint256 _poolOneEndTime,
        uint256 _poolTwoEndTime
    ) external onlyProxyAdmin {
        for (uint256 i = 0; i < _whales.length(); i++) {
            delete gelLockedByWhale[_whales.at(i)];
        }

        for (uint256 i = 0; i < _dolphins.length(); i++) {
            delete gelBoughtByDolphin[_dolphins.at(i)];
        }

        totalGelLocked = 0;

        require(
            GEL.allowance(SIGNER, address(this)) >
                TOTAL_GEL_CAP - GEL.balanceOf(address(this)),
            "Not enough allowed for resetting"
        );
        GEL.safeTransferFrom(
            SIGNER,
            address(this),
            TOTAL_GEL_CAP - GEL.balanceOf(address(this))
        );

        Address.sendValue(payable(SIGNER), address(this).balance);

        require(
            _poolOneStartTime <= _poolOneEndTime,
            "Pool One phase cannot end before the start"
        );
        require(
            _poolOneEndTime <= _poolTwoStartTime,
            "Pool One phase should be closed for starting pool two"
        );
        require(
            _poolTwoStartTime <= _poolTwoEndTime,
            "Pool Two phase cannot end before the start"
        );
        poolOneStartTime = _poolOneStartTime;
        poolTwoStartTime = _poolTwoStartTime;
        poolOneEndTime = _poolOneEndTime;
        poolTwoEndTime = _poolTwoEndTime;
    }
}
