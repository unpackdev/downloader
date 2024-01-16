// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

import "./Token.sol";
import "./SignUtil.sol";
import "./SafeMath.sol";

/**
 * Crowdfunding contracts are used to raise funds, raise funds, etc.
 * Such as charitable relief, public welfare projects and other scenarios.
 */
contract VivCrowfundingClonable is Token {
    using SafeMath for uint256;

    address payable internal _platform;
    address payable internal _owner;
    uint256 internal _feeRate;
    address internal _token;
    mapping(bytes => bool) internal _couponIds;
    mapping(bytes => bool) internal _tids;

    receive() external payable {
        // emit Transfer(msg.sender, address(this), msg.value);
    }

    function getCrowfunding()
        external
        view
        returns (
            address,
            address,
            uint256,
            address,
            uint256
        )
    {
        return (_platform, _owner, _feeRate, _token, _balanceOf(_token));
    }

    /**
     * init
     * @param owner owner
     * @param platform platform
     * @param feeRate feeRate
     * @param token token
     */
    function init(
        address owner,
        address platform,
        uint256 feeRate,
        address token
    ) external {
        require(owner != address(0), "VIV5703");
        require(platform != address(0), "VIV5704");
        require(_owner == address(0), "VIV5702");
        _owner = payable(owner);
        _platform = payable(platform);
        _feeRate = feeRate;
        _token = token;
    }

    /**
     * withdrawal
     * note: If the owner and platform sign any two parties, the owner can withdraw.
     * @param signedValue1 signed by one of seller, buyer, guarantor
     * @param signedValue2 signed by one of seller, buyer, guarantor
     * @param signedValue3 signed by platform
     * @param value        all amount, include which user can get, platform fee and arbitrate fee
     * @param couponRate   platform service fee rate
     * @param tid          trade id
     * @param couponId     coupon id
     */
    function withdraw(
        bytes memory signedValue1,
        bytes memory signedValue2,
        bytes memory signedValue3,
        uint256 value,
        uint256 couponRate,
        bytes memory tid,
        bytes memory couponId
    ) external {
        require(value > 0, "VIV0001");
        require(!_tids[tid], "VIV0060");
        require(msg.sender == _owner, "VIV5701");

        uint256 fee = value.rate(_feeRate);
        // Calculate the discounted price when couponRate more than 0
        if (couponRate > 0) {
            // Coupon cannot be reused
            require(!_couponIds[couponId], "VIV0006");
            // Check if _platform signed
            bytes32 h = ECDSA.toEthSignedMessageHash(abi.encode(couponRate, couponId, tid));
            require(SignUtil.checkSign(h, signedValue3, _platform), "VIV0007");
            // Use a coupon
            fee = fee.sub(fee.rate(couponRate));
            _couponIds[couponId] = true;
        }

        bytes32 hashValue = ECDSA.toEthSignedMessageHash(abi.encode(value, fee, tid));
        require(SignUtil.checkSign(hashValue, signedValue1, signedValue2, _owner, _platform), "VIV5006");

        require(_balanceOf(_token) >= value, "VIV5007");

        if (fee > 0) {
            _transfer(_token, _platform, fee);
        }

        _transfer(_token, _owner, value.sub(fee));
        _tids[tid] = true;
    }
}
