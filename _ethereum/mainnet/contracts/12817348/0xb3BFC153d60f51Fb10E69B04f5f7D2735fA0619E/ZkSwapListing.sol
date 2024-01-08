//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

// import "./console.sol";
import "./IZkSwap.sol";
import "./IGovernance.sol";
import "./IERC20Metadata.sol";

contract ZkSwapListing is Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;

    // evnets
    event ListingCapUpdated(address sender, uint256 newListingCap);
    event ListingFeeReceiverUpdated(
        address sender,
        address newListingFeeReceiver
    );
    event ListingFeeTokenUpdated(
        address sender,
        address newListingFeeTokenAddress,
        uint256 newListingFeeAmount
    );
    event QuoteTokenEnabled(address sender, address[] quoteTokenAddresses);
    event QuoteTokenDisabled(address sender, address[] quoteTokenAddresses);
    event TokenPairListed(address user, address quoteToken, address tradeToken);
    event ETHPairListed(address user, address tradeToken);

    uint16 constant MAX_FEE_TOKEN_ID = 32;

    uint16 constant PAIR_TOKEN_START_ID = 16384;

    // public properties
    uint256 public listingCap;
    uint256 public listingCount;

    address public listingFeeReceiver;
    address public listingFeeToken;
    uint256 public listingFeeAmount;

    // max token name limit
    uint256 public tokenNameLimit;

    // max token symbol limit
    uint256 public tokenSymbolLimit;

    // max token decimals limit
    uint8 public tokenDecimalsLimit;

    mapping(address => bool) public quoteTokenList;

    // internal properties
    IZkSwap private zkswap;
    IGovernance private governance;

    constructor(
        uint256 _listingCap,
        address _listingFeeReceiver,
        address _listingFeeToken,
        uint256 _listingFeeAmount,
        address _zkswapAddress,
        address _governanceAddress,
        uint256 _tokenNameLimit,
        uint256 _tokenSymbolLimit,
        uint8 _tokenDecimalsLimit){
        listingCap = _listingCap;

        listingFeeReceiver = _listingFeeReceiver;
        listingFeeToken = _listingFeeToken;
        listingFeeAmount = _listingFeeAmount;

        tokenNameLimit = _tokenNameLimit;
        tokenSymbolLimit = _tokenSymbolLimit;
        tokenDecimalsLimit = _tokenDecimalsLimit;

        zkswap = IZkSwap(_zkswapAddress);
        governance = IGovernance(_governanceAddress);
    }

    // setters
    function setListingCap(uint256 _listingCap) external onlyOwner {
        require(
            _listingCap >= listingCount,
            "ZSL: Listing cap should not less then current listing count"
        );
        listingCap = _listingCap;
        emit ListingCapUpdated(msg.sender, _listingCap);
    }

    function setListingFeeReceiver(address _listingFeeReceiver)
        external
        onlyOwner
    {
        require(
            _listingFeeReceiver != address(0),
            "ZSL: Invalid listing fee receiver"
        );
        listingFeeReceiver = _listingFeeReceiver;
        emit ListingFeeReceiverUpdated(msg.sender, _listingFeeReceiver);
    }

    function setListingFeeToken(
        address _listingFeeToken,
        uint256 _listingFeeAmount
    ) external onlyOwner {
        require(
            _listingFeeToken != address(0),
            "ZSL: invalid fee token address"
        );

        listingFeeToken = _listingFeeToken;
        listingFeeAmount = _listingFeeAmount;

        emit ListingFeeTokenUpdated(
            msg.sender,
            _listingFeeToken,
            _listingFeeAmount
        );
    }

    function enableQuoteToken(address[] calldata _quoteTokenAddresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _quoteTokenAddresses.length; i++) {
            address quoteToken =  _quoteTokenAddresses[i];
            uint256 quoteTokenId = governance.tokenIds(quoteToken);
            require(quoteTokenId != 0 && quoteTokenId < MAX_FEE_TOKEN_ID, "invalid quote token");

            quoteTokenList[quoteToken] = true;
        }

        emit QuoteTokenEnabled(msg.sender, _quoteTokenAddresses);
    }

    function disableQuoteToken(address[] calldata _quoteTokenAddresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _quoteTokenAddresses.length; i++) {
            quoteTokenList[_quoteTokenAddresses[i]] = false;
        }
        emit QuoteTokenDisabled(msg.sender, _quoteTokenAddresses);
    }

    // external functions
    function requestListing(address quoteToken, address tradeToken) external {
        require(quoteTokenList[quoteToken], "ZSL: Invalid quote token");
        require(listingCount < listingCap, "ZSL: Listing count exceeds limit");
        listingCount += 1;

        uint16 tokenId = governance.tokenIds(tradeToken);
        if (tokenId == 0) {
            //check tradeToken is erc20 token
            require(checkERC20Metadata(tradeToken), "ZSL: ERC20 token metadata mismatch");
            governance.addToken(tradeToken);
        }
        require(tokenId < PAIR_TOKEN_START_ID, "ZSL: Cannot use LP token create pair again");
        require(
            governance.tokenIds(quoteToken) != 0,
            "ZSL: Quote token is not in whitelist"
        );

        if (listingFeeAmount > 0) {
            ERC20(listingFeeToken).safeTransferFrom(
                msg.sender,
                listingFeeReceiver,
                listingFeeAmount
            );
        }

        zkswap.createPair(quoteToken, tradeToken);

        emit TokenPairListed(msg.sender, quoteToken, tradeToken);
    }

    function requestListingETH(address tradeToken) external {
        require(listingCount < listingCap, "ZSL: Listing count exceeds limit");
        listingCount += 1;

        uint16 tokenId = governance.tokenIds(tradeToken);
        if (tokenId == 0) {
            //check tradeToken is erc20 token
            require(checkERC20Metadata(tradeToken), "ZSL: ERC20 token metadata mismatch");
            governance.addToken(tradeToken);
        }
        require(tokenId < PAIR_TOKEN_START_ID, "ZSL: Cannot use LP token create pair again");

        if (listingFeeAmount > 0) {
            ERC20(listingFeeToken).safeTransferFrom(
                msg.sender,
                listingFeeReceiver,
                listingFeeAmount
            );
        }

        zkswap.createETHPair(tradeToken);

        emit ETHPairListed(msg.sender, tradeToken);
    }

     function checkERC20Metadata(address token) internal view returns(bool) {
        IERC20Metadata erc20Token = IERC20Metadata(token);
        uint256 nameLength = (bytes(erc20Token.name())).length;
        require((nameLength > 0 && nameLength <= tokenNameLimit) || tokenNameLimit == 0, "ZSL: Token name is incorrect");
        uint256 symbolLength = (bytes(erc20Token.symbol())).length;
        require((symbolLength > 0 && symbolLength <= tokenSymbolLimit) || tokenSymbolLimit == 0, "ZSL: Token symbol is incorrect");
        uint8 decimals = erc20Token.decimals();
        require((decimals >= 0 && decimals <= tokenDecimalsLimit) || tokenDecimalsLimit == 0, "ZSL: Token decimals is incorrect");
        return true;
    }

    function setTokenNameLimit(uint256 newLimit) external onlyOwner {
        tokenNameLimit = newLimit;
    }

    function setTokenSymbolLimit(uint256 newLimit) external onlyOwner {
        tokenSymbolLimit = newLimit;
    }

    function setTokenDecimalsLimit(uint8 newLimit) external onlyOwner {
        tokenDecimalsLimit = newLimit;
    }

}
