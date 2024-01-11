//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./draft-EIP712.sol";
import "./DecimalMath.sol";

abstract contract TOCBaseSale is Ownable, ERC721Holder, EIP712 {
    using DecimalMath for uint256;

    /// @notice event emitted when buyer purchase nft
    event Purchased(
        address indexed seller,
        address indexed buyer,
        uint256 indexed auctionId,
        uint256 price
    );

    /// @notice event emitted when seller cancel the active sale
    event SaleCancelled(uint256 indexed saleId);

    /// @notice event emitted when owner updates treasury and fee amount
    event TreasuryUpdated(address treasury, uint256 fee);

    /// @notice structure for treasury
    struct Treasury {
        /// @notice treasury address
        address treasury;
        /// @notice fee amount (DENOMINATOR = 1000, accepting 1 decimal)
        uint256 fee;
    }

    /// @notice TOC NFT
    IERC721 public tocNFT;

    /// @notice treasury information
    Treasury public treasury;

    /// @notice the last sale id
    uint256 public lastSaleId;

    constructor(address toc) EIP712("TOCBaseSale", "1.0") {
        require(toc != address(0), "Sale: INVALID_TOC_TOKEN");
        tocNFT = IERC721(toc);
    }

    function setTreasury(address _treasury, uint256 _fee) external onlyOwner {
        require(_treasury != address(0), "Sale: INVALID_TREASURY");
        require(_fee.isLessThanAndEqualToDenominator(), "Sale: FEE_OVERFLOWN");
        treasury = Treasury(_treasury, _fee);
        emit TreasuryUpdated(_treasury, _fee);
    }
}
