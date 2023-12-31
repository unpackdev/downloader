// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ECDSA.sol";
import "./IERC20.sol";

contract MelonClaimUpgradeable is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable,
    PausableUpgradeable
{
    using ECDSA for bytes32;

    struct Claim {
        address recipient;
        uint256 amount;
    }

    address private signerAddress;

    IERC20 public melonToken;
    uint public totalClaimed;

    mapping(address => uint) public claimedAmount;

    bytes32 private constant CLAIM_TYPEHASH =
        keccak256("Claim(address recipient,uint256 amount)");

    event NewClaim(address recipient, uint256 amount);

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __EIP712_init("MelonClaim", "1");

        _pause();
    }

    function claim(
        Claim calldata data,
        bytes calldata signature
    ) external nonReentrant whenNotPaused {
        require(_validateSigner(data, signature), "Invalid signer");
        require(msg.sender == data.recipient, "Invalid sender");
        require(data.amount > claimedAmount[data.recipient], "Nothing to claim");

        uint claimableAmount = data.amount - claimedAmount[data.recipient];
        require(
            melonToken.balanceOf(address(this)) >= claimableAmount,
            "Insufficient MELON to claim"
        );

        bool success = melonToken.transfer(data.recipient, claimableAmount);
        require(success, "Transfer failed");

        totalClaimed += claimableAmount;
        claimedAmount[data.recipient] = data.amount;

        emit NewClaim(data.recipient, claimableAmount);
    }

    function _validateSigner(
        Claim calldata data,
        bytes calldata signature
    ) private view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(CLAIM_TYPEHASH, data.recipient, data.amount)
        );
        address recoveredSignerAddress = ECDSA.recover(
            ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash),
            signature
        );

        return recoveredSignerAddress == signerAddress;
    }

    // view functions
    function getClaimDetails(
        address recipient
    )
        external
        view
        returns (
            uint totalMelonSupply,
            uint totalMelonClaimed,
            uint recipientClaimed,
            bool isPaused
        )
    {
        return (
            melonToken.balanceOf(address(this)),
            totalClaimed,
            claimedAmount[recipient],
            paused()
        );

    }

    // admin functions
    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }

    function setup(address signer, address melon) external onlyOwner {
        signerAddress = signer;
        melonToken = IERC20(melon);
    }

    function withdrawERC20(IERC20 erc20Token) external onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    function withdrawETH(address to, uint256 balance) external onlyOwner {
        payable(to).transfer(balance);
    }
}
