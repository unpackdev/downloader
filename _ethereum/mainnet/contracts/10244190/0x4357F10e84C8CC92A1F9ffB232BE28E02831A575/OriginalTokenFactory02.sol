pragma solidity ^0.6.8;

// import "./console.sol";
import "./IERC20.sol";

import "./OriginalDropToken02.sol";

contract OriginalTokenFactory02 {

    function createToken(
        string memory name,
        string memory symbol,
        address minter,
        uint256 supplyStart,
        uint256 supplyCap
    ) public returns (OriginalDropToken02) {
        OriginalDropToken02 newToken = new OriginalDropToken02(
            name,
            symbol,
            minter,
            supplyStart,
            supplyCap
        );

        return newToken;
    }

}
