// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// Inheritance

import "./PausableUpgradeable.sol";
import "./Initializable.sol";

// Libraries
import "./Address.sol";
import "./SafeERC20Upgradeable.sol";

// References
import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";

/// @title Base contract for Rentable
/// @author Rentable Team <hello@rentable.world>
/// @custom:security Rentable Security Team <security@rentable.world>
/// @notice Implement simple security helpers for safe operations
contract BaseSecurityInitializable is Initializable, PausableUpgradeable {
    ///  Base security:
    ///  1. establish simple two-roles contract, _governance and _operator.
    ///  Operator can be changed only by _governance. Governance update needs acceptance.
    ///  2. can be paused by _operator or _governance via SCRAM()
    ///  3. only _governance can recover from pause via unpause
    ///  4. only _governance can withdraw in emergency
    ///  5. only _governance execute any tx in emergency

    /* ========== LIBRARIES ========== */
    using Address for address;

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== CONSTANTS ========== */
    address private constant ETHER = address(0);

    /* ========== STATE VARIABLES ========== */
    // current governance address
    address private _governance;
    // new governance address awaiting to be confirmed
    address private _pendingGovernance;
    // operator address
    address private _operator;

    /* ========== MODIFIERS ========== */

    /// @dev Prevents calling a function from anyone except governance
    modifier onlyGovernance() {
        require(msg.sender == _governance, "Only Governance");
        _;
    }

    /// @dev Prevents calling a function from anyone except governance or operator
    modifier onlyOperatorOrGovernance() {
        require(
            msg.sender == _operator || msg.sender == _governance,
            "Only Operator or Governance"
        );
        _;
    }

    /* ========== EVENTS ========== */

    /// @notice Emitted on operator change
    /// @param previousOperator previous operator address
    /// @param newOperator new operator address
    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    /// @notice Emitted on governance change proposal
    /// @param currentGovernance current governance address
    /// @param proposedGovernance new proposed governance address
    event GovernanceProposed(
        address indexed currentGovernance,
        address indexed proposedGovernance
    );

    /// @notice Emitted on governance change
    /// @param previousGovernance previous governance address
    /// @param newGovernance new governance address
    event GovernanceTransferred(
        address indexed previousGovernance,
        address indexed newGovernance
    );

    /* ========== CONSTRUCTOR ========== */

    /* ---------- INITIALIZER ---------- */

    /// @dev For internal usage in the child initializers
    /// @param governance address for governance role
    /// @param operator address for operator role
    // slither-disable-next-line naming-convention
    function __BaseSecurityInitializable_init(
        address governance,
        address operator
    ) internal onlyInitializing {
        __Pausable_init();

        require(governance != address(0), "Governance cannot be null");

        _governance = governance;
        _operator = operator;
    }

    /* ========== SETTERS ========== */

    /// @notice Propose new governance
    /// @param proposedGovernance governance address
    function setGovernance(address proposedGovernance) external onlyGovernance {
        // enable to cancel a proposal setting proposedGovernance to 0
        // slither-disable-next-line missing-zero-check
        _pendingGovernance = proposedGovernance;

        emit GovernanceProposed(_governance, proposedGovernance);
    }

    /// @notice Accept proposed governance
    function acceptGovernance() external {
        require(msg.sender == _pendingGovernance, "Only Proposed Governance");

        address previousGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0);

        emit GovernanceTransferred(previousGovernance, _governance);
    }

    /// @notice Set operator
    /// @param newOperator new operator address
    function setOperator(address newOperator) external onlyGovernance {
        address previousOperator = _operator;

        // governance can disable operator role
        // slither-disable-next-line missing-zero-check
        _operator = newOperator;

        emit OperatorTransferred(previousOperator, newOperator);
    }

    /* ========== VIEWS ========== */

    /// @notice Shows current governance
    /// @return governance address
    // slither-disable-next-line external-function
    function getGovernance() public view returns (address) {
        return _governance;
    }

    /// @notice Shows upcoming governance
    /// @return upcoming pending governance address
    // slither-disable-next-line external-function
    function getPendingGovernance() public view returns (address) {
        return _pendingGovernance;
    }

    /// @notice Shows current operator
    /// @return governance operator
    // slither-disable-next-line external-function
    function getOperator() public view returns (address) {
        return _operator;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Pause all operations
    // slither-disable-next-line naming-convention
    function SCRAM() external onlyOperatorOrGovernance {
        _pause();
    }

    /// @notice Returns to normal state
    function unpause() external onlyGovernance {
        _unpause();
    }

    /// @notice Withdraw asset ERC20 or ETH
    /// @param assetAddress Asset to be withdrawn
    function emergencyWithdrawERC20ETH(address assetAddress)
        external
        whenPaused
        onlyGovernance
    {
        uint256 assetBalance;
        if (assetAddress == ETHER) {
            address self = address(this);
            assetBalance = self.balance;
            payable(msg.sender).transfer(assetBalance);
        } else {
            assetBalance = IERC20Upgradeable(assetAddress).balanceOf(
                address(this)
            );
            IERC20Upgradeable(assetAddress).safeTransfer(
                msg.sender,
                assetBalance
            );
        }
    }

    /// @notice Batch withdraw asset ERC721
    /// @param assetAddress token address
    /// @param tokenIds array of token ids
    function emergencyBatchWithdrawERC721(
        address assetAddress,
        uint256[] calldata tokenIds,
        bool notSafe
    ) external whenPaused onlyGovernance {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (notSafe) {
                // slither-disable-next-line calls-loop
                IERC721Upgradeable(assetAddress).transferFrom(
                    address(this),
                    msg.sender,
                    tokenIds[i]
                );
            } else {
                // slither-disable-next-line calls-loop
                IERC721Upgradeable(assetAddress).safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenIds[i]
                );
            }
        }
    }

    /// @notice Batch withdraw asset ERC1155
    /// @param assetAddress token address
    /// @param tokenIds array of token ids
    function emergencyBatchWithdrawERC1155(
        address assetAddress,
        uint256[] calldata tokenIds
    ) external whenPaused onlyGovernance {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // slither-disable-next-line calls-loop
            uint256 assetBalance = IERC1155Upgradeable(assetAddress).balanceOf(
                address(this),
                tokenIds[i]
            );

            // slither-disable-next-line calls-loop
            IERC1155Upgradeable(assetAddress).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                assetBalance,
                ""
            );
        }
    }

    /// @notice Execute any tx in emergency
    /// @param to target
    /// @param value ether value
    /// @param data function+data
    /// @param isDelegateCall true will execute a delegate call, false a call
    function emergencyExecute(
        address to,
        uint256 value,
        bytes memory data,
        bool isDelegateCall
    )
        external
        payable
        whenPaused
        onlyGovernance
        returns (bytes memory returnData)
    {
        if (isDelegateCall) {
            returnData = to.functionDelegateCall(data, "");
        } else {
            returnData = to.functionCallWithValue(data, value, "");
        }
    }

    // Reserved storage space to allow for layout changes in the future.
    // slither-disable-next-line unused-state
    uint256[50] private _gap;
}
