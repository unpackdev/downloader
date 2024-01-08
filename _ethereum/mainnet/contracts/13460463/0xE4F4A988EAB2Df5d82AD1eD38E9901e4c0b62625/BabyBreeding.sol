pragma solidity ^0.8.0;

//SPDX-License-Identifier: Unlicense

import "./console.sol";
import "./Initializable.sol";
import "./BabyBase.sol";

contract BabyBreeding is BabyBase, Initializable {

    constructor() {}

    function initialize(address _femaleAddr, address _maleAddr, address _babyAddr) public initializer {
        // Starts paused.
        paused = true;
        hippoFemale = IHippoFemale(_femaleAddr);
        hippoMale = IHippoMale(_maleAddr);
        hippoBaby = IHippoBaby(_babyAddr);
    }

    receive() external payable {}

    function unpause() public override onlyOwner whenPaused {
        super.unpause();
    }

    function withdrawBalance(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    // Breeding enable for public 
    bool isBreedingEnableForPublic;

    function _isMalePermitted(uint256 _maleId, uint256 _femaleId) internal view returns (bool) {
        address femaleOwner = hippoFemale.ownerOf(_femaleId); 
        address maleOwner = hippoMale.ownerOf(_maleId);

        return (femaleOwner == maleOwner || maleAllowedToAddress[_maleId] == femaleOwner);
    }

    function approveMale(address _addr, uint256 _maleId) external whenNotPaused {
        require(hippoMale.ownerOf(_maleId) == msg.sender); 
        maleAllowedToAddress[_maleId] = _addr;
    }

    function enableBreedingForPublic(bool _status) external onlyOwner {
        isBreedingEnableForPublic = _status;
    }

    function setBreedingPrice(uint256 _price) external onlyOwner {
        breedingPrice = _price;
    }

    function setMaleApproveReward(uint256 _price) external onlyOwner {
        maleApproveReward = _price;
    }

    function canBreedWith(uint256 _femaleId, uint256 _maleId) external view returns(bool) {
        bool retVal = false;
        require(_femaleId > 0);
        require(_maleId > 0);
        retVal = _isMalePermitted(_maleId, _femaleId);
        if(retVal) {
            if(claimedFemaleInfo[_femaleId]) {
                FemaleInfo storage female = femaleInfos[_femaleId];
                retVal = (female.breedingCount < female.maxBreedingCount) 
                    && (female.lastBreedingAt + _getCoolDownPeriod(female.breedingCount) <= block.timestamp);
            }
        }
        return retVal;
    }

    function _getCoolDownPeriod(uint breedingCount) internal view returns(uint) {
        uint cooldownIndex = breedingCount < 5 ? breedingCount : 4;
        return cooldowns[cooldownIndex];
    }

    function breed(uint32 _femaleId, uint32 _maleId) external payable whenNotPaused {
        require(isBreedingEnableForPublic);
        require(msg.value >= breedingPrice, "Value below breeding price");

        // Caller must own the female.
        require(hippoFemale.ownerOf(_femaleId) == msg.sender);

        if(!claimedFemaleInfo[_femaleId]) _claimFemaleCategory(_femaleId);

        require(_isMalePermitted(_maleId, _femaleId));

        // Grab a reference to the potential female
        FemaleInfo storage female = femaleInfos[_femaleId];

        // Make sure female isn't pregnant, or in the middle of a male cooldown
        require(female.breedingCount < female.maxBreedingCount, "Over max breeding count");
        require(female.lastBreedingAt + _getCoolDownPeriod(female.breedingCount) <= block.timestamp, "Hippo is in cooldown period");
        female.breedingCount++;
        female.lastBreedingAt = block.timestamp;
        female.nextBreedingAt = block.timestamp + _getCoolDownPeriod(female.breedingCount);

        // Mint baby
        uint babyNftId = hippoBaby.totalSupply();
        hippoBaby.breedingMint(msg.sender);
        // send reward to male owner
        if(maleApproveReward > 0) payable(hippoMale.ownerOf(_maleId)).transfer(maleApproveReward);
        // Generate random Gender ID 
        uint gender = rand(2); // Gender Count 
        _createBaby(babyNftId, _maleId, _femaleId, msg.sender, gender == 0 ? Gender.MALE : Gender.FEMALE);
    }

    function burnBaby(uint256 babyNftId) external onlyBabyContract {
        _removeBaby(babyNftId);
    }

    function _getFemaleMaxBreedingCount() internal view returns(uint256) {
        uint probability = rand(100);
        uint256 num = type(uint256).max;
        if(probability < 50) num = 1; // 1 time breed
        else if(probability < 80) num = 2; // 2 times breed
        else if(probability < 90) num = 3; // 3 times breed
        else if(probability < 99) num = 4; // 4 times breed
        return num;
    }

    function _claimFemaleCategory(uint32 femaleId) internal {
        claimedFemaleInfo[femaleId] = true;
        femaleInfos[femaleId] = FemaleInfo({
            femaleId: femaleId,
            maxBreedingCount: _getFemaleMaxBreedingCount(),
            breedingCount: 0,
            lastBreedingAt: 0,
            nextBreedingAt: 0
        });
    }

    function claimFemaleCategory(uint32 femaleId) external {
        require(_msgSender() == hippoFemale.ownerOf(femaleId), "Not hippo owner");
        require(!claimedFemaleInfo[femaleId], "This hippo already has info");

        _claimFemaleCategory(femaleId);
    }
}