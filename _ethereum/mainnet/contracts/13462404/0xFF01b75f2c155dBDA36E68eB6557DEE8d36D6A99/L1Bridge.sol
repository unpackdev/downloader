// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract L1Bridge is AccessControl {
    using SafeMath for uint256;

    // Original token on L1 network (Ethereum mainnet #1)
    IERC20 public l1Token;

    // L2 mintable + burnable token that acts as a twin of L1 token on L2
    IERC20 public l2Token;

    // total L1Token amount locked on the bridge
    uint256 public totalBridgedBalance;

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    event DepositInitiated(address indexed l1Token, address indexed _from, address indexed _to, uint256 _amount);
    event WithdrawalFinalized(address indexed l1Token, string indexed _l2Tx, address indexed _to, uint256 _amount);

    constructor(IERC20 _l1Token, IERC20 _l2Token) {
        require(address(_l1Token) != address(0), "ZERO_TOKEN");
        require(address(_l2Token) != address(0), "ZERO_TOKEN");
        l1Token = _l1Token;
        l2Token = _l2Token;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Initiates a deposit from L1 to L2; callable by any tokenholder.
     * The amount should be approved by the holder
     * @param _to L2 address of destination
     * @param _amount Token amount to bridge
     */
    function outboundTransfer(address _to, uint256 _amount) external {
        require(_amount > 0, "Cannot deposit 0 Tokens");
        totalBridgedBalance = totalBridgedBalance.add(_amount);
        require(l1Token.transferFrom(msg.sender, address(this), _amount), "TRANSFER_FROM_FAILED");
        emit DepositInitiated(address(l1Token), msg.sender, _to, _amount);
    }

    /**
     * @notice Finalizes withdrawal initiated on L2. callable only by ORACLE_ROLE
     * @param _to L1 address of destination
     * @param _amount Token amount being deposited
     * @param _l2Tx Tx hash of `L2Bridge.outboundTransfer` on L2 side
     */
    function finalizeInboundTransfer(
        address _to,
        string memory _l2Tx,
        uint256 _amount
    ) external onlyRole(ORACLE_ROLE) {
        require(_amount > 0, "NO_AMOUNT");
        require(_to != address(0), "NO_RECEIVER");
        require(totalBridgedBalance >= _amount, "NOT_ENOUGH_BALANCE");
        totalBridgedBalance = totalBridgedBalance.sub(_amount);
        require(l1Token.transfer(_to, _amount), "TRANSFER_FAILED");
        emit WithdrawalFinalized(address(l1Token), _l2Tx, _to, _amount);
    }
}
