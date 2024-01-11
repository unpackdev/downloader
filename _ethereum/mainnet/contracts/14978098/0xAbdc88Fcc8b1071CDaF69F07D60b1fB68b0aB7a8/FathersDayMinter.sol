// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/*
                                                                         ▄▄▄██
 ████████████████▄▄▄▄                                               ▄█████████
  █████████▀▀▀▀█████████▄                                            ▀████████
  ▐███████▌       ▀████████▄                                          ▐███████
  ▐███████▌         █████████▄                                        ▐███████
  ▐███████▌          ▀████████▌         ▄▄▄▄                    ▄▄▄   ▐███████          ▄▄▄▄
  ▐███████▌           █████████▌   ▄█████▀▀█████▄▄         ▄█████▀▀███████████     ▄█████▀▀██████▄
  ▐███████▌            █████████ ▐██████    ▐██████▄     ▄█████▌     ▀████████   ▄██████    ▐██████
  ▐███████▌            █████████ ▐█████      ███████▌   ███████       ████████  ▐███████▌    ▀█████
  ▐███████▌            ▐████████       ▄▄▄▄  ▐███████  ▐███████       ▐███████   ██████████▄▄
  ▐███████▌            ▐███████▌   ▄███████▀█████████  ████████       ▐███████    ██████████████▄▄
  ▐███████▌            ███████▌  ▄███████    ▐███████▌ ▐███████       ▐███████      ▀▀█████████████
  ▐███████▌           ▄██████▀   ████████     ████████  ████████      ▐███████   ████▄    ▀▀███████▌
  ▐████████▄        ▄██████▀     ████████     ████████   ███████▌     ▐███████  ███████     ▐██████▌
 ▄██████████████████████▀         ▀███████▄  ▄█████████▄  ▀███████▄  ▄█████████  ▀██████▄   ██████▀
 ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀                ▀▀▀████▀▀▀  ▀▀▀▀▀▀▀▀     ▀▀▀████▀▀  ▀▀▀▀▀▀▀▀    ▀▀▀▀████▀▀▀▀

*/

import "./Ownable.sol";
import "./GenericCollection.sol";

contract FathersDayMinter is Ownable {
  error SaleNotActiveError();
  error MaxWalletBalanceExceededError();
  error ContractMintDisallowedError();

  uint256 constant CARD_ID = 3;
  uint256 constant MAX_PER_WALLET = 2;

  bool public isActive = false;

  GenericCollection public specialsCollection;

  constructor(address specialsAddress) {
    specialsCollection = GenericCollection(specialsAddress);
  }

  function mintFathersDayCard() public {
    if (!isActive) revert SaleNotActiveError();
    if (specialsCollection.balanceOf(msg.sender, CARD_ID) >= MAX_PER_WALLET)
      revert MaxWalletBalanceExceededError();
    if (msg.sender != tx.origin) revert ContractMintDisallowedError();

    string memory uri = specialsCollection.uri(CARD_ID);
    specialsCollection.mint(CARD_ID, 1, uri, msg.sender);
  }

  function balanceOf(address wallet) public view returns (uint256) {
    return specialsCollection.balanceOf(wallet, CARD_ID);
  }

  function setActive(bool active) public onlyOwner {
    isActive = active;
  }
}
