// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./NiftyEntity.sol";
import "./ERC2981.sol";
import "./Clones.sol";

contract ERC2981Factory is NiftyEntity {
    address public immutable tokenImplementation;

    event ERC2981Created(address newERC2981Address);

    constructor(address _niftyRegistryContract) NiftyEntity(_niftyRegistryContract) {
        tokenImplementation = address(new ERC2981(_niftyRegistryContract));
    }

    function createGlobalRoyaltyInfo(
        address _recipient,
        uint256 _value,
        address _tokenAddress
    ) public onlyValidSender returns (address) {
        address clone = Clones.clone(tokenImplementation);
        ERC2981(clone).initialize(_recipient, _value, _tokenAddress);
        emit ERC2981Created(clone);
        return clone;
    }

    function createTokenRoyaltyInfo(address _tokenAddress) public onlyValidSender returns (address) {
        address clone = Clones.clone(tokenImplementation);
        ERC2981(clone).initialize(address(0), 0, _tokenAddress);
        emit ERC2981Created(clone);
        return clone;
    }
}