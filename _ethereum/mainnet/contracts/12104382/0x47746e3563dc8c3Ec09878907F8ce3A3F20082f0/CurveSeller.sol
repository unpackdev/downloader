// SPDX-License-Identifier: MIT


pragma solidity ^0.7.0;

//import "./console.sol";
import "./MahinNFT.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./SafeMath.sol";


// Sell NFTs using a step function.
contract CurveSeller is Ownable {
    using SafeMath for uint256;

    // Sells these token ids in ascending order
    uint[] public idsToSell;
    uint256 public beneficiarySplit = 75;

    uint[2][6] public steps = [
        [5, 0.15 ether],
        [10, 0.3 ether],
        [15, 0.5 ether],
        [10, 0.65 ether],
        [7, 0.75 ether],
        [3, 1 ether]
    ];

    bool public enabled = false;

    uint256 public numSold = 0;

    MahinNFT public nftContract;

    constructor (address mahinAddress, uint[] memory _idsToSell) {
        nftContract = MahinNFT(mahinAddress);
        idsToSell = _idsToSell;
    }

    function withdraw() public onlyOwner {
        address payable owner = payable(owner());
        owner.transfer(address(this).balance);
    }

    function enable(bool _enable) public onlyOwner {
        enabled = _enable;
    }

    function numRemaining() public view returns (uint256) {
        return idsToSell.length;
    }

    function purchase() public virtual payable returns (uint256 _tokenId) {
        require(idsToSell.length > 0, "sold out");
        require(enabled, "disabled");

        uint256 mintPrice = getPriceToMint(0);
        require(msg.value >= mintPrice, "not enough eth");

        // Cut for the beneficiary
        address beneficiary = nftContract.beneficiary();
        if (beneficiary != address(0)) {
            uint256 toCharity = mintPrice.mul(beneficiarySplit).div(100);
            payable(beneficiary).transfer(toCharity);
        }

        uint idx = block.timestamp % idsToSell.length;
        uint256 tokenId = idsToSell[idx];

        // delete the element - move the last element to the deleted slot
        idsToSell[idx] = idsToSell[idsToSell.length-1];
        idsToSell.pop();

        numSold = numSold+1;

        // Send the token to the buyer
        nftContract.mintToken(tokenId, msg.sender);

        // Send back remainder if overpaid
        if (msg.value - mintPrice > 0) {
            msg.sender.transfer(msg.value - mintPrice);
        }

        return tokenId;
    }

    function getPriceToMint(uint256 idx) public virtual view returns (uint256) {
        uint256 target = numSold + idx;
        uint256 count = 0;
        for (uint s=0; s<steps.length; s++) {
            count = count + steps[s][0];
            if (count > target) {
                return steps[s][1];
            }
        }
        revert("failed-pr");
    }
}
