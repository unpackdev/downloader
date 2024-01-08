// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RoyaltiesV2.sol";

contract SingleRoyaltiesV2Impl is RoyaltiesV2 {
    LibPart.Part internal royalty;

    function getRaribleV2Royalties(uint256 id)
        external
        view
        override
        returns (LibPart.Part[] memory)
    {
        return _getRoyalties();
    }

    function royaltyOwner() public view returns (address) {
        return royalty.account;
    }

    function _getRoyalties() internal view returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0] = royalty;
        return _royalties;
    }

    function _saveRoyalties(LibPart.Part[] memory _royalties) internal {
        require(royalty.account == address(0), "RoyaltiesV2Impl: ALREADY_SET");
        require(
            _royalties.length == 1,
            "RoyaltiesV2Impl: ONLY_ONE_MASTERWALLET_ALLOWED"
        );

        LibPart.Part memory _royalty = _royalties[0];
        require(
            _royalty.account != address(0x0),
            "Recipient should be present"
        );
        require(_royalty.value != 0, "Royalty value should be positive");
        require(
            _royalty.value < 10000,
            "Royalty total value should be < 10000"
        );

        royalty = _royalty;

        emit RoyaltiesSet(0, _royalties);
    }

    function _updateAccountRoyalties(address payable _to) internal {
        require(
            royalty.account != address(0),
            "RoyaltiesV2Impl: ROYALTIES_NOT_SET"
        );
        royalty.account = _to;
    }

    function _onRoyaltiesSet(uint256 id) internal {
        require(
            royalty.account != address(0),
            "RoyaltiesV2Impl: ROYALTIES_NOT_SET"
        );
        emit RoyaltiesSet(id, _getRoyalties());
    }
}
