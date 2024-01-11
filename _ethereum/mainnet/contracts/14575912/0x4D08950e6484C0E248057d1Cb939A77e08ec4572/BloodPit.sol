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

interface IBloodToken {
  function spend(address wallet_, uint256 amount_) external;
}

contract BloodPit is Ownable {
  event Burned(address wallet, uint256 amount);

  IBloodToken public bloodToken;

  /**
   * @dev Constructor
   * @param _token Address of Blood token.
   */
  constructor(address _token) {
    bloodToken = IBloodToken(_token);
  }

  /**
   * @dev Function for burning in game tokens and increasing blood pit standing.
   * @notice This contract has to be authorised.
   * @param amount Amount of tokens user is burning in the blood pit.
   */
  function burn(uint256 amount) external {
    bloodToken.spend(msg.sender, amount);
    emit Burned(msg.sender, amount);
  }
}
