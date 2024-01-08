// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./IStakingContract.sol";

/*
    ____  ____  ___    ____  _____   ________   __    _________    ____  __________  _____
   / __ \/ __ \/   |  / __ \/  _/ | / / ____/  / /   / ____/   |  / __ \/ ____/ __ \/ ___/
  / /_/ / / / / /| | / /_/ // //  |/ / / __   / /   / __/ / /| | / / / / __/ / /_/ /\__ \ 
 / _, _/ /_/ / ___ |/ _, _// // /|  / /_/ /  / /___/ /___/ ___ |/ /_/ / /___/ _, _/___/ / 
/_/ |_|\____/_/  |_/_/ |_/___/_/ |_/\____/  /_____/_____/_/  |_/_____/_____/_/ |_|/____/  
                                                                                          

I see you nerd! ⌐⊙_⊙
*/

contract RLBreedingManager is Ownable {
    using Counters for Counters.Counter;

    using ECDSA for bytes32;

    Counters.Counter private _breedingCounter;

    address public cubsContractAddress;

    uint256 public maxBreedingSupply = 5000;

    IStakingContract public roarStakingContractInstance;

    // Mapping of token numbers to last timestamp bred
    mapping(uint256 => uint256) public lastTimestamps;

    // Used to validate authorized mint addresses
    address private _signerAddress = 0xB44b7e7988A225F8C479cB08a63C04e0039B53Ff;

    uint256 public maleCooldown = 28 * 24 * 3600;
    uint256 public femaleCooldown = 3 * 24 * 3600;

    constructor() {
        //
    }

    function setAddresses(address newCubsContractAddress, address roarStakingAddress, address newSignerAddress) public onlyOwner {
        cubsContractAddress = newCubsContractAddress;
        roarStakingContractInstance = IStakingContract(roarStakingAddress);
        _signerAddress = newSignerAddress;
    }

    function setMaxBreedingSupply(uint256 newMaxBreedingSupply) public onlyOwner {
        maxBreedingSupply = newMaxBreedingSupply;
    }

    function setCooldowns(uint256 newMaleCooldown, uint256 newFemaleCooldown) public onlyOwner {
        maleCooldown = newMaleCooldown;
        femaleCooldown = newFemaleCooldown;
    }

    function currentBreedingCount() external view returns (uint256) {
        return _breedingCounter.current();
    }

    /**
     * @dev Throws if called by any account other than the cubs contract.
     */
    modifier onlyCubs() {
        require(cubsContractAddress == msg.sender, "Caller is not the cubs contract");
        _;
    }

    function hashCooldowns(uint256 maleTokenId, uint256 femaleTokenId, bool hasSignature) public pure returns (bytes32) {
        return keccak256(abi.encode(
            maleTokenId,
            femaleTokenId,
            hasSignature
        ));
    }

    function hashListing(uint256 tokenId, uint256 rentalFee, uint256 expiry) public pure returns (bytes32) {
        return keccak256(abi.encode(
            tokenId,
            rentalFee,
            expiry
        ));
    }

    /*
    * Breed Roaring Leaders - both need to be owned by caller
    */
    function breedOwnLeaders(address ownerAddress, uint256 maleTokenId, uint256 femaleTokenId, bool hasSignature, bool instantCooldown, bytes memory signature) public onlyCubs {
        require(_breedingCounter.current() < maxBreedingSupply, "Max breeding supply");
        _breedingCounter.increment();
        
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = maleTokenId;
        tokenIds[1] = femaleTokenId;
        require(roarStakingContractInstance.hasDepositsOrOwns(ownerAddress, tokenIds), "Not owner");
        
        _verifyCooldowns(maleTokenId, femaleTokenId, hasSignature, instantCooldown, signature);
    }

    function breedUsingMarketplace(address ownerAddress, uint256 maleTokenId, uint256 femaleTokenId, bool hasSignature, bool instantCooldown, address renter, bool acceptorIsMaleOwner, uint256 rentalFee, uint256 expiry, bytes memory cooldownSignature, bytes memory listingSignature) public onlyCubs {
        require(_breedingCounter.current() < maxBreedingSupply, "Max breeding supply");
        _breedingCounter.increment();
        require(expiry > block.timestamp, "Listing has expired");
        
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = maleTokenId;
        require(roarStakingContractInstance.hasDepositsOrOwns(acceptorIsMaleOwner ? ownerAddress : renter, tokenIds), "Not owner");
        tokenIds[0] = femaleTokenId;
        require(roarStakingContractInstance.hasDepositsOrOwns(acceptorIsMaleOwner ? renter : ownerAddress, tokenIds), "Not owner");
        
        _verifyCooldowns(maleTokenId, femaleTokenId, hasSignature, instantCooldown, cooldownSignature);

        require(renter == hashListing(acceptorIsMaleOwner ? femaleTokenId : maleTokenId, rentalFee, expiry).toEthSignedMessageHash().recover(listingSignature), "Invalid listing signature");
    }

    function _verifyCooldowns(uint256 maleTokenId, uint256 femaleTokenId, bool hasSignature, bool instantCooldown, bytes memory signature) internal {
        if (!instantCooldown) {
            require((lastTimestamps[maleTokenId] + maleCooldown < block.timestamp) && (lastTimestamps[femaleTokenId] + femaleCooldown < block.timestamp), "Cooldown not expired");
        }
        require(_signerAddress == hashCooldowns(maleTokenId, femaleTokenId, hasSignature).toEthSignedMessageHash().recover(signature), "Invalid cooldown signature");

        lastTimestamps[maleTokenId] = block.timestamp;
        lastTimestamps[femaleTokenId] = block.timestamp;
    }
}