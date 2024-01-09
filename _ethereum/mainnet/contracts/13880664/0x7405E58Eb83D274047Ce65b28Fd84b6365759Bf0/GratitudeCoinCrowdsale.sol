// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

import "./Crowdsale.sol";

contract GratitudeCoinCrowdsale is Crowdsale {

    /**
    * @dev initializing the variable that points to the GratitudeCoin contract:
    */
    GratitudeCoinAbstract GC;

    constructor (
        address payable wallet,

        /**
        * @dev passing the token address through the migration process as an address variable
        */
        address token_address

    ) public Crowdsale(100, wallet, IERC20(token_address))

    /**
    * @dev Linking the GC variable to the gratitude coin contract:
    */
    {
        GC = GratitudeCoinAbstract(token_address);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(weiAmount >= 10000000000000000, "Minimum amount is one GRTFUL coin, or 0.01 Ethereum");
    }

    /**
    * @dev The only thing that buyTokens does extra is that it calls the function which emits a simple gratitude
    * event from the Gratitude Coin contract
    */
    function buyTokens(address beneficiary) public payable {
        super.buyTokens(beneficiary);
        GC.emitGratitudeEventSimpleFromCrowdsale(msg.sender);
    }

    /*
    @dev rewriting the _processPurchase function to point it to the transferFromCrowdsale function of the GC contract,
    which does not emit any gratitude events. That allows the crowdsale contract to control which gratitude events
    get emitted by the gratitude coin contract (via the emitGratitudeEvent family of functions of the GC contract)
    */
     function _processPurchase(address recipient, uint256 amount) internal {
         GC.transferFromCrowdsale(recipient, amount);
     }

    /**
    * @dev similar to buyTokens, only that instead of calling the function that emits a simple gratitude event from the
    * GC contract, it calls the function that emits a personalized gratitude event.
    * @param name: the name/nickname of the individual that buys the coins
    * @param gratitudeObject: what the individual above is grateful for
    * the GC contract will emit a personalized gratitude event, which will state that:
    * [name] is grateful for [gratitudeObject]
    */
    function buyTokensPersonalized(address beneficiary, string memory name, string memory gratitudeObject) public payable {
        super.buyTokens(beneficiary);
        GC.emitGratitudeEventPersonalizedFromCrowdsale(name, gratitudeObject);
    }
}

contract GratitudeCoinAbstract {
    function emitGratitudeEventSimpleFromCrowdsale(address _buyerAddress) public;
    function emitGratitudeEventPersonalizedFromCrowdsale(string memory name, string memory gratitudeObject) public;
    function transferFromCrowdsale(address recipient, uint256 amount) public;
}