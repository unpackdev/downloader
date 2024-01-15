//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Interface for MSDController
 */
interface IMSDController {
    function mintMSD(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function isMSDController() external view returns (bool);

    function mintCaps(address _token, address _minter)
        external
        view
        returns (uint256);

    function _addMSD(
        address _token,
        address[] calldata _minters,
        uint256[] calldata _mintCaps
    ) external;
}
