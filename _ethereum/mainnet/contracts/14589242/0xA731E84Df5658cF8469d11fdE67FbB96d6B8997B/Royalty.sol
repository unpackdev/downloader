//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC2981.sol";

abstract contract Royalty is Ownable, IERC2981 {
    uint256 private constant _BPS_BASE = 10000;
    uint256 private _bps;
    address private _recipient;

    function setRoyalty(address recipient, uint256 bps) public onlyOwner {
        require(_bps < _BPS_BASE, "Royalty: bps invalid");
        _recipient = recipient;
        _bps = bps;
    }

    // solhint-disable-next-line no-unused-vars
    function royaltyInfo(uint256 _tokenId, uint256 salePrice)
        public
        view
        override
        returns (address, uint256)
    {
        if (_recipient != address(0x0) && _bps != 0) {
            return (_recipient, (salePrice * _bps) / _BPS_BASE);
        } else {
            return (address(0x0), 0);
        }
    }
}
