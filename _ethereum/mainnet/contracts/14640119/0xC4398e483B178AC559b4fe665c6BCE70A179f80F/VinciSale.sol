// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./TokenTimelock.sol";

contract VinciSale is Ownable {
    IERC20 public exchangeAsset;
    IERC20 public vinciContract;
    uint256 public vinciPrice;
    uint256 public releaseTime;

    event TokenLocked(
        address indexed beneficiary,
        uint256 amount,
        uint256 releaseTime,
        address contractAddress
    );

    constructor(
        IERC20 exchangeAsset_,
        IERC20 vinciContract_,
        uint256 vinciPrice_,
        uint256 releaseTime_,
        address owner_
    ) {
        exchangeAsset = exchangeAsset_;
        vinciContract = vinciContract_;
        vinciPrice = vinciPrice_;
        releaseTime = releaseTime_;
        transferOwnership(owner_);
    }

    /**
     * @dev Buy vinci tokens from this sales contract. Only a multiple of
     * tokens can be bought.
     *
     * The amount is specifed in tokens (10**18 amount). If the release time
     * of this contract is in the future, it will create a TokenTimelock
     * contract. Otherwise it will immediately send out the tokens.
     *
     * Requirements:
     *
     * - Caller needs to own enough exchange Asset
     * - Enough Vinci tokens need to still be in the contract.
     */
    function buy(uint256 numberVinciTokens) public {
        uint256 amountVinci = numberVinciTokens * 10**18;
        uint256 cost = vinciPrice * numberVinciTokens;

        require(
            vinciContract.balanceOf(address(this)) >= amountVinci,
            "The contract does not hold enough VINCI to sell"
        );
        require(
            exchangeAsset.balanceOf(msg.sender) >= cost,
            "Sender doesn't have enough to pay"
        );

        exchangeAsset.transferFrom(msg.sender, address(this), cost);

        if (releaseTime <= block.timestamp) {
            // No timelock
            vinciContract.transfer(_msgSender(), amountVinci);
        } else {
            TokenTimelock token_timelock_contract = new TokenTimelock(
                vinciContract,
                _msgSender(),
                releaseTime
            );

            emit TokenLocked(
                _msgSender(),
                amountVinci,
                releaseTime,
                address(token_timelock_contract)
            );

            vinciContract.transfer(
                address(token_timelock_contract),
                amountVinci
            );
        }
    }

    /**
     * @dev Retrieve proceeds from sale
     */
    function getProceeds() public onlyOwner {
        uint256 amount = exchangeAsset.balanceOf(address(this));
        exchangeAsset.transfer(owner(), amount);
    }

    /**
     * @dev Retrieve remaining vinci
     */
    function getVinci() public onlyOwner {
        uint256 amount = vinciContract.balanceOf(address(this));
        vinciContract.transfer(owner(), amount);
    }
}
