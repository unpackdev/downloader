// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IInstaDapp.sol";
import "./IInstaMemory.sol";
import "./CInstaDapp.sol";
import "./FInstaDapp.sol";
import "./DSMath.sol";

contract ConnectGelatoDebtBridgeFee is ConnectorInterface {
    // solhint-disable const-name-snakecase
    string public constant override name = "ConnectGelatoDebtBridgeFee-v1.0";
    uint256 internal immutable _id;

    constructor(uint256 __id) {
        _id = __id;
    }

    /// @notice Function to compute Fee and borrow amount
    /// @dev payable to be compatible in conjunction with DSA.cast payable target
    /// @param _debt the amount of debt at the beginning
    /// @param _txFee  fast transaction fee of Gelato.
    /// @param _instaFeeFactor  instadapp fee.
    /// @param _getId  the amount storing Id in instaMemory.
    /// @param _setId  id to store total amount (e.g. debt or col to draw)
    /// @param _setIdInstaFee  id to store instaFee
    function calculateFee(
        uint256 _debt,
        uint256 _txFee,
        uint256 _instaFeeFactor,
        uint256 _getId,
        uint256 _setId,
        uint256 _setIdInstaFee
    ) external payable {
        _debt = _getUint(_getId, _debt);

        uint256 instaFee = wmul(_debt, _instaFeeFactor);

        _setUint(_setId, _debt + _txFee + instaFee); // Total amount to borrow.
        _setUint(_setIdInstaFee, instaFee);
    }

    /// @dev Connector Details
    function connectorID()
        external
        view
        override
        returns (uint256 _type, uint256 id)
    {
        (_type, id) = (1, _id);
    }
}
