// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./VRFConsumerBase.sol";
import "./ERC721.sol";
import "./CurrentTime.sol";

contract Coupon is Ownable, VRFConsumerBase, CurrentTime {
    mapping(uint256 => bool) internal redemptions;

    uint256 internal constant REBATE_AMOUNT = 20000000000000000;
    uint256 internal constant MINT_FLOOR = 40000000000000000;
    uint256 public currentRebate;

    uint256 public promotionStart;
    uint256 public promotionEnd;
    address public cryptorchidsERC721;

    uint256 public pot;
    address[] internal drawingEntries;
    bytes32 internal randomWinnerRequestId;
    bool public winnerRequested;
    address public winner;

    bytes32 internal keyHash;
    uint256 internal vrfFee;
    address public VRFCoordinator;
    address public LinkToken;

    constructor(
        address cryptorchidsAddress,
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyhash
    ) public payable VRFConsumerBase(_VRFCoordinator, _LinkToken) {
        VRFCoordinator = _VRFCoordinator;
        LinkToken = _LinkToken;
        keyHash = _keyhash;
        vrfFee = 2000000000000000000; // 2 LINK
        cryptorchidsERC721 = cryptorchidsAddress;
        promotionStart = block.timestamp;
        promotionEnd = 1622520000;
        currentRebate = REBATE_AMOUNT;
    }

    /** Public function for whether the promotion is open. The promotion is only
     * open if the contract balance is greater than the currentRebate. Displayed
     * on CryptOrchids nursery for transparency.
     * @dev
     * @return bool Whether promotion is open for entries.
     */
    function promotionOpen() public view returns (bool) {
        if (currentTime() > promotionEnd) return false;
        uint256 balance = address(this).balance;
        if (pot > balance.add(currentRebate)) return false;
        if (currentRebate > balance) return false;

        return true;
    }

    /** Check rebate value and eligible tokens. Tokens are valid if they are planted
     * after this contract is deployed, alive, and not yet redeemed.
     * @dev calls public functions on the CryptOrchids contract to build
     * an array of eligible token IDs and a rebate amount.
     * @return eligibleTokens uint256[] Uncompacted array of 0s and eligible token IDs
     * @return rebateAmount uint256 Eligible tokens * currentRebate
     */
    function checkEligibility() public view returns (uint256[] memory eligibleTokens, uint256 rebateAmount) {
        uint256 tokenCount = ERC721(cryptorchidsERC721).balanceOf(msg.sender);
        eligibleTokens = new uint256[](tokenCount);
        uint256 safeBal = safeBalance();
        for (uint256 index = 0; index < tokenCount; index++) {
            uint256 tokenId = ERC721(cryptorchidsERC721).tokenOfOwnerByIndex(msg.sender, index);
            if (redemptions[tokenId] == true) continue;
            bool flowering = ERC721(cryptorchidsERC721).flowering(tokenId);
            if (!flowering) continue;

            (, uint256 plantedAt, , ) = ERC721(cryptorchidsERC721).getTokenMetadata(tokenId);
            uint256 rebate = tokenRebate(tokenId);

            if (plantedAt > promotionStart && rebateAmount + rebate <= safeBal) {
                eligibleTokens[index] = tokenId;
                rebateAmount += rebate;
            }
        }

        return (eligibleTokens, rebateAmount);
    }

    /** Claim ETH for valid tokens. Check for valid tokens before claming.
     * @dev calls checkEligibility and sets all eligibleTokens as redeemed.
     * Then transfers caller rebateAmount.
     */
    function redeem() public virtual returns (uint256) {
        uint256 tokenCount = ERC721(cryptorchidsERC721).balanceOf(msg.sender);
        uint256 safeBal = safeBalance();
        uint256 rebateAmount = 0;

        for (uint256 index = 0; index < tokenCount; index++) {
            uint256 tokenId = ERC721(cryptorchidsERC721).tokenOfOwnerByIndex(msg.sender, index);
            if (redemptions[tokenId] == true) continue;

            uint256 rebate = tokenRebate(tokenId);
            if (rebateAmount + rebate > safeBal) break;

            bool flowering = ERC721(cryptorchidsERC721).flowering(tokenId);
            if (!flowering) continue;

            (, uint256 plantedAt, , ) = ERC721(cryptorchidsERC721).getTokenMetadata(tokenId);
            if (plantedAt < promotionStart) continue;

            rebateAmount += rebate;
            redemptions[tokenId] = true;
        }

        require(rebateAmount > 0, "Unpayable");
        payable(msg.sender).transfer(rebateAmount);

        return rebateAmount;
    }

    /** Redeem tokens for entries in drawing.
     * @dev Adds address to drawingEntries, increments entriesCount, and
     * increases pot for each eligible token, while marking each token redeemed.
     */
    function enter() public virtual {
        uint256 tokenCount = ERC721(cryptorchidsERC721).balanceOf(msg.sender);
        uint256 safeBal = safeBalance();
        uint256 rebateAmount = 0;

        for (uint256 index = 0; index < tokenCount; index++) {
            uint256 tokenId = ERC721(cryptorchidsERC721).tokenOfOwnerByIndex(msg.sender, index);
            if (redemptions[tokenId] == true) continue;

            uint256 rebate = tokenRebate(tokenId);
            if (rebateAmount + rebate > safeBal) break;

            bool flowering = ERC721(cryptorchidsERC721).flowering(tokenId);
            if (!flowering) continue;

            (, uint256 plantedAt, , ) = ERC721(cryptorchidsERC721).getTokenMetadata(tokenId);
            if (plantedAt < promotionStart) continue;

            rebateAmount += rebate;
            redemptions[tokenId] = true;
            drawingEntries.push(msg.sender);
        }

        pot += rebateAmount;
    }

    /** Current rebate amount for new, mintable token. Based on CryptOrchids current price,
     * the ramping rebate is intended to address the regrettable FOMO ramp pricing.
     * Starts at 0.02ETH, and increases with inverse correlation to price ramp to
     * offer effectively straight 0.04 ETH for seeds.
     * @dev calls CryptOrchids.currentPrice and finds difference with MINT_FLOOR to return rebate.
     */
    function setCurrentRebate() public {
        uint256 currentPrice = ERC721(cryptorchidsERC721).currentPrice();

        if (currentPrice == MINT_FLOOR) {
            currentRebate = REBATE_AMOUNT;
            return;
        }

        currentRebate = currentPrice - MINT_FLOOR;
    }

    /** Redeemable rebate amount for existing token. Based on the price the token was sold at,
     * this prevents a seed holder from redeeming a seed for more than it was purchased for.
     * @dev Copies currentPrice and returns rebate amount for tokenId
     */
    function tokenRebate(uint256 tokenId) public pure returns (uint256) {
        if (tokenId > 9900) {
            return 1000000000000000000 - MINT_FLOOR; // 9900+: 0.960 ETH
        } else if (tokenId > 9500) {
            return 640000000000000000 - MINT_FLOOR; // 9500-9500:  0.60 ETH
        } else if (tokenId > 7500) {
            return 320000000000000000 - MINT_FLOOR; // 7500-9500:  0.28 ETH
        } else if (tokenId > 3500) {
            return 160000000000000000 - MINT_FLOOR; // 3500-7500:  0.12 ETH
        } else if (tokenId > 1500) {
            return 80000000000000000 - MINT_FLOOR; // 1500-3500:  0.04 ETH
        } else if (tokenId > 500) {
            return 60000000000000000 - MINT_FLOOR; // 500-1500:   0.02 ETH
        } else {
            return REBATE_AMOUNT; // 0 - 500     0.02 ETH
        }
    }

    /** Current count of rebates available as determined by safeBalance and currentRebate
     */
    function rebatesAvailable() public view returns (uint256) {
        return SafeMath.div(safeBalance(), currentRebate);
    }

    /** Current amount availble for refund or to be staked in raffle.
     */
    function safeBalance() internal view returns (uint256) {
        return (address(this).balance).sub(pot);
    }

    /** Current amount availble for refund or to be staked in raffle.
     */
    function drawingEntriesCount() public view returns (uint256) {
        return drawingEntries.length;
    }

    /** Current amount availble for refund or to be staked in raffle.
     */
    function addressEntriesCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 index = 0; index < drawingEntries.length; index++) {
            if (drawingEntries[index] == msg.sender) {
                count += 1;
            }
        }
        return count;
    }

    function selectWinner(uint256 userProvidedSeed) public virtual {
        require(currentTime() > promotionEnd, "COC:wW:promotion running");
        require(randomWinnerRequestId[0] == 0, "COC:wW:winner requested");
        require(LINK.balanceOf(address(this)) >= vrfFee, "COC:sW:no LINK");

        randomWinnerRequestId = requestRandomness(keyHash, vrfFee, userProvidedSeed);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(requestId == randomWinnerRequestId, "COC:fR:invalid request ID");
        uint256 winnerIndex = SafeMath.mod(randomness, drawingEntriesCount());
        winner = drawingEntries[winnerIndex];
    }

    /** Winner may withdraw ether from the contract once the promotion is over.
     *
     */
    function withdrawWinner() public {
        require(currentTime() > promotionEnd, "COC:wW:promotion running");
        require(msg.sender == winner, "COC:wW:not winner");

        uint256 winnings = pot;
        pot = 0;

        payable(winner).transfer(winnings);
    }

    /** Owner may reset the promotion to run again.
     *
     */
    function reset(uint256 newPromotionEnd) public onlyOwner {
        require(currentTime() > promotionEnd, "COC:rst:promotion running");
        require(pot == 0, "COC:rst:winnings unclaimed");

        delete drawingEntries;

        winnerRequested = false;
        randomWinnerRequestId = bytes32(0);
        winner = address(0);

        pot = 0;
        promotionEnd = newPromotionEnd;
    }

    /** Withdraw ether from this contract once the promotion is over.
     * @dev Transfer remaining balance to owner if after promotionEnd.
     *
     */
    function withdrawUnclaimed() public onlyOwner {
        require(currentTime() > promotionEnd, "COC:wU:promotion running");
        require(pot == 0, "COC:wU:winnings unclaimed");

        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}
