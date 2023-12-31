
// SPDX-License-Identifier: MIT

/** 

Telegram: https://t.me/BoostTokenETH
Twitter: https://twitter.com/BoostTokenETH
Website: https://boostto.in

**/

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC20.sol";

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );

  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;

  function initialize(address, address) external;
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract BoostToken is ERC20, Ownable {

    uint256 constant public REWARD_WINDOW = 1 hours;
    uint256 constant public STORAGE_WINDOW = 3 hours;
    uint16 constant public MAX_BASIS_POINT  = 10_000;
    uint16 constant public SOLD_OR_TRANSFER_CLAIM_PERCENTAGE = 7500;
    uint16 constant public THIRTY_BASIS_POINT = 3_000;
    uint16 constant public TWENTY_FIVE_BASIS_POINT = 2500;
    uint16 constant public TWENTY_BASIS_POINT = 2_000;
    uint16 constant public FIFTEEN_BASIS_POINT = 1500;
    uint16 constant public TEN_BASIS_POINT = 1_000;
    uint16 constant public FIVE_BASIS_POINT = 500;
    uint16 public buyTaxRateBasisPoint;
    uint16 public sellTaxRateBasisPoint;
    uint256 public maxSellTaxLimit = 15_000_000 * 10**18;

    bool public limited; // Whether trading is limited
    bool public isTradingEnabled; // Whether trading is enabled
    bool public isTaxDisabled; // Whether taxes are disabled

    IRouter immutable public router;
    uint256 immutable public tokenClaimConstraint;
    address public pair;

    uint256 public maxTokenHolding; // Maximum token holding limit for each user
    uint256 public minTokenHolding; // Minimum token holding limit for each user
    uint256 public firstTradingEnabledTimestamp;
    uint256 public sellTax; // Tax amount paid by each user

    mapping(address => bool) private blacklistUser; // Blacklisted addresses
    mapping(address => bool) private userSoldOrTransferToken;
    mapping(address => bool) public exemptFee;
    mapping(address => uint256) public userBuyTaxAmount;
    mapping(address => uint256) public userBuyAmountInRewardWindow;

    /**
     * @dev Emitted when tokens are claimed by a recipient.
     * @param recipient The address of the recipient who claimed tokens.
     * @param amount The amount of tokens claimed by the recipient.
     */
    event TokensClaimed(address indexed recipient, uint256 amount);

    event SellTaxBasisPointChanged(uint256 basisPoint);
    event BuyTaxBasisPointChanged(uint256 basisPoint);

    modifier tradingEnabled(address sender_, address recipient_) {
        require(isTradingEnabled || exemptFee[sender_] || exemptFee[recipient_], "Trading is currently disabled.");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        bool isTradingEnabled_
    ) ERC20(name_, symbol_) {
        //! Todo Change the router address according to network.
        // main net 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        // sepolia net 0x86dcd3293C53Cf8EFd7303B57beb2a3F671dDE98
        IRouter router_ = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        address pair_ = IFactory(router_.factory()).createPair(address(this), router_.WETH());

        router = router_;
        pair = pair_;
        isTradingEnabled = isTradingEnabled_;
        isTaxDisabled = false;
        // solhint-disable-next-line not-rely-on-time
        tokenClaimConstraint = block.timestamp + 18 days;
        exemptFee[msg.sender] = true;
        exemptFee[address(this)] = true;

        _mint(msg.sender, totalSupply_);
    }

    function setIsTradingEnabled(bool status_) external onlyOwner {
        isTradingEnabled = status_;
        if((firstTradingEnabledTimestamp == uint256(0)) && (status_ == true)) {
            firstTradingEnabledTimestamp = block.timestamp;
        }
    }

    function setBuyTaxRateBasisPoint(uint16 newBuyTaxRateBasisPoint_) external onlyOwner {
        require(newBuyTaxRateBasisPoint_ <= MAX_BASIS_POINT, "Claim percentage exceeds maximum allowed value.");
        buyTaxRateBasisPoint = newBuyTaxRateBasisPoint_;

        emit BuyTaxBasisPointChanged(newBuyTaxRateBasisPoint_);
    }    
    function setSellTaxRateBasisPoint(uint16 newSellTaxRateBasisPoint_) external onlyOwner {
        require(newSellTaxRateBasisPoint_ <= MAX_BASIS_POINT, "Claim percentage exceeds maximum allowed value.");
        sellTaxRateBasisPoint = newSellTaxRateBasisPoint_;

        emit SellTaxBasisPointChanged(newSellTaxRateBasisPoint_);
    }

    function setBlacklist(address address_, bool isBlacklisting_) external onlyOwner {
        blacklistUser[address_] = isBlacklisting_;
    }

    function setRule(
        bool limited_,
        uint256 maxTokenHolding_,
        uint256 minTokenHolding_
    ) external onlyOwner {
        limited = limited_;
        maxTokenHolding = maxTokenHolding_;
        minTokenHolding = minTokenHolding_;
    }

    function setIsTaxDisabled(bool isTaxDisabled_) external onlyOwner {
        isTaxDisabled = isTaxDisabled_;
    }

    function setMaxSellTaxLimit(uint256 limit) external onlyOwner {
        maxSellTaxLimit = limit;
    }

    /**
     * @notice address balance should be greater than token total calimable amount always 
     */
    function claimTokens(address reciever_) external {
        require(block.timestamp > firstTradingEnabledTimestamp + 2 days, "Claiming Tokens has not started yet.");
        require(block.timestamp < tokenClaimConstraint, "Claim Period has ended.");
        require(!blacklistUser[reciever_], "Not eligible for tax claim.");
        require(balanceOf(reciever_) >= userBuyAmountInRewardWindow[reciever_], "Account balance is less then buy amount in reward houre.");
        
        uint256 tokensToClaim = claimableTokens(reciever_);

        require(tokensToClaim > 0, "No tokens to claim.");

        userBuyTaxAmount[reciever_] = 0;
        // Caution won't be able to claim if the msg sender doesn't lie between the max and min holding value.
        _tokenTransfer(address(this), reciever_, tokensToClaim);

        emit TokensClaimed(reciever_, tokensToClaim);
    }

    function claimableTokens(address reciever_) public view returns(uint256) {
        uint256 tokensToClaim = userBuyTaxAmount[reciever_];
        if(userSoldOrTransferToken[reciever_]) {
            tokensToClaim = (tokensToClaim * SOLD_OR_TRANSFER_CLAIM_PERCENTAGE) / MAX_BASIS_POINT;
        }
        return tokensToClaim;
    }

    function isBlacklisted(address address_) public view returns (bool) {
        return blacklistUser[address_];
    }

    function userSoldToken(address address_) public view returns (bool) {
        return userSoldOrTransferToken[address_];
    }

    function _transfer(
        address sender_,
        address recipient_,
        uint256 amount_
    ) internal virtual override tradingEnabled(sender_, recipient_) {
        if (isTaxDisabled) {
            // Taxes are disabled, no tax calculation needed
            _tokenTransfer(sender_, recipient_, amount_);
        } 
        else {
            // Apply tax rate
            uint256 taxAmount = _calculateTax(amount_, recipient_, sender_);
            if(taxAmount == 0) {
                _tokenTransfer(sender_, recipient_, amount_);
            }
            else {
                bool isBuyTransfer = sender_ == pair;
                // solhint-disable-next-line not-rely-on-time
                if (isBuyTransfer && (block.timestamp <= firstTradingEnabledTimestamp + REWARD_WINDOW)) {
                    // recipient will get to reclaim as the tax is deducted from their share
                    userBuyTaxAmount[recipient_] += taxAmount;
                    userBuyAmountInRewardWindow[recipient_] += amount_ - taxAmount;
                }
                // solhint-disable-next-line not-rely-on-time
                if (!(isBuyTransfer) && (block.timestamp < firstTradingEnabledTimestamp + STORAGE_WINDOW)) {
                    userSoldOrTransferToken[sender_] = true;
                }

                _tokenTransfer(sender_, recipient_, amount_ - taxAmount);

                if(isBuyTransfer) {
                    _tokenTransfer(sender_, address(this), taxAmount);
                } else {
                    _tokenTransfer(sender_, address(this), taxAmount);
                    sellTax += taxAmount;
                    if (sellTax > maxSellTaxLimit) {
                        swapTokensForETH(maxSellTaxLimit);
                        sellTax = 0;
                    }
                }
            }
        }
    }

    function _tokenTransfer(
        address sender_,
        address recipient_,
        uint256 amount_
    ) internal {
        super._transfer(sender_, recipient_, amount_);
    }

    // Calculates tax based on amount and tax rate.
    function _calculateTax(uint256 amount_, address recipient_, address sender_) internal view returns (uint256) {
        uint256 taxRate;
        // solhint-disable-next-line not-rely-on-time
        if(sender_!=pair && recipient_ !=pair){
            return 0;
        }
        else {
            if(sender_ == pair) {
                taxRate = buyTaxRate();
            } 
            if (recipient_ == pair ) {
                taxRate = sellTaxRate();
            } 
        }
        if (exemptFee[recipient_] || exemptFee[sender_]) {
            return 0;
        }
        uint256 taxAmount = (amount_ * taxRate) / MAX_BASIS_POINT;
        return taxAmount;
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual override {
        require(!blacklistUser[from_], "Sender is blacklisted.");
        require(!blacklistUser[to_], "Recipient is blacklisted.");
        
        if (limited && msg.sender != owner() && to_!=pair && to_ != address(this)) {
            uint256 recipientBalance = super.balanceOf(to_);
            uint256 newBalance = recipientBalance + amount_;

            require(newBalance <= maxTokenHolding && newBalance >= minTokenHolding, "Not within max/min holding limits.");
        }
    }

    function swapTokensForETH(uint256 tokenAmount_) internal {
        // generate the pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount_);
        
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount_,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    receive() external payable {}

    function buyTaxRate() view public returns(uint256) {
        if(block.timestamp < firstTradingEnabledTimestamp + 10 minutes) {
            return THIRTY_BASIS_POINT;
        }
        if(block.timestamp < firstTradingEnabledTimestamp + 20 minutes) {
            return TWENTY_FIVE_BASIS_POINT;
        }
        if(block.timestamp < firstTradingEnabledTimestamp + 30 minutes) {
            return TWENTY_BASIS_POINT;
        }
        if(block.timestamp < firstTradingEnabledTimestamp + 40 minutes) {
            return FIFTEEN_BASIS_POINT;
        }
        if(block.timestamp < firstTradingEnabledTimestamp + 50 minutes) {
            return TEN_BASIS_POINT;
        }
        if(block.timestamp < firstTradingEnabledTimestamp + 60 minutes) {
            return FIVE_BASIS_POINT;
        }
        else {
            return buyTaxRateBasisPoint;
        }
    }

    function sellTaxRate() view public returns(uint256) {
        if(block.timestamp < firstTradingEnabledTimestamp + 30 minutes) {
            return THIRTY_BASIS_POINT;
        }
        if(block.timestamp < firstTradingEnabledTimestamp + 60 minutes) {
            return TWENTY_FIVE_BASIS_POINT;
        }
        if(block.timestamp < firstTradingEnabledTimestamp + 90 minutes) {
            return TWENTY_BASIS_POINT;
        }
        if(block.timestamp < firstTradingEnabledTimestamp + 120 minutes) {
            return FIFTEEN_BASIS_POINT;
        }
        if(block.timestamp < firstTradingEnabledTimestamp + 150 minutes) {
            return TEN_BASIS_POINT;
        }
        if(block.timestamp < firstTradingEnabledTimestamp + 180 minutes) {
            return FIVE_BASIS_POINT;
        }
        else {
            return sellTaxRateBasisPoint;
        }
    }

    function withdrawETH() external onlyOwner returns(bool){
        (bool success, bytes memory data) = owner().call{value: address(this).balance}("");
        return success;
    }

    function withdrawTokens() external onlyOwner {
        uint256 amount = balanceOf(address(this));
        _tokenTransfer(address(this), owner(), amount);
    }
}