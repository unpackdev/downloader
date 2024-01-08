//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.3;

import "./ERC20Burnable.sol";

// import "./console.sol";

// Uses quadratic bonding curve integral formula from
// https://blog.relevant.community/how-to-make-bonding-curves-for-continuous-token-models-3784653f8b17
abstract contract QuadraticBondingCurve is ERC20Burnable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 scaling,
        uint256 supplyCap
    ) ERC20(name, symbol) {
        SCALING = scaling;
        SUPPLY_CAP = supplyCap;
        // Mint total supply to the contract's own address. 
        // The bonding curve sells tokens out of this pool, instead of increasing token
        // supply by minting as most bonding curves do. This makes no difference to price,
        // but it means the total supply on sites such as Etherscan reflect the true total supply.
        _mint(address(this), supplyCap);
    }

    uint256 public SUPPLY_CAP;
    uint256 public SCALING;

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH transfer failed");
    }

    function quoteBuyRaw(uint256 tokensToBuy, uint256 currentTokensBought)
        public
        view
        returns (uint256)
    {
        uint256 newTokensBought = currentTokensBought + tokensToBuy;

        // How much is the pool's ether balance
        uint256 currentPoolBalance =
            (currentTokensBought * currentTokensBought * currentTokensBought) / 3;

        // How much the pool's ether balance will be after buying
        uint256 newPoolBalance =
            (newTokensBought * newTokensBought * newTokensBought) / 3;

        // How much it costs to buy tokensToBuy from the bonding curve
        uint256 numEther = newPoolBalance - currentPoolBalance;

        // Scale by 1e18^2 (ether precision) to cancel out exponentiation
        // Scales the number by a constant to get to the level we want
        // We add one wei to absorb rounding error
        return ((numEther / (1e18 * 1e18)) / SCALING) + 1;
    }

    // This function gives us the total number of tokens that are not
    // owned by the contract
    function totalBought() public view returns (uint256) {
       return SUPPLY_CAP - balanceOf(address(this));
    }

    function quoteBuy(uint256 tokensToBuy) public view returns (uint256) {
        return quoteBuyRaw(tokensToBuy, totalBought());
    }

    function buy(uint256 tokensToBuy) public payable {
        // CHECKS
        uint256 currentTokensBought = totalBought();

        require(
            currentTokensBought + tokensToBuy <= SUPPLY_CAP,
            "Supply cap exceeded, no more tokens can be bought from the curve."
        );

        uint256 numEther = quoteBuyRaw(tokensToBuy, currentTokensBought);

        require(numEther <= msg.value, "Did not send enough Ether");

        // ACTIONS

        // Give bought tokens to buyer
        _transfer(address(this), msg.sender, tokensToBuy);

        // Send dust back to caller
        safeTransferETH(msg.sender, msg.value - numEther);
    }

    function quoteSellRaw(uint256 tokensToSell, uint256 currentTokensBought)
        public
        view
        returns (uint256)
    {
        uint256 newTokensBought = currentTokensBought - tokensToSell;

        // How much the pool's ether balance
        uint256 currentPoolBalance =
            (currentTokensBought * currentTokensBought * currentTokensBought) / 3;

        // How much the pool's ether balance will be after
        uint256 newPoolBalance =
            (newTokensBought * newTokensBought * newTokensBought) / 3;

        // How much you get when you sell tokensToSell to the bonding curve
        uint256 numEther = currentPoolBalance - newPoolBalance;

        // Scale by 1e18^2 (ether precision) to cancel out exponentiation
        // Scales the number by a constant to get to the level we want
        return ((numEther / (1e18 * 1e18)) / SCALING);
    }

    function quoteSell(uint256 tokensToSell) public view returns (uint256) {
        return quoteSellRaw(tokensToSell, totalBought());
    }

    function sell(uint256 tokensToSell, uint256 minEther) public payable {
        // CHECKS

        uint256 numEther = quoteSell(tokensToSell);

        require(
            numEther >= minEther,
            "Number of Ether received would be lower than minEther"
        );

        // ACTIONS

        // Take sold tokens from seller
        _transfer(msg.sender, address(this), tokensToSell);

        // Send proceeds to caller
        safeTransferETH(msg.sender, numEther);
    }
}
