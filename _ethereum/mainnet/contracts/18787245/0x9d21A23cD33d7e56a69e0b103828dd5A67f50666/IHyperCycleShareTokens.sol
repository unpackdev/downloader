// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC1155.sol";

/// @notice Interface for the HyperCycleShareTokens.sol contract.
interface IHyperCycleShareTokens is IERC1155 {

    struct PendingDeposit {
        uint256 availableAtTimestamp;
        uint256 amount;
    }

    function increaseShareLimit(uint256 number) external;

    function createShareTokens(uint256 licenseNumber, uint256 chypcNumber, bool chypcTokenHeld, string memory startingMessage, uint256 maxRevenueDeposit) external;

    function transferShareOwnership(uint256 shareNumber, address to) external;


    function cancelShareTokens(uint256 shareNumber) external;

    function depositRevenue(uint256 shareNumber, uint256 amt) external;

    function claimRevenue(uint256 shareNumber) external;

    function withdrawEarnings(uint256 shareNumber) external;

    function setShareMessage(uint256 shareNumber, string memory message) external;

    function burnRevenueTokens(uint256 shareNumber, uint256 amount) external;
    
    function burnWealthTokens(uint256 shareNumber, uint256 amount) external;

    function getShareLicenseId(uint256 shareNumber) external view returns (uint256);
    function getShareCHyPCId(uint256 shareNumber) external view returns (uint256);
    function getShareOwner(uint256 shareNumber) external view returns (address);
    function getShareRevenueTokenId(uint256 shareNumber) external view returns (uint256);
    function getShareWealthTokenId(uint256 shareNumber) external view returns (uint256);
    function getShareTotalRevenue(uint256 shareNumber) external view returns (uint256);
    function getShareStartTime(uint256 shareNumber) external view returns (uint256);
    function getShareMessage(uint256 shareNumber) external view returns (string memory);
    function isShareActive(uint256 shareNumber) external view returns (bool);
    function shareCreated(uint256 shareNumber) external view returns (bool);
    function getRevenueTokenTotalSupply(uint256 shareNumber) external view returns (uint256);
    function getWealthTokenTotalSupply(uint256 shareNumber) external view returns (uint256);
    function getPendingDeposit(uint256 shareNumber, uint256 index) external view returns (PendingDeposit memory);
    function getPendingDepositsLength(uint256 shareNumber) external view returns (uint256);

}


