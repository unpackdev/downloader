// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./Pausable.sol";

interface IMintPass {
  function mint(address to, uint256 id, uint96 amount) external;
}

/*
                            :+
                           -#:
                          -##
                         .##*
                         =###
                         *###:     +
                         *###*     =*.
                   +.    +####*-   :##-
                   *+  . .#######++*###*.
                 .*#+ .*  +##############+.
                 +#*. +#  .################-
                     +#+   +################+.
                   :*##:   -##########*==#####:
                  +####:   -########=:.+#######-
                :*######=-=######+-  -##########-
               -##############*=.  .*############:
              :#############=:    -##############*
             .###########+-      =################-
             *#########=.          :-+############+
            :##########*+-:            :=*#########
            +#######+*######*+-        .=##########
            ########= .=*#####-      :+############
            #########.   .=*#:     -*#############*
            +########=      .    -*###############-
            :#########*+-:      +################*
             +###########+  :-:   :+############*.
              +#########= :*####*+-:.-+########*.
               -#######=-*###########*+=+*####=
                 -*#########################=.
                   :=*##################*=:
                       :-=+**####**+=-:.


@title Shackers Mint Pass Airdrop
@author loltapes.eth
*/
contract ShackersMintPassAirdrop is AccessControl, Ownable, Pausable {

  error RecipientsAmountsMismatch();
  error OverAirdropLimit();

  bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

  IMintPass public immutable MINT_PASS_CONTRACT;

  uint256 public constant AIRDROP_LIMIT = 10;

  constructor(
    address mintPassContractAddress
  ) {
    MINT_PASS_CONTRACT = IMintPass(mintPassContractAddress);

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(AIRDROP_ROLE, msg.sender);
  }

  function airdrop(
    uint256 passId,
    address[] calldata to,
    uint96[] calldata amounts
  ) external onlyRole(AIRDROP_ROLE) whenNotPaused {
    if(to.length != amounts.length) revert RecipientsAmountsMismatch();
    uint256 amount = to.length;

    for (uint256 i = 0; i < amount;) {
      if (amounts[i] > AIRDROP_LIMIT) revert OverAirdropLimit();
      MINT_PASS_CONTRACT.mint(to[i], passId, amounts[i]);
    unchecked {++i;}
    }
  }
}
