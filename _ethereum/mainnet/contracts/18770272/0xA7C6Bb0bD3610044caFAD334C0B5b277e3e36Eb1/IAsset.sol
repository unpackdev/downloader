// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import "./Initializable.sol";
import "./Ownable.sol";
import "./IERC20.sol";

interface IAsset is IERC20 {
    function baseToken() external view returns (address);

    function master() external view returns (address);

    function maxSupply() external view returns (uint256);

    function virtualSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function baseTokenDecimals() external view returns (uint8);

    function setMaster(address master_) external;

    function addVirtualSupply(uint256 amount) external;

    function removeVirtualSupply(uint256 amount) external;

    function baseTokenBalance() external view returns (uint256);

    function transferBaseToken(address to, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;
}
