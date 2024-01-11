// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
import "./LibPart.sol";

abstract contract AbstractRoyalties {
    mapping(uint256 => LibPart.Part) public royalties;

    function _saveRoyalties(uint256 _id, LibPart.Part memory _royalties)
        internal
    {
        require(
            _royalties.account != address(0x0),
            "Recipient should be present"
        );
        require(_royalties.value >= 0, "Royalty value should be positive");
        royalties[_id] = _royalties;
        _onRoyaltiesSet(_id, _royalties);
    }

    function _updateAccount(
        uint256 _id,
        address _from,
        address _to
    ) internal {
        if (royalties[_id].account == _from) {
            royalties[_id].account = payable(address(uint160(_to)));
        }
    }

    function _onRoyaltiesSet(uint256 _id, LibPart.Part memory _royalties)
        internal
        virtual;
}
