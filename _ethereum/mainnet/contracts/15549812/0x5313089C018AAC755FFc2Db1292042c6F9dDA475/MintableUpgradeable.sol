// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IMintable.sol";
import "./Minting.sol";
// import "./Ownable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";


// abstract contract Mintable is Ownable, IMintable {
abstract contract MintableUpgradeable is OwnableUpgradeable, IMintable {

    address public imx;
    mapping(uint256 => bytes) public blueprints;

    event AssetMinted(address to, uint256 id, bytes blueprint);


    //constructor(address _owner, address _imx) {
    function __Mintable_init(address _imx) internal onlyInitializing {
        __Ownable_init();
        imx = _imx;
    }

    modifier onlyOwnerOrIMX() {
        require(msg.sender == imx || msg.sender == owner(), "Function can only be called by owner or IMX");
        _;
    }

    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external override onlyOwnerOrIMX {
        require(quantity == 1, "Mintable: invalid quantity");
        (uint256 id, bytes memory blueprint) = Minting.split(mintingBlob);
        _mintFor(user, id, blueprint);
        blueprints[id] = blueprint;
        emit AssetMinted(user, id, blueprint);
    }

    function _mintFor(
        address to,
        uint256 id,
        bytes memory blueprint
    ) internal virtual;
}
