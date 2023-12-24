// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Ownable.sol";

interface IHopRouter {
    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) external payable;
}

/// @title BridgeETHToBaseETH.
/// @author RedDuck Software.
/// @notice Serves as a `IHopRouter` wrapper.
/// @dev Inherits the OpenZeppelin `Ownable` implementation.
contract BridgeETHToBaseETH is Ownable {
    /// @notice Hop router address.
    IHopRouter public immutable hopRouter;
    /// @notice Current BeefyStaker address.
    address public beefyStaker;
    /// @notice Chain Id of L2 network.
    uint256 public constant CHAIND_ID = 8453;

    event Deposited(
        address indexed sender,
        address indexed recipient,
        uint256 indexed amount,
        uint256 amountOutMin
    );

    /// @notice Deploys the smart contract. Assigns the initial values: `_hopRouter` and `_beefyStaker` to the state.
    constructor(address _hopRouter, address _beefyStaker) {
        hopRouter = IHopRouter(_hopRouter);
        beefyStaker = _beefyStaker;
    }

    /// @notice Sets new BeefyStake address to `_beefyStaker`. Can be executed only by `owner`.
    /// @param _beefyStaker New BeefyStaker address to set.
    function setBeefyStaker(address _beefyStaker) external onlyOwner {
        beefyStaker = _beefyStaker;
    }

    /// @notice Transfers `msg.value` of ETH to `beefyStaker` on `CHAIN_ID` via `hopRouter`.
    receive() external payable {
        address recipient = beefyStaker;
        uint256 amount = msg.value;
        uint256 amountOutMin = (amount * 95) / 100;
        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp + 3600;

        hopRouter.sendToL2{value: amount}(
            CHAIND_ID,
            recipient,
            amount,
            amountOutMin,
            deadline,
            address(0),
            0
        );

        emit Deposited(msg.sender, recipient, amount, amountOutMin);
    }
}
