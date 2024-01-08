// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";

interface IPandas {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256);
    function pandasOfOwner(address _owner) external view returns(uint256[] memory );
    function getMintTime(uint256 tokenId) external view returns(uint256);
}


contract BambooToken is Context, Ownable, ERC20Burnable, ERC20Pausable {
    uint256 private constant SECONDS_IN_A_DAY = 86400;
    uint256 private constant INITIAL_REWARD = 1000 * (10 ** 18);
    uint256 public emissions_per_day = 100 * (10 ** 18);
    uint256 private _createdTime;

    uint256 public numContracts = 0;
    mapping(uint256 => address) public contractAddresses;
    mapping(uint256 => uint256) public bambooMultiplier;
    mapping(bytes32 => uint256) private _lastClaim;

    constructor(address contractGen1, uint256 multiplier) ERC20("BambooToken", "BAMBOO") {
        _createdTime = block.timestamp;
        addContract(contractGen1, multiplier);
    }

    // Adds new contract whose Pandas generate Bamboo.
    function addContract(address contractAddress, uint256 _bambooMultiplier) public onlyOwner {
        for (uint256 i = 0; i < numContracts; i++) {
            require(contractAddress != contractAddresses[i], 'Contract already added');
        }
        contractAddresses[numContracts] = contractAddress;
        bambooMultiplier[numContracts] = _bambooMultiplier;
        numContracts = numContracts + 1;
    }

    // See how much Bamboo is accumulated by a specific Panda.
    function accumulated(uint256 tokenId, uint256 contractId) public view returns (uint256) {
        address contractAddress = contractAddresses[contractId];
        require(tokenId <= IPandas(contractAddress).totalSupply(), "Panda does not exist");
        require(IPandas(contractAddress).ownerOf(tokenId) != address(0), "Nobody owns this Panda");

        bytes32 hash = keccak256(abi.encodePacked(tokenId, contractId));
        uint256 lastClaimed = uint256(_lastClaim[hash]);
        uint256 claimPeriod;
        if (lastClaimed == 0 && contractId == 0) {
            // Bamboo has never been claimed and Panda is from generation 1.
            claimPeriod = _createdTime;
        } else if (lastClaimed == 0) {
            // Bamboo has never been claimed and Panda is from generation >1.
            claimPeriod = IPandas(contractAddress).getMintTime(tokenId);
        } else {
            // Bamboo has already been claimed.
            claimPeriod = lastClaimed;
        }

        uint256 totalAccum = ((block.timestamp - claimPeriod) * emissions_per_day * bambooMultiplier[contractId]) / SECONDS_IN_A_DAY;

        // give initial reward if this Panda hasn't claimed its Bamboo yet and is first generation Panda
        if (lastClaimed == 0 && contractId == 0) totalAccum = totalAccum + INITIAL_REWARD;

        return totalAccum;
    }

    // See how much Bamboo is accumulated by multiple Pandas.
    function totalAccumulated(uint256[] memory tokenIds, uint256[] memory contractIds) public view returns (uint256) {
        require(tokenIds.length == contractIds.length, "Unequal number of panda and contract IDs");
        uint256 totalAccum = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalAccum = totalAccum + accumulated(tokenIds[i], contractIds[i]);
        }

        return totalAccum;
    }


    function claim(uint256[] memory tokenIds, uint256[] memory contractIds) public returns (uint256) {
        require(tokenIds.length == contractIds.length, "Unequal number of panda and contract IDs");

        uint256 totalClaimQty = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 contractId = contractIds[i];
            address contractAddress = contractAddresses[contractId];

            require(tokenId <= IPandas(contractAddress).totalSupply(), "Panda does not exist");

            // // Todo: isch das nöd egal?
            // for (uint256 j = i + 1; j < tokenIds.length; j++) {
            //     require(!(tokenId == tokenIds[j] && contractId == contractIds[j]), "Duplicate token IDs");
            // }

            require(IPandas(contractAddress).ownerOf(tokenId) == msg.sender, "You are not the owner");

            uint256 claimQty = accumulated(tokenId, contractId);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty + claimQty;

                bytes32 hash = keccak256(abi.encodePacked(tokenId, contractId));
                _lastClaim[hash] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "No accumulated $BAMBOO");
        _mint(msg.sender, totalClaimQty);

        return totalClaimQty;
    }

    function pandasOfOwner(address _owner, uint256 contractId) external view returns(uint256[] memory) {
        address contractAddress = contractAddresses[contractId];
        uint256[] memory pandaIds = IPandas(contractAddress).pandasOfOwner(_owner);
        return pandaIds;
    }

    function setDailyEmitionsRate(uint256 rewardAmount) public virtual onlyOwner {
        emissions_per_day = rewardAmount;
    }

    function mint(address to, uint256 amount) public virtual onlyOwner {
        _mint(to, amount);
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
