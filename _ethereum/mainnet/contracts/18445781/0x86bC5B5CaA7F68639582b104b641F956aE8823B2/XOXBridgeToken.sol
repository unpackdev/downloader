//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./CountersUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract XOXBridgeToken is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev Return XOX address.
    IERC20Upgradeable public xox;
    mapping(address => bool) private operators;
    mapping(uint256 => mapping(bytes32 => bool)) public checkIsWithdrawn;

    function initialize(
        address _xox,
        address _timeLockSystem,
        address _timelockAdmin
    ) public initializer {
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        _transferOwnership(_timelockAdmin);
        xox = IERC20Upgradeable(_xox);
        operators[_timeLockSystem] = true;
    }

    event Deposited(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 chainIdDest
    );
    event Withdrawn(
        bytes32 indexed txHash,
        address indexed to,
        uint256 amount,
        uint256 chainIdSource
    );

    modifier onlyOperator() {
        require(operators[msg.sender], "XOXBridge: only operator");
        _;
    }

    // @notice This function gets the current chain ID.
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function deposit(
        address receiver,
        uint256 amount,
        uint256 chainId
    ) public whenNotPaused {
        require(getChainID() != chainId, "XOXBridgeToken: wrong chainID");
        xox.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, receiver, amount, chainId);
    }

    function withdraw(
        bytes32 txHash,
        address to,
        uint256 amount,
        uint256 chainId
    ) public whenNotPaused onlyOperator {
        require(!checkIsWithdrawn[chainId][txHash], "XOX: Processed before");
        xox.safeTransfer(to, amount);
        checkIsWithdrawn[chainId][txHash] = true;
        emit Withdrawn(txHash, to, amount, chainId);
    }

    /**
     * Admin functions
     */
    function setOperator(
        address[] calldata beneficiaries,
        bool[] calldata isOperator
    ) external onlyOwner {
        require(
            beneficiaries.length == isOperator.length,
            "XOXBridge: invalid params length"
        );

        for (uint256 i; i < beneficiaries.length; i++) {
            operators[beneficiaries[i]] = isOperator[i];
        }
    }

    function setPause() external onlyOwner {
        _pause();
    }

    function setUnPause() external onlyOwner {
        _unpause();
    }

    function emergencyWithdraw(
        address to,
        uint256 amount
    ) external whenPaused onlyOwner {
        xox.safeTransfer(to, amount);
    }
}
