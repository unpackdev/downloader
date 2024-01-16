// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Ownable.sol";
import "./ERC20.sol";

contract CYVO is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1_500_000_000_000_000_000_000_000_000;

    constructor(
        address _Private,
        address _Public,
        address _Exchange_Listing,
        address _Staking,
        address _Airdrop_Referal_NewAccount,
        address _Bounty,
        address _Treasury,
        address _Research_And_Development,
        address _Founders_And_Management,
        address _Advisory_Panel
    ) ERC20("CYVO", "CYVO") {
        _mint(_Private, 285_000_000 * (10**decimals()));
        _mint(_Public, 45_000_000 * (10**decimals()));
        _mint(_Exchange_Listing, 135_000_000 * (10**decimals()));
        _mint(_Staking, 150_000_000 * (10**decimals()));
        _mint(_Airdrop_Referal_NewAccount, 45_000_000 * (10**decimals()));
        _mint(_Bounty, 15_000_000 * (10**decimals()));
        _mint(_Treasury, 300_000_000 * (10**decimals()));
        _mint(_Research_And_Development, 225_000_000 * (10**decimals()));
        _mint(_Founders_And_Management, 225_000_000 * (10**decimals()));
        _mint(_Advisory_Panel, 75_000_000 * (10**decimals()));
    }
}
