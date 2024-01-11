// SPDX-License-Identifier: MIT
/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";

interface IBloodToken {
  function spend(address wallet_, uint256 amount_) external;
}

contract Whitelist is Ownable {
  event Whitelisted(address wallet, uint256 project, uint256 price);

  IBloodToken public bloodToken;
  address public signer;

  mapping(address => mapping(uint256 => bool)) public whitelisted;
  mapping(uint256 => uint256) public projectSlots;

  /**
   * @dev Constructor
   * @param _token Address of Blood token.
   * @param _signer Address of the backend signer.
   */
  constructor(address _token, address _signer) {
    bloodToken = IBloodToken(_token);
    signer = _signer;
  }

  /**
   * @dev function for whitelisting by speding in game wallet money.
   * @notice This contract has to be whitelisted.
   * @param price Price for which user is buying whitelist.
   * @param project Project for which user is buying whitelist.
   * @param timestamp Signature creation timestamp.
   * @param signature Signature of above data.
   */
  function whitelist(
    uint256 price,
    uint256 project,
    uint256 timestamp,
    bytes memory signature
  ) external {
    require(!whitelisted[msg.sender][project], "Already whitelisted.");
    require(
      validateSignature(msg.sender, price, project, timestamp, signature),
      "Invalid signature."
    );
    // signature is valid for 60 minutes.
    require(timestamp + 3600 > block.timestamp, "Signature expired.");
    require(projectSlots[project] > 0, "No more slots available.");
    projectSlots[project]--;
    whitelisted[msg.sender][project] = true;

    bloodToken.spend(msg.sender, price);
    emit Whitelisted(msg.sender, project, price);
  }

  /**
   * @dev Validates signature.
   * @param _sender User wanting to whitelist.
   * @param _price Price for which user is buying whitelist.
   * @param _project Project for which user is buying whitelist.
   * @param _timestamp Signature creation timestamp.
   * @param _signature Signature of above data.
   */
  function validateSignature(
    address _sender,
    uint256 _price,
    uint256 _project,
    uint256 _timestamp,
    bytes memory _signature
  ) public view returns (bool) {
    bytes32 dataHash = keccak256(
      abi.encodePacked(_sender, _price, _project, _timestamp)
    );
    bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
    address receivedAddress = ECDSA.recover(message, _signature);
    return receivedAddress == signer;
  }

  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }

  /**
   * @dev Sets slots available for a project.
   * @param projects Project ids.
   * @param slots Slots available.
   */
  function setProjects(uint256[] calldata projects, uint256[] calldata slots) external onlyOwner {
    for (uint8 i = 0; i < projects.length; i++) {
      projectSlots[projects[i]] = slots[i];
    }
  }
}
