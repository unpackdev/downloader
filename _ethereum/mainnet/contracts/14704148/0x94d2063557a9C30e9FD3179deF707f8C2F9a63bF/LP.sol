pragma solidity ^0.8.0;

//   LP (Literal Ponzi)
//
//  Send N eth to this contract to get N * 2 back :)
//
//  How does it work?
//  1. You send N eth (max 2 eth, we don't want whales monopolizing)
//  2. Other people send
//  3. Once N * 2 eth accrues in the contract, you get N *2 eth back, minus a 10% dev fee
//
//  Note: it's first-come-first-serve. This means every contribution is added to a queue
//  and the payouts are done by processing the queue, in order. You know...like a literal ponzi :)
//
//  FAQ:
//  1. Q: Where to trade? A: nowhere, this is not a token, you simply send eth to this contract address.
//  2. Q: Wen lock? A: this is not a token, no liquidity, no lock needed.
//  3. Q: Wen renounce? A: Maybe never, to be able to change the max contribution amount if needed. However, the owner can't do anything else so it's safu.
//  4. Q: Wen socials? A: create them and I'll join ;) Otherwise send a message (0tx plus text) to the dev wallet 0x615A2a9CDa24F20b79e3d9077068AE2C2A7D7f04
//  5. Q: Can I send more than once? A: Yes, but EACH contribution is entered in the queue, so if you contribute multiple times you get rewarded when the turn of each contribution comes.
//  6. Q: What if people stop sending? A: Then the ponzi dies, so ya better shill ya know? :) Note that any eth left in the contract will stay there forever, me (the dev) can't retrieve it (so I can't rug)
//  7. Q: There's more eth in the contract than N * 2 my contribution, why am I not getting paid out? A: Order...you need to wait your turn. Also, only 5 contributions are paid out at a time (for gas optimization), just wait until someone else contributes again.

import "./Ownable.sol";
import "./SafeMath.sol";

contract LP is Ownable {
    using SafeMath for uint256;
    uint256 maxContribution = 2 ether;

    struct Contributor {
        address addr;
        uint amount;
    }

    Contributor[] contributors;
    uint currentPayoutIndex = 0;
    address devWallet = 0x615A2a9CDa24F20b79e3d9077068AE2C2A7D7f04;

    constructor () {
    }

    function setMaxContribution(uint256 newMax) external onlyOwner() {
        maxContribution = newMax;
    }

    receive() external payable {
        require(msg.value <= maxContribution);

        contributors.push(Contributor(msg.sender, msg.value));

        for (uint i = 0; i < 5; i++) {
            uint256 balance = address(this).balance;
            Contributor storage currentContributor = contributors[currentPayoutIndex];
            uint256 payoutAmount = currentContributor.amount.mul(2);

            if (balance > payoutAmount) {
                uint256 tax = payoutAmount.mul(10).div(100);
                uint256 payout = payoutAmount - tax;

                payable(devWallet).transfer(tax);
                payable(currentContributor.addr).transfer(payout);

                currentPayoutIndex++;
            } else {
                break;
            }
        }
    }
}
