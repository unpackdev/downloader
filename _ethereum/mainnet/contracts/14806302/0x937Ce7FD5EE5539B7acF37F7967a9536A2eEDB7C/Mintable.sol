// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IMintable.sol";
import "./Bytes.sol";

abstract contract Mintable is Ownable, IMintable {
    address public imx;
    bool public allow;

    event AssetMinted(address to, uint256 id);

    constructor(address _owner, address _imx) {
        imx = _imx;
        allow = false;
        require(_owner != address(0), "Owner must not be empty");
        transferOwnership(_owner);
    }

    modifier onlyOwnerOrIMX() {
        require(msg.sender == imx || msg.sender == owner(), "Function can only be called by IMX or owner");
        _;
    }

    function setAllow(bool _allow) public onlyOwner {
        allow = _allow;
    }

    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external override onlyOwnerOrIMX {
        require(quantity == 1, "Mintable: invalid quantity");
        require(allow, "Not alllowed to bridge");
        // (uint256 id, bytes memory blueprint) = Minting.split(mintingBlob);
        uint256 id = Bytes.toUint(mintingBlob);
        _mintFor(user, id, '');
        emit AssetMinted(user, id);
    }

    function _mintFor(
        address to,
        uint256 id,
        bytes memory blueprint
    ) internal virtual;
}
