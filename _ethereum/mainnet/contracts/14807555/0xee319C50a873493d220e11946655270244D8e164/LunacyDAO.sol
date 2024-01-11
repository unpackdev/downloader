// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC20.sol";

import "./TerraClaimable.sol";

contract LunacyDAO is ERC20, TerraClaimable {
    address immutable minter;

    mapping(string => bool) public hasClaimed;

    mapping(address => uint256) public leftToClaim;
    mapping(address => uint256) public initiallyClaimed;

    bool public claiming;

    error Unauthorized();
    error ClaimingNotEnabled();
    error TooEarlyToClaimRemainder();
    error NothingLeftToClaim();
    error AlreadyClaimed();
    error CannotClaim();

    event Claim(address indexed to, uint256 amount);

    constructor(address _minter) ERC20("LunacyDAO", "LUNAC", 18) {
        minter = _minter;

        _mint(msg.sender, 420_000_000_000e18);
    }

    function enableClaiming() external {
        if (msg.sender != minter) revert Unauthorized();
        claiming = true;
    }

    function claim(
        uint256 amount,
        bytes memory _minterSignature,
        bytes memory _terraSignature,
        bytes memory _terraPubKey
    ) external {
        if (!claiming) revert ClaimingNotEnabled();
        string memory terraAddress = addressFromPublicKey(_terraPubKey);

        if (hasClaimed[terraAddress]) revert AlreadyClaimed();
        if (!canClaim(_terraSignature, _terraPubKey)) revert CannotClaim();

        bytes32 hashedMessage = sha256(abi.encodePacked(msg.sender, amount, terraAddress));
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_minterSignature);
        address recoveredAddress = ecrecover(hashedMessage, v, r, s);

        if (recoveredAddress == address(0)) revert InvalidSignature();
        if (recoveredAddress != minter) revert InvalidAddress();

        uint256 mintAmount = (amount * 33) / 100;
        hasClaimed[terraAddress] = true;
        leftToClaim[msg.sender] = amount - mintAmount;
        initiallyClaimed[msg.sender] = block.timestamp;
        _mint(msg.sender, mintAmount);

        emit Claim(msg.sender, mintAmount);
    }

    function claimRemainder() external {
        uint256 mintAmount = leftToClaim[msg.sender];
        if (mintAmount == 0) revert NothingLeftToClaim();
        if (block.timestamp - initiallyClaimed[msg.sender] < 7 days) revert TooEarlyToClaimRemainder();

        leftToClaim[msg.sender] = 0;
        _mint(msg.sender, mintAmount);

        emit Claim(msg.sender, mintAmount);
    }
}
