// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC20Permit.sol";

/**
 * @title PolkaRare Token
 * @dev PolkaRare ERC20 Token
 */
contract PolkaRareToken is ERC20Permit, Ownable {
    uint256 public constant MAX_CAP = 100 * (10**6) * (10**18); // 100 million

    address public governance;

    event RecoverToken(address indexed token, address indexed destination, uint256 indexed amount);

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    constructor() ERC20("PolkaRareToken", "PRARE") {
        governance = msg.sender;
        _mint(governance, MAX_CAP);
    }

    /**
     * @notice Function to set governance contract
     * Owner is assumed to be governance
     * @param _governance Address of governance contract
     */
    function setGovernance(address _governance) public onlyGovernance {
        governance = _governance;
    }

    /**
     * @notice Function to recover funds
     * Owner is assumed to be governance or PolkaRare trusted party for helping users
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
        require(IERC20(token).transfer(destination, amount), "Retrieve failed");
        emit RecoverToken(token, destination, amount);
    }
}
