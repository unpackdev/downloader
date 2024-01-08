pragma solidity ^0.8.0;
//SPDX-License-Identifier: Unlicense
import "./BabyAccessControl.sol";
import "./IHippoFemale.sol";
import "./IHippoMale.sol";
import "./IHippoBaby.sol";


contract BabyBase is BabyAccessControl {
  
    event BabyBirth(address creator, uint256 babyId, uint256 motherId, uint256 fatherId, Gender gender, uint256 birthDate);
    event BabyRemoval(uint256 babyId);

    struct FemaleInfo {
        uint32 femaleId;
        uint256 maxBreedingCount;
        uint32 breedingCount;
        uint256 lastBreedingAt;
        uint256 nextBreedingAt;
    }

    enum Gender { MALE, FEMALE }

    struct Baby {
        address creator;
        uint256 babyId;
        uint256 fatherId;
        uint256 motherId;
        Gender gender;
        uint256 birthDate;
    }

    uint256 public breedingPrice = 0;
    uint256 public maleApproveReward = 0;
    // Access Male, Female and Baby contract via address, define all contract variable for checking status and token ownership
    IHippoFemale public hippoFemale; // access Female contract
    IHippoMale public hippoMale; // accress Male contract
    IHippoBaby public hippoBaby; // access baby contract
    
    uint32[5] public cooldowns = [
        uint32(0 hours),
        uint32(72 hours),
        uint32(7 days),
        uint32(30 days),
        uint32(180 days)
    ];

    mapping (uint256 => address) public maleAllowedToAddress;
    // babyId => babyInfo
    mapping (uint256 => Baby) public babyInfos;
    // femaleId => femaleInfo
    mapping (uint256 => FemaleInfo) public femaleInfos;
    mapping (uint256 => bool) public claimedFemaleInfo;

    modifier onlyBabyContract {
        require(_msgSender() == address(hippoBaby), "Invalid baby contract");
        _;
    }

    function _createBaby(
        uint256 _babyId,
        uint256 _fatherId,
        uint256 _motherId,
        address _owner,
        Gender _gender
    ) internal {
        require(_owner != address(0));
      
        babyInfos[_babyId] = Baby({
            babyId: _babyId,
            fatherId: _fatherId,
            motherId: _motherId,
            creator: _owner,
            gender: _gender,
            birthDate: block.timestamp
        });

        // emit the birth event
        emit BabyBirth(
            _owner,
            _babyId,
            uint256(_motherId),
            uint256(_fatherId),
            _gender,
            block.timestamp
        );
    }

    function _removeBaby(uint256 _babyId) internal {
      
        babyInfos[_babyId].babyId = 0;
        babyInfos[_babyId].fatherId = 0;
        babyInfos[_babyId].motherId = 0;
        babyInfos[_babyId].creator = address(0x0);
        babyInfos[_babyId].gender = Gender(0);
        babyInfos[_babyId].birthDate = 0;

        // emit the remove event
        emit BabyRemoval(_babyId);
    }

    function rand(uint val) internal view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        return (seed - ((seed / val) * val));
    }
}