// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import "./PToken.sol";
import "./ProxyFactory.sol";

contract PTokenFactory is ProxyFactory {
  address public ptokenLogic;
  mapping(address => PToken) public userPTokens;

  event PTokenLogicDeployed(address logicAddress);
  event NewPToken(PToken token);

  constructor() public {
    // Deploy our PToken logic contract and initialize it so no one else can
    PToken ptokenLogicContract = new PToken();
    ptokenLogicContract.initializePtoken("PToken Logic", "PTLOGIC", 0, 0, address(0));

    // Save off the address
    ptokenLogic = address(ptokenLogicContract);
    emit PTokenLogicDeployed(address(ptokenLogicContract));
  }

  /**
   * @notice Creats a pToken for the calleer
   * @param _name Token name
   * @param _symbol Token symbol
   * @param _price Price per token, denominated in _acceptedERC20 units
   * @param _initialSupply Initial token supply
   * @param _acceptedERC20 Address of token used to purchase these tokens
   */
  function createPToken(
    string memory _name,
    string memory _symbol,
    uint256 _price,
    uint256 _initialSupply,
    address _acceptedERC20
  ) public {
    require(address(userPTokens[msg.sender]) == address(0), "PToken: User token already exists");

    // Deploy PToken contract and call initialization function
    bytes memory payload =
      abi.encodeWithSignature(
        "initializePtoken(string,string,uint256,uint256,address)",
        _name,
        _symbol,
        _price,
        _initialSupply,
        _acceptedERC20
      );
    address newPtokenContract = deployMinimal(ptokenLogic, payload);

    // Update state
    userPTokens[msg.sender] = PToken(newPtokenContract);
    userPTokens[msg.sender].transferOwnership(msg.sender);
    emit NewPToken(userPTokens[msg.sender]);
  }
}
