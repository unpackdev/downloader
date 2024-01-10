// SPDX-License-Identifier: NONE
pragma solidity 0.7.6;

import "./Ownable.sol";
import "./Math.sol";
import "./IBalancerTrader.sol";
import "./AMPLRebaser.sol";
import "./StakingERC721.sol";
/*
Definitions and explanations: 
- Sell Threshold: Only sell AMPL when total AMPL amount is > 40,000
- Start Percent: At the beginning 25% of new AMPL supply will be sold for ETH
- End Percent: At maximum 80% of new AMPL supply will be sold for ETH
- Two ERC721 tokens will be accepted: Zeus and Apollo 
- AMPL will be sold for ETH utilizing the Balancer trading contract 
- The amount of AMPL to sell is dependent on the amount of AMPL in in the vault and is controlled by the CAP constant

*/
contract Pioneer1Vault is StakingERC721, AMPLRebaser, Ownable {
    using Math for uint256;

    uint256 public constant SELL_THRESHOLD = 40000 * 10**9;
    uint256 public constant START_PERCENT = 25;
    uint256 public constant END_PERCENT = 80;
    uint256 public constant CAP = 800000 * 10**9;
    IBalancerTrader public trader;

    constructor(
        IERC721 tokenA,
        IERC721 tokenB,
        IERC20 ampl
        )
    StakingERC721(tokenA, tokenB, ampl)
    AMPLRebaser(ampl)
    Ownable() {
    }

    receive() external payable { }

    function setTrader(IBalancerTrader _trader) external onlyOwner() {
        require(address(_trader) != address(0), "Pioneer1Vault: invalid trader");
        trader = _trader;
    }

    function _rebase(uint256 old_supply, uint256 new_supply, uint256, uint256 minimalExpectedETH) internal override {
        require(address(trader) != address(0), "Pioneer1Vault: trader not set");
        uint256 new_balance = ampl_token.balanceOf(address(this));
        require(new_balance > SELL_THRESHOLD, "Pioneer1Vault: Threshold isnt reached yet"); //needs to be checked or else _toSell fails
        if(new_supply > old_supply) {
            //only for positive rebases
            uint256 change_ratio_18digits = old_supply.mul(10**18).divDown(new_supply);
            uint256 surplus = new_balance.sub(new_balance.mul(change_ratio_18digits).divDown(10**18));
            uint256 to_sell = _toSell(surplus);
            ampl_token.approve(address(trader), to_sell);

            trader.sellAMPLForEth(to_sell, minimalExpectedETH);
            //this checks that after the sale we're still above threshold
            require(ampl_token.balanceOf(address(this)) >= SELL_THRESHOLD, "Pioneer1Vault: Threshold isnt reached yet");
            stakingContractEth.distribute{value : address(this).balance}(0, address(this));
        }
    }

    function _toSell(uint256 amount) internal view returns (uint256) {
        uint256 ampl_balance = ampl_token.balanceOf(address(this));
        uint256 percentage = (END_PERCENT - START_PERCENT).mul(Math.min(ampl_balance, CAP).sub(SELL_THRESHOLD)).divDown(CAP.sub(SELL_THRESHOLD)) + START_PERCENT;
        return percentage.mul(amount).divDown(100);
    }

}
