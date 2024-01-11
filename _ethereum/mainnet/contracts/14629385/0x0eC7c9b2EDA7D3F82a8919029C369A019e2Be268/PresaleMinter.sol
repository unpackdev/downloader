//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Address.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";

/*

__          ________ _      _____ ____  __  __ ______   _        
\ \        / /  ____| |    / ____/ __ \|  \/  |  ____| | |       
 \ \  /\  / /| |__  | |   | |   | |  | | \  / | |__    | |_ ___  
  \ \/  \/ / |  __| | |   | |   | |  | | |\/| |  __|   | __/ _ \ 
   \  /\  /  | |____| |___| |___| |__| | |  | | |____  | || (_) |
    \/  \/   |______|______\_____\____/|_|  |_|______|  \__\___/ 

  _____ _____  ______ _____ ____  _               _   _ _____  
 / ____|  __ \|  ____/ ____/ __ \| |        /\   | \ | |  __ \ 
| |    | |__) | |__ | |   | |  | | |       /  \  |  \| | |  | |
| |    |  _  /|  __|| |   | |  | | |      / /\ \ | . ` | |  | |
| |____| | \ \| |___| |___| |__| | |____ / ____ \| |\  | |__| |
 \_____|_|  \_\______\_____\____/|______/_/    \_\_| \_|_____/ 

🐊🐊
*/        

interface ICrecodiles {
  function mintTo(address) external returns(uint);
  function beneficiary() external returns(address payable);
  function setDNA(uint256[] memory, uint256[] memory) external;
}

contract CrecodileMinter is Ownable {
  using ECDSA for bytes32;
  using SafeMath for uint256;
  using Address for address payable;

  bool public isPreSaleActive = false;
  address public verifier; 
  uint256 public mintPrice = 0.088 ether;
  uint256 public maxAmount = 4;

  ICrecodiles public crecodiles;

  constructor(address _address) {
    crecodiles = ICrecodiles(_address);
  }

  // OWNER
  function setVerifier(address _verifier) public onlyOwner {
    verifier = _verifier;
  }

  function setPreSaleActive(bool _state) public onlyOwner {
    isPreSaleActive = _state;
  }

  function setPrice(uint256 _mintPrice) public onlyOwner {
    mintPrice = _mintPrice;
  }

  function setMaxAmount(uint256 amount) public onlyOwner {
    maxAmount = amount;
  }

  // INTERNAL
  function _mint(address to, uint amount) internal returns(uint256[] memory) {
    uint256[] memory ids = new uint256[](amount);
    for (uint i = 0; i < amount; i++) {
      uint tokenId = crecodiles.mintTo(to);
      ids[i] = tokenId;
    }
    return ids;
  }

  // PUBLIC 
  function hashDna(uint256[] calldata dna) public pure returns(bytes32) {
    return keccak256(abi.encode(dna));
  }

  function mintPreSaleWithMetadataStrict(address to, uint256[] calldata dna, bytes memory signature) external payable {
    require(isPreSaleActive, "Presale is closed");
    require(msg.value == mintPrice.mul(dna.length), "Ether value sent is not correct");
    require(dna.length > 0, "Empty DNA");
    require(dna.length <= maxAmount, "Exceeds max");
    require(verifier != address(0x0), "Verifier not set");
    address payable beneficiary = crecodiles.beneficiary();
    require(beneficiary != address(0x0), "Beneficiary not set");
    bytes32 _dnaHash = hashDna(dna);
    bytes32 _msg = keccak256(abi.encodePacked(to, dna.length, _dnaHash));
    address _recovered = _msg.recover(signature);
    require(verifier == _recovered, "Bad signature");
    beneficiary.sendValue(msg.value);
    uint256[] memory ids = _mint(to, dna.length); // 525,970 gas for 4
    crecodiles.setDNA(ids, dna);
  }

}
