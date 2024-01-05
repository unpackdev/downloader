// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IVestingPool {
   event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event MintVesting(
        uint8 indexed claimType,
        address indexed minter,
        uint256 indexed tokenId,
        uint64 term,
        uint64[] maturities,
        uint32[] percentages,
        uint256 vestingAmount,
        uint256 principal
    );
    event ClaimVesting(
        address indexed payee,
        uint256 indexed tokenId,
        uint256 claimAmount
    );
    event TransferVesting(
        address from,
        uint256 tokenId,
        address to,
        uint256 targetTokenId,
        uint256 transferVestingAmount,
        uint256 transferPrincipal
    );
    event SplitVesting(
        address owner,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 splitVestingAmount,
        uint256 splitPricipal
    );
    event MergeVesting(
        address owner,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 mergeVestingAmount,
        uint256 mergePrincipal
    );

    function isVestingPool() external pure returns (bool);

    function mint(
        uint8 claimType_,
        address minter_,
        uint256 tokenId_,
        uint64 term_,
        uint256 amount_,
        uint64[] calldata maturities_,
        uint32[] calldata percentages_,
        string memory originalInvestor_
    ) external returns (uint256 mintUnits);

    function claim(address payable payee, uint256 tokenId,
        uint256 amount) external returns(uint256 claimUnit);

    function claimableAmount(uint256 tokenId_)
        external
        view
        returns (uint256);

    function transferVesting(
        address from_,
        uint256 tokenId_,
        address to_,
        uint256 targetTokenId_,
        uint256 transferUnits_
    ) external;

    function splitVesting(address owner_, uint256 tokenId_, uint256 newTokenId_,
        uint256 splitUnits_) external;

    function mergeVesting(address owner_, uint256 tokenId_,
        uint256 targetTokenId_) external;

    function units2amount(uint256 units_) external view returns (uint256);
    function amount2units(uint256 units_) external view returns (uint256);
    function totalAmount() external view returns(uint256);

    function getVestingSnapshot(uint256 tokenId_)
    external
    view
    returns (
        uint8 claimType_,
        uint64 term_,
        uint256 vestingAmount_,
        uint256 principal_,
        uint64[] memory maturities_,
        uint32[] memory percentages_,
        uint256 availableWithdrawAmount_,
        string memory originalInvestor_,
        bool isValid_
    );

    function underlying() external view returns (address) ;
}
