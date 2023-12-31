// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IEsEMBR.sol";
import "./Owned.sol";

contract EsEMBRRewardsDistributor is Owned {
    IEsEMBR public esEmbr;

    uint256 public emissionPerSecondEth; // Max esEMBR emissions per second for ETH stakers
    uint256 public emissionPerSecondEmbr; // Max esEMBR emissions per second for EMBR stakers

    uint256 private lastEmissionTimeEth;
    uint256 private lastEmissionTimeEmbr;

    constructor() Owned(msg.sender) { }

    modifier onlyEsEMBR() {
        require(msg.sender == address(esEmbr), "EsEMBRRewardsDistributor: Only esEMBR contract can call this function");
        _;
    }

    function setEsEMBR(address payable _esEmbr) external onlyOwner {
        esEmbr = IEsEMBR(_esEmbr);
    }

    function setEmissionPerSecondEth(uint256 amount) external onlyOwner {
        esEmbr.updateRewardsEthForAll();

        emissionPerSecondEth = amount;
        lastEmissionTimeEth = block.timestamp;
    }

    function setEmissionPerSecondEmbr(uint256 amount) external onlyOwner {
        esEmbr.updateRewardsEmbrForAll();

        emissionPerSecondEmbr = amount;
        lastEmissionTimeEmbr = block.timestamp;
    }

    function _clamp(uint256 value, uint256 max) internal pure returns(uint256) {
        return value > max ? max : value;
    }

    function distributeForEth() onlyEsEMBR external returns (uint256) {
        uint256 tokens_to_emit = pendingForEth();
        if (tokens_to_emit == 0) return 0;

        lastEmissionTimeEth = block.timestamp;

        return _clamp(tokens_to_emit, esEmbr.rewardsLeft());
    }

    function distributeForEmbr() onlyEsEMBR external returns (uint256) {
        uint256 tokens_to_emit = pendingForEmbr();
        if (tokens_to_emit == 0) return 0;

        lastEmissionTimeEmbr = block.timestamp;

        return _clamp(tokens_to_emit, esEmbr.rewardsLeft());
    }

    function pendingForEth() public view returns (uint256) {
        if (lastEmissionTimeEth == block.timestamp) return 0;

        return (block.timestamp - lastEmissionTimeEth) * emissionPerSecondEth;
    }

    function pendingForEmbr() public view returns (uint256) {
        if (lastEmissionTimeEmbr == block.timestamp) return 0;

        return (block.timestamp - lastEmissionTimeEmbr) * emissionPerSecondEmbr;
    }
}
