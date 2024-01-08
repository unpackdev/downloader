//SPDX-License-Identifier: MIT
/*
MIT License

Copyright (c) 2021 taijusanagi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity =0.7.6;

import "./ERC165.sol";

interface IHasSecondarySaleFees {
    function getFeeBps(uint256 id) external view returns (uint256[] memory);

    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
}

contract HasSecondarySaleFees is ERC165, IHasSecondarySaleFees {
    address payable[] private defaultRoyaltyAddressMemory;
    uint256[] private defaultRoyaltyMemory;

    function _setDefaultRoyalty(
        address payable[] memory _royaltyAddress,
        uint256[] memory _royalty
    ) internal {
        require(_royaltyAddress.length == _royalty.length, "input length must be same");
        defaultRoyaltyAddressMemory = _royaltyAddress;
        defaultRoyaltyMemory = _royalty;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165)
    returns (bool)
    {
        return interfaceId == type(IHasSecondarySaleFees).interfaceId || super.supportsInterface(interfaceId);
    }

    function getFeeRecipients(uint256) external view override returns (address payable[] memory) {
        return defaultRoyaltyAddressMemory;
    }

    function getFeeBps(uint256) external view override returns (uint256[] memory) {
        return defaultRoyaltyMemory;
    }
}
