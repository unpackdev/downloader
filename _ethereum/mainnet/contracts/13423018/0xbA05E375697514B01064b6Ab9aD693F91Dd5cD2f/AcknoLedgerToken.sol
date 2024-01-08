// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC20Permit.sol";

/**
 * @title AcknoLedger Token
 * @dev AcknoLedger ERC20 Token
 */
contract AcknoLedgerToken is ERC20Permit {
    uint256 public constant MAX_CAP = 117718487 * (10**18); // 117,718,487 tokens

    address public governance;

    event RecoverToken(address indexed token, address indexed destination, uint256 indexed amount);
    event GovernanceChanged(address indexed previousGovernance, address indexed newGovernance);

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    constructor() ERC20("AcknoLedgerToken", "ACK") {
        governance = msg.sender;
        _mint(governance, MAX_CAP);
    }

    /**
     * @notice Function to set governance contract
     * Owner is assumed to be governance
     * @param _governance Address of governance contract
     */
    function setGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), "Invalid address");
        emit GovernanceChanged(msg.sender, _governance);
        governance = _governance;
    }

    /**
     * @notice Function to recover funds
     * Owner is assumed to be governance or AcknoLedger trusted party for helping users
     * @param token Address of token to be rescued
     * @param destination User address
     * @param amount Amount of tokens
     */
    function recoverToken(
        address token,
        address destination,
        uint256 amount
    ) external onlyGovernance {
        require(token != destination, "Invalid address");
        require(destination != address(0), "Invalid address");
        require(IERC20(token).transfer(destination, amount), "Retrieve failed");
        emit RecoverToken(token, destination, amount);
    }
}
