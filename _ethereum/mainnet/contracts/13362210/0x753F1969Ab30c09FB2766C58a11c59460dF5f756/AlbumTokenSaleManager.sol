//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";

abstract contract AlbumTokenSaleManager {
    event SaleInitialized(
        address creator,
        uint256 tokensPerMilliEth,
        uint256 saleStart,
        uint256 saleEnd,
        uint256 numTokens
    );
    event TokenSale(address buyer, uint256 amount, uint256 paid);
    event SaleSwept(uint256 saleProceeds, uint256 amountUnsold);

    uint256 public constant MILLIETH = 1e15;

    address public immutable CREATOR;
    // Number of tokens to sell per wei (1e-18 ETH)
    uint256 public immutable TOKENS_PER_WEI;
    uint256 public immutable SALE_START;
    uint256 public immutable SALE_END;

    uint256 private saleProceeds;
    uint256 private amountUnsold;
    bool private swept;

    modifier saleOver(bool want) {
        bool isOver = block.timestamp >= SALE_END;
        require(want == isOver, "Sale state is invalid for this method");
        _;
    }

    struct TokenSaleParams {
        uint256 price;
        uint256 saleStart;
        uint256 saleEnd;
        uint256 numTokens;
    }

    constructor(address creator, TokenSaleParams memory params) {
        require(params.saleStart < params.saleEnd);
        CREATOR = creator;
        TOKENS_PER_WEI = params.price;
        SALE_START = params.saleStart;
        SALE_END = params.saleEnd;
        amountUnsold = params.numTokens;
        emit SaleInitialized(
            creator,
            params.price,
            params.saleStart,
            params.saleEnd,
            params.numTokens
        );
    }

    function getToken() public view virtual returns (IERC20 token);

    function buyTokens() public payable saleOver(false) {
        require(block.timestamp >= SALE_START, "Sale has not started yet");
        uint256 amount = msg.value * TOKENS_PER_WEI;
        require(amountUnsold >= amount, "Attempted to purchase too many tokens!");
        amountUnsold -= amount;
        getToken().transfer(msg.sender, amount);
        saleProceeds += msg.value;
        emit TokenSale(msg.sender, amount, msg.value);
    }

    // Anyone can trigger a sweep, but the proceeds always get sent to the creator.
    function sweepProceeds() public saleOver(true) {
        require(!swept, "Already swept");
        swept = true;
        payable(CREATOR).transfer(saleProceeds);
        getToken().transfer(CREATOR, amountUnsold);
        emit SaleSwept(saleProceeds, amountUnsold);
    }

    function getTokenSaleData()
        public
        view
        returns (
            address creator,
            uint256 tokensPerWei,
            uint256 saleStart,
            uint256 saleEnd,
            uint256 _saleProceeds,
            uint256 _amountUnsold,
            bool _swept
        )
    {
        return (
            CREATOR,
            TOKENS_PER_WEI,
            SALE_START,
            SALE_END,
            saleProceeds,
            amountUnsold,
            swept
        );
    }
}
