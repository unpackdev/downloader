// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./Strings.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./VRFConsumerBase.sol";

/**
 * MurAll Frame contract
 */
contract TraitSeedManager is AccessControl, ReentrancyGuard, VRFConsumerBase {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public rangeSize;
    uint256 public rangeStart;
    uint256 public phase;
    using Strings for uint256;

    uint256[] public traitSeeds;

    // for chainlink vrf
    bytes32 internal keyHash;
    uint256 internal fee;

    event RandomnessRequested(bytes32 requestId);
    event TraitSeedSet(uint256 seed);

    /** @dev Checks if sender address has admin role
     */
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Does not have admin role");
        _;
    }

    constructor(
        address[] memory admins,
        address _vrfCoordinator,
        address _linkTokenAddr,
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _rangeSize,
        uint256 _rangeStart
    ) public VRFConsumerBase(_vrfCoordinator, _linkTokenAddr) {
        for (uint256 i = 0; i < admins.length; ++i) {
            _setupRole(ADMIN_ROLE, admins[i]);
        }
        keyHash = _keyHash;
        fee = _fee;
        rangeSize = _rangeSize;
        rangeStart = _rangeStart;
    }

    function setPhase(uint256 _phase) public onlyAdmin {
        require(_phase <= traitSeeds.length + 1, "Phase is out of range");

        phase = _phase;
    }

    function getMaxIdForCurrentPhase() public view returns (uint256) {
        return rangeStart + phase * rangeSize;
    }

    function addTraitSeedForRange(uint256 amountOfSeeds) public onlyAdmin {
        require(traitSeeds.length > 0 && traitSeeds[0] != 0, "Must have at least 1 trait seed");

        for (uint256 i = 0; i < amountOfSeeds; ++i) {
            uint256 newSeed = uint256(keccak256(abi.encode(traitSeeds[traitSeeds.length - 1], block.timestamp)));

            traitSeeds.push(newSeed);
            emit TraitSeedSet(newSeed);
        }
    }

    function getTraitSeedsLength() public view returns (uint256) {
        return traitSeeds.length;
    }

    function getTraitSeed(uint256 _tokenId) public view returns (uint256 traitSeed) {
        require(traitSeeds.length > 0 && traitSeeds[0] != 0, "Must have at least 1 trait seed");
        if (_tokenId <= rangeStart) {
            traitSeed = traitSeeds[0];
        } else {
            require(_tokenId <= rangeStart + traitSeeds.length * rangeSize, "Trait seed not set for token id");
            traitSeed = traitSeeds[(_tokenId - rangeStart - 1) / rangeSize];
        }
    }

    /** Chainlink VRF ****************************/
    function requestTraitSeed() public onlyAdmin nonReentrant {
        // require(traitSeeds[0] == 0, "Trait seed already requested");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 requestId = requestRandomness(keyHash, fee);

        emit RandomnessRequested(requestId);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        traitSeeds.push(randomness);
        emit TraitSeedSet(randomness);
    }

    /** END Chainlink VRF ****************************/

    function withdrawFunds(address payable _to) public onlyAdmin {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Failed to transfer the funds, aborting.");
    }

    function rescueTokens(address tokenAddress) public onlyAdmin {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(IERC20(tokenAddress).transfer(msg.sender, balance), "rescueTokens: Transfer failed.");
    }

    fallback() external payable {}

    receive() external payable {}
}
