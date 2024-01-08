// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract TokiumBribe is AccessControl {
    using SafeERC20 for IERC20;

    uint256 public fee;

    address public feeAddress;

    address public distributor;

    mapping(address => uint256) public proposalDeadlines;

    uint256 internal constant maxFee = 1e4;

    bytes32 internal constant TEAM_ROLE = keccak256("TEAM_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TEAM_ROLE, msg.sender);
        uint256 _fee = 0.04e4;
        fee = _fee;
        feeAddress = msg.sender;
        emit NewFee(0, _fee);
        emit NewFeeAddress(address(0), msg.sender);
    }

    function depositBribe(
        address proposal,
        address token,
        uint256 amount
    ) external {
        require(proposalDeadlines[proposal] >= block.timestamp, "TokiumBribe: Invalid proposal");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit NewBribe(proposal, token, msg.sender, amount);
    }

    function updateProposals(address[] calldata proposals, uint256[] calldata deadlines) external onlyRole(TEAM_ROLE) {
        for (uint256 i = 0; i < proposals.length; i++) {
            proposalDeadlines[proposals[i]] = deadlines[i];
            emit NewProposal(proposals[i], deadlines[i]);
        }
    }

    function transferBribesToDistributor(address[] calldata tokens) external onlyRole(TEAM_ROLE) {
        require(distributor != address(0), "TokiumBribe: Invalid distributor");
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balance = IERC20(tokens[i]).balanceOf(address(this));
            uint256 feeAmount = (balance * fee) / maxFee;
            IERC20(tokens[i]).safeTransfer(distributor, balance - feeAmount);
            IERC20(tokens[i]).safeTransfer(feeAddress, feeAmount);
        }
    }

    function setFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFee < maxFee, "TokiumBribe: Invalid fee");
        uint256 oldFee = fee;
        fee = newFee;
        emit NewFee(oldFee, newFee);
    }

    function setFeeAddress(address _feeAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldFeeAddress = feeAddress;
        feeAddress = _feeAddress;
        emit NewFeeAddress(oldFeeAddress, _feeAddress);
    }

    function setDistributor(address _distributor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldDistributor = distributor;
        distributor = _distributor;
        emit NewDistributor(oldDistributor, _distributor);
    }

    event NewBribe(address indexed proposal, address indexed token, address indexed user, uint256 amount);
    event NewProposal(address indexed proposal, uint256 deadline);
    event NewFee(uint256 oldFee, uint256 newFee);
    event NewFeeAddress(address oldFeeAddress, address newFeeAddress);
    event NewDistributor(address oldDistributor, address newDistributor);
}
