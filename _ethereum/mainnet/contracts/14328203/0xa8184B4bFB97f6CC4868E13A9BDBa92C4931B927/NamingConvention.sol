// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Strings.sol";
import "./IERC721.sol";
import "./ECDSA.sol";

/**
 * @dev Interface for checking active staked balance of a user.
 */
interface ILoomi {
  function spendLoomi(address user, uint256 amount) external;
}

interface ISTAKING {
  function ownerOf(address contractAddress, uint256 tokenId) external view returns (address);
}

contract NamingConvention is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using Strings for uint256;

    ILoomi public loomi;
    IERC721 public creepz;
    ISTAKING public staking;

    uint256 public firstNamePrice;
    uint256 public secondNamePrice;
    
    uint256[] public titlePrices;
    string[] public titles;

    bool public isPaused;
    bool public creepzRestriction;

    address public signer;

    mapping (uint256 => string) private _names;
    mapping (string => bool) private _nameReserved;
    
    event Rename(address indexed userAddress, uint256 creepzId, string name);

    function initialize(address _loomi, address _signer, address _creepz, address _staking) external initializer {
      firstNamePrice = 2000 ether;
      secondNamePrice = 5000 ether;
      
      titlePrices = [0 ether, 2000 ether, 5000 ether, 10000 ether, 20000 ether, 50000 ether, 100000 ether, 100000 ether, 200000 ether, 500000 ether, 1000000 ether];
      titles = ["","The Great","Love Doctor","Lil","Lord","Infamous","King","Queen","Simp Lord","Wizard","God"];

      loomi = ILoomi(_loomi);
      signer = _signer;
      creepz = IERC721(_creepz);
      staking = ISTAKING(_staking);

      creepzRestriction = true;
      isPaused = true;

      __Ownable_init();
      __ReentrancyGuard_init();
    }

    modifier whenNotPaused {
      require(!isPaused, "Name change paused!");
      _;
    }

    /**
    * @dev Function to withdraw game LOOMI to ERC-20 LOOMI.
    */
    function renameCreepz(
      uint256 _creepzId,
      string calldata _firstName,
      string calldata _secondName,
      uint256 _title,
      bytes calldata signature
    ) public nonReentrant whenNotPaused {
      require(_validateData(_title, _firstName, _secondName, signature), "Invalid Data Provided");
      require(_validateCreepzOwner(_creepzId, _msgSender()), "!Creepz owner");

      (string memory fullName, uint256 namePrice) = composeFullName(_firstName, _secondName, _title);

      require(sha256(bytes(fullName)) != sha256(bytes(_names[_creepzId])), "New name is same as the current one");
      require(!_isNameReserved(fullName), "Name already reserved");

      loomi.spendLoomi(_msgSender(), namePrice);

      if (bytes(_names[_creepzId]).length > 0) {
        _nameReserved[toLower(_names[_creepzId])] = false;
      }
      _nameReserved[toLower(fullName)] = true;
      _names[_creepzId] = fullName;

      emit Rename(
        _msgSender(),
        _creepzId,
        fullName
      );
    }

    function composeFullName(
      string calldata _firstName,
      string calldata _secondName,
      uint256 _title
    ) public view returns (string memory, uint256) {
      uint256 totalPrice = firstNamePrice;
      string memory fullName = _firstName;

      if (bytes(_secondName).length > 0 && _title > 0) {
        totalPrice += secondNamePrice + titlePrices[_title];
        fullName = string(abi.encodePacked(titles[_title], " ", _firstName, " ", _secondName));
      }
      if (bytes(_secondName).length > 0 && _title == 0) {
        totalPrice += secondNamePrice;
        fullName = string(abi.encodePacked(_firstName, " ", _secondName));
      }
      if (bytes(_secondName).length == 0 && _title > 0) {
        totalPrice += titlePrices[_title];
        fullName = string(abi.encodePacked(titles[_title], " ", _firstName));
      }

      return (fullName, totalPrice);
    }

    /**
    * @dev Function incoming name validation
    */
    function _validateData(
      uint256 _title,
      string calldata _firstName,
      string calldata _secondName,
      bytes calldata signature
      ) internal view returns (bool) {
      bytes32 dataHash = keccak256(abi.encodePacked(_title, _firstName, _secondName));
      bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

      address receivedAddress = ECDSA.recover(message, signature);
      return (receivedAddress != address(0) && receivedAddress == signer);
    }

    /**
    * @dev Function for Genesis Creepz ownership validation
    */
    function _validateCreepzOwner(uint256 tokenId, address user) internal view returns (bool) {
      if (!creepzRestriction) return true;
      if (staking.ownerOf(address(creepz), tokenId) == user) {
        return true;
      }
      return creepz.ownerOf(tokenId) == user;
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function isNameReserved(string calldata _firstName, string calldata _secondName, uint256 _title) public view returns (bool) {
      (string memory fullName, ) = composeFullName(_firstName, _secondName, _title);
      return _isNameReserved(fullName);
    }

    function creepzName(uint256 _creepzId) public view returns (string memory) {
      return _names[_creepzId];
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function _isNameReserved(string memory nameString) internal view returns (bool) {
      return _nameReserved[toLower(nameString)];
    }

    /**
    * @dev Function allows admin to retract name of any token.
    */
    function retractName(uint256 _creepzId) public onlyOwner {
      string memory currentName = _names[_creepzId];
      string memory newName = string(abi.encodePacked("Creepz #", _creepzId.toString()));

      _nameReserved[toLower(currentName)] = false;
      _nameReserved[toLower(newName)] = true;
      _names[_creepzId] = newName;

      emit Rename(_msgSender(),_creepzId,newName);
    }

    /**
    * @dev Function allows admin to update first Name Price.
    */
    function updateFirstNamePrice(uint256 _fNamePrice) public onlyOwner {
      firstNamePrice = _fNamePrice;
    }

    /**
    * @dev Function allows admin to update Surname Price.
    */
    function updateSecondNamePrice(uint256 _secondNamePrice) public onlyOwner {
      secondNamePrice = _secondNamePrice;
    }

    /**
    * @dev Function allows admin to add titles.
    */
    function addTitle(string calldata _title, uint256 _titlePrice) public onlyOwner {
      titles.push(_title);
      titlePrices.push(_titlePrice);
    }

    /**
    * @dev Function allows admin to pause contract.
    */
    function pause(bool _pause) public onlyOwner {
      isPaused = _pause;
    }

    function updateCreepzRestriction(bool _restrict) public onlyOwner {
      creepzRestriction = _restrict;
    }

    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}
