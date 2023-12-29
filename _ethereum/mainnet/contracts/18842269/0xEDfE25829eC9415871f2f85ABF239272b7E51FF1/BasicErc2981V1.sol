// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Initializable.sol";
import "./IERC2981Upgradeable.sol";

import "./BasicErc2981StorageV1.sol";

abstract contract BasicErc2981V1 is Initializable, IERC2981Upgradeable {
    using BasicErc2981StorageV1 for BasicErc2981StorageV1.Layout;

    uint256 private constant _ROYALTIES_FEE_DENOMINATOR = 10000;

    error FractionBeMoreThat10000();

    function __BasicErc2981_init(address _receiver, uint256 _fraction) onlyInitializing internal {
        _setRoyalties(_receiver, _fraction);
    }

    function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice) public view virtual override returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * BasicErc2981StorageV1.layout()._royaltiesFraction) / _ROYALTIES_FEE_DENOMINATOR;

        return (BasicErc2981StorageV1.layout()._royaltiesReveiver, royaltyAmount);
    }

    function _setRoyalties(address _receiver, uint256 _fraction) internal virtual {
        if (_fraction > _ROYALTIES_FEE_DENOMINATOR) {
            revert FractionBeMoreThat10000();
        }

        BasicErc2981StorageV1.layout()._royaltiesReveiver = _receiver;
        BasicErc2981StorageV1.layout()._royaltiesFraction = _fraction;
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual returns (bool) {
        return _interfaceId == type(IERC2981Upgradeable).interfaceId || _interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    function setRoyalties(address _receiver, uint256 _fraction) public virtual;
}
