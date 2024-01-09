//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;
import "./IERC20MetadataUpgradeable.sol";

interface IMintableBurnableERC20 is IERC20MetadataUpgradeable {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}
