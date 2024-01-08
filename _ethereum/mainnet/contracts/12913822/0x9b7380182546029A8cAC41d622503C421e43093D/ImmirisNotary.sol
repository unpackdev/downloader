// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import Ownable from the OpenZeppelin Contracts library
import "./Ownable.sol";

contract ImmirisNotary is Ownable {
  event CreatedCertificate(string indexed constructionPermitId, bytes32 indexed statementFileHash, address issuer);

  struct Certificate {
    string constructionPermitId;
    uint timestamp;
  }

  mapping (bytes32 => Certificate) private certificates;
  bytes32[] public statementFileHashes;

  function createCertificate(string calldata constructionPermitId, bytes32 hash) public onlyOwner {
      require(certificates[hash].timestamp == 0, "IMMIRIS: certificate already exists for this hash");

      certificates[hash].constructionPermitId = constructionPermitId;
      certificates[hash].timestamp = block.timestamp;

      statementFileHashes.push(hash);

      emit CreatedCertificate(constructionPermitId, hash, msg.sender);
  }

  function getCertificate(bytes32 hash) public view returns (Certificate memory) {
    require(certificates[hash].timestamp != 0, "IMMIRIS: no certificate exists for this hash");

    return certificates[hash];
  }
}
