// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ISupportable {
    event SupportTo(address indexed supporter, uint256 indexed to);
    event ChangeSupportingRoute(uint256 indexed from, uint256 indexed to);
    event ChangeSupportedPower(uint256 indexed id, int256 power);
    event TransferSupportingRewards(address indexed supporter, uint256 indexed id, uint256 amounts);

    function supportingRoute(uint256 id) external view returns (uint256);

    function supportingTo(address supporter) external view returns (uint256);

    function supportedPower(uint256 id) external view returns (uint256);

    function totalRewardsFromSupporters(uint256 id) external view returns (uint256);

    function setSupportingTo(
        address supporter,
        uint256 to,
        uint256 amounts
    ) external;

    function checkSupportingRoute(address supporter) external returns (address, uint256);

    function changeSupportedPower(address supporter, int256 power) external;

    function shareRewards(
        uint256 pending,
        address supporter,
        uint8 supportingRatio
    ) external returns (address nurseOwner, uint256 amountToNurseOwner);
}
