pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Token.sol";
import "./NFT.sol";

contract Redeem {
    using SafeMath for uint256;

    Token public token;
    NFT public nft;
    uint256[] public prices;
    uint256[] public limits;

    constructor(
        Token token_,
        NFT nft_,
        uint256[] memory prices_,
        uint256[] memory limits_
    ) {
        token = token_;
        nft = nft_;
        require(limits_.length == prices_.length, "INVALID_PARAMS_LENGTH");
        prices = prices_;
        limits = limits_;
    }

    function redeem(uint256 id, uint256 amount) public {
        require(id < prices.length, "INVALID_ID");
        require(amount > 0, "INVALID_AMOUNT");
        uint256 limit = limits[id];
        if (limit != 0) {
            require(nft.seriesMinted(id) + amount <= limit, "LIMIT_REACHED");
        }

        uint256 price = prices[id];
        uint256 cost = price.mul(amount);

        token.burn(msg.sender, cost);

        for (uint256 i = 0; i < amount; i++) {
            nft.mint(msg.sender, id);
        }
    }

    // Return the number of NFTs minted for each series.
    function seriesMinted() public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](prices.length);
        for (uint256 i = 0; i < balances.length; i++) {
            balances[i] = nft.seriesMinted(i);
        }
        return balances;
    }
}
