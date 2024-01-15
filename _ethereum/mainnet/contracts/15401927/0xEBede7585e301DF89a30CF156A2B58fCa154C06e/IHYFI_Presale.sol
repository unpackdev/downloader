// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.12;

interface IHYFI_Presale {
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function buyWithCurrency(uint256 amount, uint256 referralCode) external;

    function buyWithTokens(
        string memory token,
        bool buyWithHYFI,
        uint256 amount,
        uint256 referralCode
    ) external;

    function endTime() external view returns (uint256);

    function getAllBuyers() external view returns (address[] memory);

    function getBuyerData(address addr)
        external
        view
        returns (
            uint256,
            uint256,
            string[] memory
        );

    function getBuyerReservedAmount(address addr)
        external
        view
        returns (uint256);

    function getBuyerFromListById(uint256 id) external view returns (address);

    function getBuyerReferralData(address addr, uint256 referral)
        external
        view
        returns (uint256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getTotalAmountOfBuyers() external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function initialize(
        address _priceCalculatorContractAddress,
        address _referralsContractAddress,
        address _collectorWallet,
        uint256 _startTime,
        uint256 _endTime
    ) external;

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function setCollectorWalletAddress(address newAddress) external;

    function setNewPriceCalculatorImplementation(address newPriceCalculator)
        external;

    function setNewReferralImplementation(address newReferral) external;

    function setNewSaleTime(uint256 newStartTime, uint256 newEndTime) external;

    function setTotalUnitAmount(uint256 newAmount) external;

    function startTime() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function totalAmountSold() external view returns (uint256);

    function totalUnitAmount() external view returns (uint256);

    function withdrawCurrency(address recipient, uint256 amount) external;

    function withdrawERC20Tokens(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external returns (bool);
}
