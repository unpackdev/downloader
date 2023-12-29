// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./AccessControl.sol";
import "./IAjnaDripper.sol";
import "./IAjnaRedeemer.sol";
import "./BitMaps.sol";

/* @inheritdoc IAjnaRedeemer */
contract AjnaRedeemer is AccessControl, IAjnaRedeemer {
    using BitMaps for BitMaps.BitMap;

    mapping(uint256 => bytes32) public weeklyRoots;
    mapping(address => BitMaps.BitMap) private hasClaimed;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    uint256 public immutable deploymentWeek;
    address public immutable dripper;
    IERC20 public immutable ajnaToken;

    event Claimed(address indexed user, uint256 indexed week, uint256 amount);

    constructor(IERC20 _ajnaToken, address _operator, address _dripper) {
        require(address(_ajnaToken) != address(0), "drip/invalid-ajna-token");
        require(_operator != address(0), "drip/invalid-operator");
        require(_dripper != address(0), "drip/invalid-dripper");
        deploymentWeek = block.timestamp / 1 weeks;
        ajnaToken = _ajnaToken;
        dripper = _dripper;
        _setupRole(OPERATOR_ROLE, _operator);
        _setupRole(EMERGENCY_ROLE, _operator);
        _setupRole(EMERGENCY_ROLE, _msgSender());
    }

    /* @inheritdoc IAjnaRedeemer */
    function getCurrentWeek() public view returns (uint256) {
        return block.timestamp / 1 weeks;
    }

    /* @inheritdoc IAjnaRedeemer */
    function addRoot(uint256 week, bytes32 root) external onlyRole(OPERATOR_ROLE) {
        require(weeklyRoots[week] == bytes32(0), "redeemer/root-already-added");
        require(IAjnaDripper(dripper).drip(week), "redeemer/transfer-from-failed");
        weeklyRoots[week] = root;
    }

    /* @inheritdoc IAjnaRedeemer */
    function getRoot(uint256 week) external view returns (bytes32) {
        bytes32 root = weeklyRoots[week];
        return root;
    }

    /* @inheritdoc IAjnaRedeemer */
    function claimMultiple(
        uint256[] calldata weekIds,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external {
        require(weekIds.length > 0, "redeemer/cannot-claim-zero");
        require(
            weekIds.length == amounts.length && amounts.length == proofs.length,
            "redeemer/invalid-params"
        );

        uint256 total;
        BitMaps.BitMap storage alreadyClaimed = hasClaimed[_msgSender()];
        for (uint256 i = 0; i < weekIds.length; i += 1) {
            uint256 adjustedWeekId = weekIds[i] - deploymentWeek;
            require(canClaim(proofs[i], weekIds[i], amounts[i]), "redeemer/cannot-claim");
            require(!alreadyClaimed.get(adjustedWeekId), "redeemer/already-claimed");
            alreadyClaimed.set(adjustedWeekId);
            total += amounts[i];
            emit Claimed(_msgSender(), weekIds[i], amounts[i]);
        }
        require(ajnaToken.transfer(_msgSender(), total), "redeemer/transfer-failed");
    }

    /* @inheritdoc IAjnaRedeemer */
    function canClaim(
        bytes32[] memory proof,
        uint256 week,
        uint256 amount
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), amount));
        return MerkleProof.verify(proof, weeklyRoots[week], leaf);
    }

    /* @inheritdoc IAjnaRedeemer */
    function emergencyWithdraw() external onlyRole(EMERGENCY_ROLE) {
        require(
            ajnaToken.transfer(dripper, ajnaToken.balanceOf(address(this))),
            "redeemer/transfer-failed"
        );
    }
}
