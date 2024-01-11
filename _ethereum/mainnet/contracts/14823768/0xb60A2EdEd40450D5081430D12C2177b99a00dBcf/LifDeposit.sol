// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "./ERC165.sol";
import "./ERC165Checker.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Initializable.sol";
import "./ILifDeposit.sol";

address constant LIF2 = 0x9C38688E5ACB9eD6049c8502650db5Ac8Ef96465;

interface OrgIdInterfaceLike {
    function getOrganization(bytes32 _orgId)
        external
        view
        returns (
            bool exists,
            bytes32 orgId,
            bytes32 orgJsonHash,
            string memory orgJsonUri,
            string memory orgJsonUriBackup1,
            string memory orgJsonUriBackup2,
            bytes32 parentOrgId,
            address owner,
            address director,
            bool isActive,
            bool isDirectorshipAccepted
        );
}

interface ClaimLike {
    function claim() external;
}

/**
 * @title LifDeposit contract
 * @dev A contract that manages deposits in Lif tokens
 */
contract LifDeposit is ILifDeposit, Ownable, Initializable, ERC165 {
    using SafeERC20 for IERC20;

    // Preserve storage gaps from older OpenZeppelin versions
    uint256[52] private ______gap;  // Initializable & Ownable

    /// @dev Withdrawal request structure
    struct WithdrawalRequest {
        uint256 value;
        uint256 withdrawTime;
    }

    /// @dev OrgId instance
    OrgIdInterfaceLike internal orgId;

    /// @dev Lif token instance
    IERC20 internal lif;

    /// @dev Delay in seconds between withdrawal request and withdrawal
    uint256 internal withdrawDelay;

    /// @dev Mapped list of deposits
    mapping (bytes32 => uint256) internal deposits;

    /// @dev Deposits withdrawal requests
    mapping (bytes32 => WithdrawalRequest) internal withdrawalRequests;

    /**
     * @dev Event emitted when Lif deposit has been added
     */
    event LifDepositAdded(
        bytes32 indexed organization,
        address indexed sender,
        uint256 value
    );

    /**
     * @dev Event emitted when withdrawDelay has been changed
     */
    event WithdrawDelayChanged(
        uint256 previousWithdrawDelay,
        uint256 newWithdrawDelay
    );

    /**
     * @dev Event emitted when withdrawal requested has been sent
     */
    event WithdrawalRequested(
        bytes32 indexed organization,
        address indexed sender,
        uint256 value,
        uint256 withdrawTime
    );

    /**
     * @dev Event emitted when deposit has been withdrawn
     */
    event DepositWithdrawn(
        bytes32 indexed organization,
        address indexed sender,
        uint256 value
    );

    /**
     * @dev Throws if called by any account other than the owner or entity director.
     */
    modifier onlyOrganizationOwnerOrDirector(bytes32 organization) {
        (
            bool exists,
            ,
            ,
            ,
            ,
            ,
            ,
            address organizationOwner,
            address organizationDirector,
            ,
            
        ) = orgId.getOrganization(organization);
        require(exists, "LifDeposit: Organization not found");
        require(
            organizationOwner == msg.sender || 
            organizationDirector == msg.sender, 
            "LifDeposit: action not authorized"
        );
        _;
    }

    /// @inheritdoc ILifDeposit
    function getLifTokenAddress() external view returns (address lifToken) {
        lifToken = address(lif);
    }

    /// @inheritdoc ILifDeposit
    function getWithdrawDelay() external view returns (uint256 delay) {
        delay = withdrawDelay;
    }

    /// @inheritdoc ILifDeposit
    function setWithdrawDelay(uint256 _withdrawDelay) external onlyOwner {
        emit WithdrawDelayChanged(withdrawDelay, _withdrawDelay);
        withdrawDelay = _withdrawDelay;
    }

    /// @inheritdoc ILifDeposit
    function addDeposit(
        bytes32 organization,
        uint256 value
    )
        external 
        onlyOrganizationOwnerOrDirector(organization)
    {
        require(value > 0, "LifDeposit: Invalid deposit value");
        lif.safeTransferFrom(msg.sender, address(this), value);
        deposits[organization] += value;
        emit LifDepositAdded(organization, msg.sender, value);
    }

    /// @inheritdoc ILifDeposit
    function submitWithdrawalRequest(
        bytes32 organization,
        uint256 value
    )
        external 
        onlyOrganizationOwnerOrDirector(organization)
    {
        require(value > 0, "LifDeposit: Invalid withdrawal value");
        require(
            value <= deposits[organization],
            "LifDeposit: Insufficient balance"
        );
        uint256 withdrawTime = block.timestamp + withdrawDelay;
        withdrawalRequests[organization] = WithdrawalRequest(value, withdrawTime);
        emit WithdrawalRequested(organization, msg.sender, value, withdrawTime);
    }

    /// @inheritdoc ILifDeposit
    function getWithdrawalRequest(bytes32 organization)
        external
        view 
        returns (
            bool exists,
            uint256 value,
            uint256 withdrawTime
        )
    {
        exists = 
            organization != bytes32(0) &&
            deposits[organization] > 0 &&
            withdrawalRequests[organization].value != 0;
        value = withdrawalRequests[organization].value;
        withdrawTime = withdrawalRequests[organization].withdrawTime;
    }

    /**
     * @dev Returns deposit value of the organization
     * @param organization The organization Id
     * @return balance Deposit value
     */
    function balanceOf(bytes32 organization)
        external
        view
        returns (uint256 balance)
    {
        balance = deposits[organization];
    }

    /// @inheritdoc ILifDeposit
    function withdrawDeposit(
        bytes32 organization
    )
        external 
        onlyOrganizationOwnerOrDirector(organization)
    {
        require(
            withdrawalRequests[organization].value != 0,
            "LifDeposit: Withdrawal request not found"
        );
        require(
            withdrawalRequests[organization].withdrawTime <= block.timestamp,
            "LifDeposit: Withdrawal request delay period not passed"
        );
        uint256 withdrawalValue = withdrawalRequests[organization].value;
        deposits[organization] -= withdrawalValue;
        delete withdrawalRequests[organization];
        lif.safeTransfer(msg.sender, withdrawalValue);
        emit DepositWithdrawn(organization, msg.sender, withdrawalValue);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public virtual override view returns (bool) {
        return (
            interfaceId == bytes4(0x7f5828d0) ||            // Ownable (EIP173) access control
            interfaceId == bytes4(0xe936be58) ||            // LifDeposit interface without LifToken setter
            super.supportsInterface(interfaceId));          // Otherwise check with super (IERC165)
    }

    /// @dev Upgrade function to ram owner to multi-sig.
    function upgrade() external {
        require(address(lif) != LIF2, "LifDeposit/token-already-set");

        uint256 oldBalance = lif.balanceOf(address(this));

        // claim LIF2
        lif.approve(address(LIF2), lif.balanceOf(address(this)));
        ClaimLike(address(LIF2)).claim();

        require(IERC20(LIF2).balanceOf(address(this)) == oldBalance, "LifDeposit/upgrade-fail");

        lif = IERC20(LIF2);
    }
}
