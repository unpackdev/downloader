// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./ITreasury.sol";

contract FlyzClaim is Ownable, ReentrancyGuard, Pausable {
    uint256 public claimStartDate;
    uint256 public claimEndDate;
    uint256 public totalRewards;
    ITreasury public treasury;
    bytes32 public merkelRoot;
    mapping(address => bool) private _claims;

    event Claim(address indexed account, uint256 amount);
    event ClaimDatesChanged(uint256 startBlock, uint256 endBlock);
    event MerkelRootUpdated(bytes32 root);

    modifier whenClaimable() {
        require(claimStartDate <= block.timestamp, "FlyzClaim: before date");
        require(claimEndDate == 0 || claimEndDate >= block.timestamp, "FlyzClaim: after date");
        _;
    }

    constructor(
        ITreasury _treasury,
        uint256 _claimStartDate,
        uint256 _claimEndDate
    ) {
        treasury = _treasury;
        claimStartDate = _claimStartDate;
        claimEndDate = _claimEndDate;
    }

    function setClaimDates(uint256 _claimStartDate, uint256 _claimEndDate) external onlyOwner {
        require(_claimEndDate == 0 || _claimStartDate < _claimEndDate, "FlyzClaim: invalid dates");
        claimStartDate = _claimStartDate;
        claimEndDate = _claimEndDate;
        emit ClaimDatesChanged(claimStartDate, claimEndDate);
    }

    function setMerkelRoot(bytes32 _merkelRoot) external onlyOwner {
        merkelRoot = _merkelRoot;
        emit MerkelRootUpdated(merkelRoot);
    }

    function claim(
        uint256 amount,
        bytes32 userRoot,
        bytes32[] memory proof
    ) external nonReentrant whenNotPaused whenClaimable {
        require(!_claims[_msgSender()], "FlyzClaim: Already claimed");
        require(
            MerkleProof.verify(proof, merkelRoot, keccak256(abi.encodePacked(_msgSender(), amount, userRoot))),
            "FlyzClaim: Proof not verified"
        );

        _claims[_msgSender()] = true;
        treasury.mintRewards(_msgSender(), amount);
        totalRewards += amount;
        emit Claim(_msgSender(), amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function hasClaimed(address _account) public view returns (bool) {
        return _claims[_account];
    }
}
