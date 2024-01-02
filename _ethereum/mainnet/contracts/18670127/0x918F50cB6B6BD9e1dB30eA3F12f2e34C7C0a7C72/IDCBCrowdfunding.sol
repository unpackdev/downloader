// SPDX-License-Identifier: MIT

//** DCB Crowdfunding Interface */
//** Author: Aceson & Aaron 2023.3 */

import "./IERC20.sol";

pragma solidity 0.8.19;

interface IDCBCrowdfunding {
    struct Params {
        uint8 minTier;
        uint16 nativeChainId;
        uint32 startDate;
        address investmentAddr;
        address tierMigratorAddr;
        address vestingAddr;
        address paymentToken;
        address saleTokenAddr;
        address layerZeroAddr;
        uint256 totalTokenOnSale;
        uint256 hardcap;
    }

    struct InvestorInfo {
        uint8 active;
        uint32 joinDate;
        address wallet;
        uint256 investAmount;
    }

    struct InvestorAllocation {
        uint8 tier;
        uint8 multi;
        uint256 shares;
        bool active;
    }

    /**
     *
     * @dev AgreementInfo will have information about agreement.
     * It will contains agreement details between innovator and investor.
     * For now, innovatorWallet will reflect owner of the platform.
     *
     */
    struct AgreementInfo {
        uint8 minTier;
        IERC20 token;
        uint32 createDate;
        uint32 startDate;
        uint32 endDate;
        uint256 totalTokenOnSale;
        uint256 hardcap;
        uint256 totalInvestFund;
        mapping(address => InvestorInfo) investorList;
    }

    /**
     *
     * @dev this event will call when new agreement generated.
     * this is called when innovator create a new agreement but for now,
     * it is calling when owner create new agreement
     *
     */
    event CreateAgreement(Params);

    /**
     *
     * @dev it is calling when new investor joinning to the existing agreement
     *
     */
    event NewInvestment(address wallet, uint256 amount);

    /**
     *
     * inherit functions will be used in contract
     *
     */

    function registerForAllocation(address _user, uint8 _tier, uint8 _multi) external returns (bool);

    function initialize(Params memory p) external;

    function setParams(Params calldata p) external;

    function setToken(address _token) external;

    function fundAgreement(uint256 _investFund) external returns (bool);

    function userInvestment(address _address) external view returns (uint256 investAmount, uint256 joinDate);

    function getInfo() external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    function getParticipants() external view returns (address[] memory);

    function getUserAllocation(address _address) external view returns (uint256);
}
