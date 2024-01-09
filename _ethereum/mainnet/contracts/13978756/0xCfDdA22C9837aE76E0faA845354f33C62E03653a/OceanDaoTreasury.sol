//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract OceanDaoTreasury is Ownable {
    using SafeERC20 for IERC20;
    address public verifierWallet;
    uint256 public grantDeadline = 2 weeks;
    mapping(bytes32 => bool) public isGrantClaimedHash;
    mapping(string => bool) public isGrantClaimedId;

    event VerifierWalletSet(address oldVerifierWallet);
    event TreasuryDeposit(
        address indexed sender,
        uint256 amount,
        address token
    );
    event TreasuryWithdraw(
        address indexed sender,
        uint256 amount,
        address token
    );
    event GrantClaimed(
        address indexed recipient,
        uint256 amount,
        string proposalId,
        uint256 roundNumber,
        address caller,
        uint256 timestamp
    );

    constructor(address _verifierWallet) {
        setVerifierWallet(_verifierWallet);
    }

    /*
     * @dev Set the verifier wallet.
     * @param _verifierWallet The new verifier wallet.
     */
    function setVerifierWallet(address _verifierWallet) public onlyOwner {
        verifierWallet = _verifierWallet;
        emit VerifierWalletSet(verifierWallet);
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return address(0);
        }
        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return address(0);
        }

        return signer;
    }

    /*
     * @dev Withdraw tokens from the treasury.
     * @param _amount The amount of tokens to deposit.
     * @param _token The token to deposit.
     */
    function withdrawFunds(uint256 amount, address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
        emit TreasuryWithdraw(msg.sender, amount, token);
    }

    function setGrantDeadline(uint256 _grantDeadline) external onlyOwner {
        grantDeadline = _grantDeadline;
    }

    /*
     * @dev Transfers the amount of tokens from message sender to the contract.
     * @param token Token contract address.
     * @param amount Amount of tokens to transfer.
     */
    function fundTreasury(address token, uint256 amount) external payable {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit TreasuryDeposit(msg.sender, amount, token);
    }

    /**
     * @dev Grants the recipient the amount of tokens from the treasury.
     * @param roundNumber The round number.
     * @param recipient The wallet address of the recipient.
     * @param proposalId The proposal id.
     * @param timestamp The timestamp when the message has signed.
     * @param amount The amount of tokens to grant.
     * @param tokenAddress The address of the token.
     * @param v The v value from the signature.
     * @param r The r value from the signature.
     * @param s The s value from the signature.
     */
    function claimGrant(
        uint256 roundNumber,
        address recipient,
        string memory proposalId,
        uint256 timestamp,
        uint256 amount,
        address tokenAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= timestamp + grantDeadline, "Timed out"); // Check if the grant deadline has passed

        bytes32 message = keccak256(
            abi.encodePacked(
                roundNumber,
                recipient,
                proposalId,
                timestamp,
                amount,
                tokenAddress
            )
        );

        require(isGrantClaimedHash[message] == false, "Grant already claimed"); // Check if grant has already been claimed
        require(isGrantClaimedId[proposalId] == false, "Grant already claimed"); // Check if grant has already been claimed

        address signer = tryRecover(message, v, r, s);
        require(signer == verifierWallet, "Not authorized"); // Check if the verifier wallet is the signer

        isGrantClaimedHash[message] = true; // Mark grant as claimed
        isGrantClaimedId[proposalId] = true; // Mark grant as claimed

        emit GrantClaimed( // Emit event
            recipient,
            amount,
            proposalId,
            roundNumber,
            msg.sender,
            block.timestamp
        );
        // transfer funds
        IERC20(tokenAddress).safeTransfer(recipient, amount); // Transfer funds
    }
}
