// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Mintable.sol";
import "./ERC721.sol";
import "./Signature.sol";
import "./LondonBurnMinterBase.sol";
import "./LondonBurn.sol";

abstract contract LondonBurnNoble is LondonBurnMinterBase {
  enum Nobility {
    Common,
    Baron, 
    Earl, 
    Duke
  }
  
  mapping(Nobility => uint256) airdropAmount;

  constructor(
  ) {
    airdropAmount[Nobility.Baron] = 2;
    airdropAmount[Nobility.Earl] = 5;
    airdropAmount[Nobility.Duke] = 16;
  }

  address public airdropAuthority;

  mapping(address => uint256) public receivedAirdropNum;

  function getAirdropHash(address to, Nobility nobility) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(to, nobility));
  }

  function setAirdropAuthority(address _airdropAuthority) external onlyOwner {
    airdropAuthority = _airdropAuthority;
  }
  
  function verifyAirdrop(
    address to, Nobility nobility, bytes calldata signature
  ) public view returns (bool) {
    bytes32 signedHash = getAirdropHash(to, nobility);
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
    return isSigned(airdropAuthority, signedHash, v, r, s);
  }

  function mintNobleType(
    Nobility nobility, bytes calldata signature, LondonBurn.MintCheck calldata mintCheck
  ) public {
    require(block.number > revealBlockNumber, 'NOBLE has not been revealed yet');
    require(block.number < ultraSonicForkBlockNumber, "ULTRASONIC MODE ENGAGED");
    require(verifyAirdrop(_msgSender(), nobility, signature), "Noble mint is not valid");
    require(mintCheck.uris.length <= airdropAmount[nobility], "MintChecks length mismatch");
    require(receivedAirdropNum[_msgSender()] + mintCheck.uris.length <= airdropAmount[nobility], "Already received airdrop");
    require(mintCheck.tokenType == NOBLE_TYPE, "Must be correct tokenType");
    londonBurn.mintTokenType(mintCheck);
    receivedAirdropNum[_msgSender()] += mintCheck.uris.length;
  }

}