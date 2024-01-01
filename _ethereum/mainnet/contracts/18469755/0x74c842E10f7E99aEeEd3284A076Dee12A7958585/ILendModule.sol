// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./ILendFacet.sol";
interface ILendModule {
    event SubmitOrder(address indexed submitor, ILendFacet.LendInfo lendInfo);
    event LiquidateOrder(address indexed liquidator, ILendFacet.LendInfo lendInfo);
    event SubmitStakeOrder(address indexed submitor, ILendFacet.StakeInfo stakeInfo);
    event LiquidateStakeOrder(address indexed liquidator, ILendFacet.StakeInfo stakeInfo);

    event SetDomainHash(
        string name,
        string version,
        uint256 chainId,
        address verifyingContract,
        bytes32 domainHash
    );
    event SetLendFeePlatformRecipient(address _recipient);

    function setDomainHash(
        string memory _name,
        string memory _version
    ) external;

   function setLendFeePlatformRecipient(address _recipient) external;

    function submitOrder(
        ILendFacet.LendInfo memory _lendInfo,
        bytes calldata _debtorSignature,
        bytes calldata _loanerSignature
    ) external;

    function liquidateOrder(address _debtor,bool _type) external;

    function submitStakeOrder(ILendFacet.StakeInfo memory _stakeInfo,bytes calldata _lenderSignature,bytes calldata _borrowerSignature) external;
    function liquidateStakeOrder(address _borrower,bool _type) external;
}
