// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./AccessControl.sol";

contract MerkleRedeemer is AccessControl {
    mapping(uint256 => bytes32) public weeklyRoots;
    mapping(address => uint256) private hasClaimed;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    bytes32 public constant URGENT_ROLE = keccak256("URGENT_ROLE");

    uint256 public immutable deploymentWeek;

    IERC20 public immutable DAI;

    address public immutable beneficiary;

    event Claimed(address indexed user, uint256 indexed week, uint256 amount);

    constructor(
        IERC20 _DAI,
        address _admin,
        address _operator
    ) {
        deploymentWeek = block.timestamp / 1 weeks;
        DAI = _DAI;
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(OPERATOR_ROLE, _operator);
        _setupRole(URGENT_ROLE, _admin);
        _setupRole(URGENT_ROLE, _operator);
        _setupRole(URGENT_ROLE, msg.sender);
        beneficiary = _admin;
    }

    function getCurrentWeek() public view returns (uint256) {
        return block.timestamp / 1 weeks;
    }

    // remember to approve
    function addRoot(
        uint256 week,
        bytes32 root,
        uint256 totalWeekAmount
    ) external onlyRole(OPERATOR_ROLE) {
        require(week >= getCurrentWeek(), "redeemer/invalid-week");
        require(weeklyRoots[week] == bytes32(0), "redeemer/root-already-added");
        require(DAI.transferFrom(msg.sender, address(this), totalWeekAmount), "redeemer/transfer-from-failed");
        weeklyRoots[week] = root;
    }

    function getRoot(uint256 week) public view returns (bytes32) {
        bytes32 root = weeklyRoots[week];
        require(root != bytes32(0), "redeemer/no-root");
        return root;
    }

    function claimMultiple(
        uint256[] calldata _weeks,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external {
        require(_weeks.length > 0, "redeemer/cannot-claim-zero");
        require(_weeks.length == amounts.length && amounts.length == proofs.length, "redeemer/invalid-params");

        uint256 total;
        uint256 alreadyClaimed = hasClaimed[msg.sender];
        uint256 accumulatedClaimed = 0;
        for (uint256 i = 0; i < _weeks.length; i += 1) {
            require(canClaim(proofs[i], _weeks[i], amounts[i]), "redeemer/cannot-claim");

            uint256 thisWeekClaimed = 1 << (_weeks[i] - deploymentWeek);
            require((accumulatedClaimed & thisWeekClaimed) == 0);

            accumulatedClaimed = accumulatedClaimed | thisWeekClaimed;
            total += amounts[i];
            emit Claimed(msg.sender, _weeks[i], amounts[i]);
        }
        require((accumulatedClaimed & alreadyClaimed) == 0, "redeemer/already-claimed");
        hasClaimed[msg.sender] = alreadyClaimed | accumulatedClaimed;
        require(DAI.transfer(msg.sender, total), "redeemer/transfer-failed");
    }

    function canClaim(
        bytes32[] memory proof,
        uint256 week,
        uint256 amount
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        return MerkleProof.verify(proof, weeklyRoots[week], leaf);
    }

    function emergencyWithdraw(address token) external onlyRole(URGENT_ROLE) {
        require(
            IERC20(token).transfer(beneficiary, IERC20(token).balanceOf(address(this))),
            "redeemer/transfer-failed"
        );
    }
}
