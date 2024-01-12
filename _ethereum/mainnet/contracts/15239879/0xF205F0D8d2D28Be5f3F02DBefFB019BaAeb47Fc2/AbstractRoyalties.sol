// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibPart.sol";

abstract contract AbstractRoyalties {
    LibPart.Part[] private _royalties;
    mapping(uint256 => LibPart.Part[]) public royalties;

    function _saveRoyalties(uint256 _id, LibPart.Part memory _royalty)
        internal
    {
        require(
            _royalty.account != address(0x0),
            "Recipient should be present"
        );
        require(_royalty.value != 0, "Royalty value should be positive");
        delete _royalties;
        _royalties.push(_royalty);
        royalties[_id] = _royalties;
        _onRoyaltiesSet(_id, _royalties);
    }

    function _updateAccount(
        uint256 _id,
        address _from,
        address _to
    ) internal {
        uint length = royalties[_id].length;
        for (uint i = 0; i < length; i++) {
            if (royalties[_id][i].account == _from) {
                royalties[_id][i].account = payable(address(uint160(_to)));
            }
        }
    }

    function _onRoyaltiesSet(uint256 _id, LibPart.Part[] memory _royalties)
        internal
        virtual;
}
