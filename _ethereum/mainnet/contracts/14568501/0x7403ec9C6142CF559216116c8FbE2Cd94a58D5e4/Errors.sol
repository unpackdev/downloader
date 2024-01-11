// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.4 <0.9.0;

library Errors {
    error DuplicateTransaction(bytes32 nonce); // 0xa7a438c2e9b8d689a3b48a831a0258ba1fa539c92e29aab202fe2c29ee761dce
    error TokensUnavailable(); // 0x1326899a606941e9eed5cde118a51228eb5aabf5caa3da44ac6ff605b6bf2446
    error AlreadyUpgraded(uint256 tokenID); // 0x9e56772c0c26c28ce833d043d8a231a1a45c73a97c1c5e101a53ac22834f1c13
    error AlreadySacrificed(uint256 tokenID); // 0x80523705138e93a217915d6490c236da17e2c6d4e1bed1413123654d09bd7557
    error AttemptingToUpgradeSacrificedToken(uint256 tokenID); //0x567ee3910780d977ad5ddd4130f487a09c72fa9d805e42129dc708a2e4babf03
    error UnownedToken(uint256 tokenID); //0xe5af3d32f88712fbb772e57faa794e06f80ba3d6ce6758da363f5175e24e9eca
    error InvalidSignature(); //0x8baa579fce362245063d36f11747a89dd489c54795634fc673cc0e0db51fedc5

    error UserPermissions(); //0xcb5b8a6e376a1343733219cdf2aadf9268ffc6cbc33f46bfd405c0e983779fb6
    error AddressTarget(address target); // 0xa48945797221314954fa81e304ea23cb16add7280a4507d21c1d21cdf7de487c
    error NotInitialized(); // 0x87138d5c8c2e77cb9f25c07b03277aad63d22f6a05255580ec55d2c21666e734
    error InsufficientBalance(uint256 available, uint256 required); // 0xcf4791818fba6e019216eb4864093b4947f674afada5d305e57d598b641dad1d
    error NotAContract(); // 0x09ee12d5e890f67fbc6b54352f3db54c0ae59044f71a515db1d8d03c55e89c18
    error UnsignedOverflow(uint256 value); // 0x3eb53d398b5dd6b3dae1ac02b21577e4148b282c5c6fb6cbd86da57b7f26a9d9
    error OutOfRange(uint256 value); // 0x6f2fb69e4970df9fe603d5ff18c40a67b1c3c5cc44b1718303e193c190e644d5
    error PaymentFailed(uint256 amount); // 0x1e67017f24b5d36ac2cf76ebc35ecc3941a2da5fdbb5db811586a41c651e24f7
    error Paused(); // 0x9e87fac88ff661f02d44f95383c817fece4bce600a3dab7a54406878b965e752
}
