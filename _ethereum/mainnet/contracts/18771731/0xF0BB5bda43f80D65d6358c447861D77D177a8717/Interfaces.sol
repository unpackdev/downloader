// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.22;

import "./IERC721AUpgradeable.sol";
import "./IERC721.sol";

interface IWoodFrame is IERC721AUpgradeable {
    function mint(address _address, uint256 _quantity) external;
}

interface ISilverFrame is IERC721 {
    function mint(address _address, uint256 _id) external;
}

interface IGoldFrame is IERC721 {
    function mint(address _address, uint256 _id, string memory base64Metadata) external;
}
