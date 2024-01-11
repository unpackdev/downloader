// SPDX-License-Identifier: MIT


pragma solidity ^0.7.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./MahinNFT.sol";
import "./MintDateRegistry.sol";
//import "./console.sol";


contract FixedPriceSeller is Ownable {
    using SafeMath for uint256;

    // Sells these token ids in ascending order
    uint[] public idsToSell;
    uint256 public beneficiarySplit = 75;
    uint256 public mintPrice = 0.4 ether;
    bool public enabled = false;
    uint256 public numSold = 0;
    MahinNFT public nftContract;
    MintDateRegistry public mintDateRegistry;
    address public treasury;

    constructor (address mahinAddress, address mintDateRegistryAddress, uint[] memory _idsToSell) {
        nftContract = MahinNFT(mahinAddress);
        mintDateRegistry = MintDateRegistry(mintDateRegistryAddress);
        idsToSell = _idsToSell;
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function setIdsToSell(uint[] memory _idsToSell) public onlyOwner {
        idsToSell = _idsToSell;
    }

    function enable(bool _enable) public onlyOwner {
        enabled = _enable;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function numRemaining() public view returns (uint256) {
        return idsToSell.length;
    }

    function purchase() public virtual payable returns (uint256 _tokenId) {
        require(idsToSell.length > 0, "sold out");
        require(enabled, "disabled");
        require(treasury != address(0), "treasury not set");

        require(msg.value >= mintPrice, "not enough eth");

        // Cut for the beneficiary
        address beneficiary = nftContract.beneficiary();
        uint256 toCharity = 0;
        if (beneficiary != address(0)) {
            toCharity = mintPrice.mul(beneficiarySplit).div(100);
            payable(beneficiary).transfer(toCharity);
        }

        // remainder to treasury
        uint256 remainder = msg.value.sub(toCharity);
        if (remainder > 0) {
            payable(treasury).transfer(remainder);
        }

        uint idx = block.timestamp % idsToSell.length;
        uint256 tokenId = idsToSell[idx];

        // Delete the element - move the last element to the deleted slot
        idsToSell[idx] = idsToSell[idsToSell.length-1];
        idsToSell.pop();

        numSold = numSold+1;

        // Send the token to the buyer
        nftContract.mintToken(tokenId, msg.sender);

        mintDateRegistry.setMintDateForToken(tokenId, block.timestamp);

        return tokenId;
    }
}
