// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./IERC20Permit.sol";
import "./Blocklist.sol";

/**
 * @title Redemption Contract
 * @dev A contract to do a fair redemption of ether based on a fixed token rate
 * @notice This contract is not audited
 */
contract TokenRedemption {
  address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
  IERC20Permit public immutable token;
  uint256 public immutable endingTimestamp;
  address public immutable recipient;
  uint256 public immutable tokenToEthRate;
  uint256 public immutable tokenAmountBase;
  bytes32 public immutable termsHash;
  Blocklist public immutable blocklist;

  error FailedToSendEth();
  error RedemptionPeriodNotFinished();
  error RedemptionPeriodFinished();
  error TermsNotCorrect();
  error AddressBlocklisted();
  error BlocklistNotInitialized();

  event EthClaimed(address receiver, uint256 tokenAmount, uint256 ethAmount);
  event EthReceived(address sender, uint256 ethSent);

  constructor(
    IERC20Permit _token,
    uint256 _endingTimestamp,
    address _recipient,
    uint256 _tokenToEthRate,
    bytes32 _termsHash,
    Blocklist _blocklist
  ) {
    token = _token;
    endingTimestamp = _endingTimestamp;
    recipient = _recipient;
    tokenAmountBase = 10 ** token.decimals();
    tokenToEthRate = _tokenToEthRate;
    termsHash = _termsHash;
    blocklist = _blocklist;
  }

  /**
   * @notice Allows for redeeming the ether from a token based on permit sigs
   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
   * ordering also apply here.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `deadline` must be a timestamp in the future.
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``owner``'s current nonce (see {nonces}).
   *
   * For more information on the signature format, see the
   * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
   * section].
   */
  function permitRedeem(bytes32 _termsHash, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
    token.permit(msg.sender, address(this), amount, deadline, v, r, s);
    redeem(_termsHash, amount);
  }

  /**
   * @notice Call this with your address to redeep your part of the eth
   * @dev This function will claim the desired amount of the funds,
            getting in return the tokens set by the `tokenToEthRate`
   * @param _termsHash The hash of the ToS
   * @param tokenAmount The amount to be claimed by the user
   */
  function redeem(bytes32 _termsHash, uint256 tokenAmount) public {
    if (blocklist.isBlocklisted(msg.sender)) {
      revert AddressBlocklisted();
    }
    if (termsHash != _termsHash) {
      revert TermsNotCorrect();
    }
    if (block.timestamp > endingTimestamp) {
      revert RedemptionPeriodFinished();
    }

    token.transferFrom(msg.sender, address(this), tokenAmount);
    uint256 ethToSend = (tokenAmount * tokenToEthRate) / tokenAmountBase;
    (bool result, ) = msg.sender.call{ value: ethToSend }("");
    if (!result) {
      revert FailedToSendEth();
    }

    emit EthClaimed(msg.sender, tokenAmount, ethToSend);
  }

  /**
   * @notice This function is called once the redemption period is finished to claim the remaining funds
   */
  function claimRemainings() external {
    if (block.timestamp <= endingTimestamp) {
      revert RedemptionPeriodNotFinished();
    }

    // Sending the token to the burning address
    token.transfer(DEAD_ADDRESS, token.balanceOf(address(this)));
    recipient.call{ value: address(this).balance }("");
  }

  receive() external payable {
    emit EthReceived(msg.sender, msg.value);
  }
}
