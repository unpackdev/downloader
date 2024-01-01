// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import {Ownable} from "Ownable.sol";
import {IStdReference} from "IStdReference.sol";
import {StdReferenceBase} from "StdReferenceBase.sol";

contract StdReferenceProxy is Ownable, StdReferenceBase {
    IStdReference public ref;

    constructor(IStdReference _ref, address _owner) {
        ref = _ref;
        _transferOwnership(_owner);
    }

    /// @notice Updates standard reference implementation. Only callable by the owner.
    /// @param _ref Address of the new standard reference contract
    function setRef(IStdReference _ref) public onlyOwner {
        ref = _ref;
    }

    /// @notice Returns the price data for the given base/quote pair. Revert if not available.
    /// @param base The base symbol of the token pair
    /// @param quote The quote symbol of the token pair
    function getReferenceData(string memory base, string memory quote) public view override returns (ReferenceData memory) {
        return ref.getReferenceData(base, quote);
    }
}
