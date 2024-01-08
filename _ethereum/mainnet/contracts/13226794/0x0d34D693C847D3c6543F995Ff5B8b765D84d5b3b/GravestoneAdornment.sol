// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./AccessControl.sol";
import "./IGravestoneAdornment.sol";

contract GravestoneAdornment is AccessControl, IGravestoneAdornment {
    bytes32 public constant CREATOR_ROLE = keccak256("C");

    bytes32[4][] private _type0Adornments; // 32x32px, 1-bit pixels
    bytes32[16][] private _type1Adornments; // 64x64px, 1-bit pixels
    bytes32[32][] private _type2Adornments; // 32x32px, 8-bit pixels
    bytes32[128][] private _type3Adornments; // 64x64px, 8-bit pixels

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CREATOR_ROLE, msg.sender);

        _type0Adornments.push(); // Start type 0 index at 1
    }

    function create(bytes32[] calldata gravestoneAdornment_)
        external
        override
        returns (uint256)
    {
        require(hasRole(CREATOR_ROLE, msg.sender), "auth");
        require(
            gravestoneAdornment_.length == 4 ||
                gravestoneAdornment_.length == 16 ||
                gravestoneAdornment_.length == 32 ||
                gravestoneAdornment_.length == 128,
            "len"
        );

        uint8 adornmentType;
        uint256 adornmentIndex;
        if (gravestoneAdornment_.length == 4) {
            adornmentType = uint8(0);
            adornmentIndex = _type0Adornments.length;

            require(adornmentIndex <= (type(uint256).max >> 2), "overflow");

            bytes32[4] storage type0Adornment = _type0Adornments.push();
            for (uint256 i = 0; i < type0Adornment.length; i++) {
                type0Adornment[i] = gravestoneAdornment_[i];
            }
        } else if (gravestoneAdornment_.length == 16) {
            adornmentType = uint8(1);
            adornmentIndex = _type1Adornments.length;

            require(adornmentIndex <= (type(uint256).max >> 2), "overflow");

            bytes32[16] storage type1Adornment = _type1Adornments.push();
            for (uint256 i = 0; i < type1Adornment.length; i++) {
                type1Adornment[i] = gravestoneAdornment_[i];
            }
        } else if (gravestoneAdornment_.length == 32) {
            adornmentType = uint8(2);
            adornmentIndex = _type2Adornments.length;

            require(adornmentIndex <= (type(uint256).max >> 2), "overflow");

            bytes32[32] storage type2Adornment = _type2Adornments.push();
            for (uint256 i = 0; i < type2Adornment.length; i++) {
                type2Adornment[i] = gravestoneAdornment_[i];
            }
        } else {
            adornmentType = uint8(3);
            adornmentIndex = _type3Adornments.length;

            require(adornmentIndex <= (type(uint256).max >> 2), "overflow");

            bytes32[128] storage type3Adornment = _type3Adornments.push();
            for (uint256 i = 0; i < type3Adornment.length; i++) {
                type3Adornment[i] = gravestoneAdornment_[i];
            }
        }
        uint256 adornmentId = (uint256(adornmentType) << 254) | adornmentIndex;
        emit Create(msg.sender, adornmentId);
        return adornmentId;
    }

    function gravestoneAdornment(uint256 adornmentId_)
        external
        view
        override
        returns (bytes32[] memory)
    {
        (
            bool ok,
            uint8 adornmentType,
            uint256 adornmentIndex
        ) = _adornmentTypeIndex(adornmentId_);
        require(ok, "aId");

        bytes32[] memory result;
        if (adornmentType == uint8(0)) {
            result = new bytes32[](4);
            for (uint256 i = 0; i < result.length; i++) {
                result[i] = _type0Adornments[adornmentIndex][i];
            }
            return result;
        } else if (adornmentType == uint8(1)) {
            result = new bytes32[](16);
            for (uint256 i = 0; i < result.length; i++) {
                result[i] = _type1Adornments[adornmentIndex][i];
            }
            return result;
        } else if (adornmentType == uint8(2)) {
            result = new bytes32[](32);
            for (uint256 i = 0; i < result.length; i++) {
                result[i] = _type2Adornments[adornmentIndex][i];
            }
            return result;
        } else {
            result = new bytes32[](128);
            for (uint256 i = 0; i < result.length; i++) {
                result[i] = _type3Adornments[adornmentIndex][i];
            }
            return result;
        }
    }

    function valid(uint256 adornmentId_) external view override returns (bool) {
        (bool ok, , ) = _adornmentTypeIndex(adornmentId_);
        return ok;
    }

    function _adornmentTypeIndex(uint256 adornmentId_)
        private
        view
        returns (
            bool valid_,
            uint8 adornmentType_,
            uint256 adornmentIndex_
        )
    {
        uint8 adornmentType = _adornmentType(adornmentId_);
        uint256 adornmentIndex = _adornmentIndex(adornmentId_);
        if (adornmentType == uint8(0)) {
            return (
                adornmentIndex < _type0Adornments.length,
                adornmentType,
                adornmentIndex
            );
        }
        if (adornmentType == uint8(1)) {
            return (
                adornmentIndex < _type1Adornments.length,
                adornmentType,
                adornmentIndex
            );
        }
        if (adornmentType == uint8(2)) {
            return (
                adornmentIndex < _type2Adornments.length,
                adornmentType,
                adornmentIndex
            );
        }
        if (adornmentType == uint8(3)) {
            return (
                adornmentIndex < _type3Adornments.length,
                adornmentType,
                adornmentIndex
            );
        }
        return (false, uint8(0), 0);
    }

    function _adornmentType(uint256 adornmentId_) private pure returns (uint8) {
        return uint8(adornmentId_ >> 254);
    }

    function _adornmentIndex(uint256 adornmentId_)
        private
        pure
        returns (uint256)
    {
        return adornmentId_ & (type(uint256).max >> 2);
    }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId_ == type(IGravestoneAdornment).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
}
