// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./Ownable.sol";
import "./TransferHelper.sol";

contract ERC20Crowdsale is Ownable {
    bool public isEnabled = false;

    // ERC20 Token address => price mapping
    mapping(address => uint256) public basePrice;

    uint256 public maxSupply;
    uint256 public totalSupply;

    address public WETH;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // wallet addresses for beneficiary parties
    address payable public charitiesBeneficiary;
    address payable public carbonOffsetBeneficiary;
    address payable public ccFundBeneficiary;
    address payable public metaCarbonBeneficiary;
    address payable public extraBeneficiary;

    // distribution Percentile for beneficiary parties
    uint8 public charitiesPercentile;
    uint8 public carbonOffsetPercentile;
    uint8 public ccFundPercentile;
    uint8 public metaCarbonPercentile;
    uint8 public extraPercentile;

    /**
     * @dev Emitted when token is purchased by `to` in `token` for `price`.
     */
    event Purchased(
        address indexed to,
        address indexed token,
        uint256 indexed price
    );

    /**
     * @dev Emitted when token is purchased by `to` in `token` for `price`.
     */
    event PurchasedWithBidPrice(
        address indexed to,
        address indexed token,
        uint256 totalPrice,
        uint256 indexed amount
    );

    // have to provide WETH token address and price in
    constructor(address wethAddress, uint256 priceInEth) {
        WETH = wethAddress;
        basePrice[WETH] = priceInEth;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    function setBasePriceInToken(address token, uint256 price)
        external
        onlyOwner
    {
        require(token != address(0), "zero address cannot be used");
        basePrice[token] = price;
    }

    function removeToken(address token) external onlyOwner {
        delete basePrice[token];
    }

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleStatus(bool status) public onlyOwner {
        isEnabled = status;
    }

    function setCharitiesBeneficiary(address payable account)
        external
        onlyOwner
    {
        require(account != address(0), "zero address cannot be used");
        charitiesBeneficiary = account;
    }

    function setCarbonOffsetBeneficiary(address payable account)
        external
        onlyOwner
    {
        require(account != address(0), "zero address cannot be used");
        carbonOffsetBeneficiary = account;
    }

    function setCCFundBeneficiary(address payable account) external onlyOwner {
        require(account != address(0), "zero address cannot be used");
        ccFundBeneficiary = account;
    }

    function setMetaCarbonBeneficiary(address payable account)
        external
        onlyOwner
    {
        require(account != address(0), "zero address cannot be used");
        metaCarbonBeneficiary = account;
    }

    function setExtraBeneficiary(address payable account) external onlyOwner {
        require(account != address(0), "zero address cannot be used");
        extraBeneficiary = account;
    }

    function setDistributionPercentile(
        uint8 charities,
        uint8 carbonOffset,
        uint8 ccFund,
        uint8 metaCarbon,
        uint8 extra
    ) external onlyOwner {
        require(
            charities + carbonOffset + ccFund + metaCarbon + extra == 100,
            "Sum of percentile should be 100"
        );
        charitiesPercentile = charities;
        carbonOffsetPercentile = carbonOffset;
        ccFundPercentile = ccFund;
        metaCarbonPercentile = metaCarbon;
        extraPercentile = extra;
    }

    function setMaxSupply(uint256 supply) public onlyOwner {
        require(supply > 0, "amount should be greater than 0");
        maxSupply = supply;
        totalSupply = 0;
    }

    function buyWithToken(address token, uint256 amount) public {
        require(isEnabled, "Sale is disabled");
        require(amount > 0, "You need to buy at least 1 token");
        require(basePrice[token] > 0, "Price in this token was not set");
        uint256 value = amount * basePrice[token];
        uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
        require(allowance >= value, "token allowance is not enough");

        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            value
        );

        _balances[msg.sender] += amount;
        for (uint256 i = 0; i < amount; i++) {
            emit Purchased(msg.sender, token, basePrice[token]);
        }
    }

    function buyWithTokenBidPrice(
        address token,
        uint256 amount,
        uint256 totalPrice
    ) public {
        require(isEnabled, "Sale is disabled");
        require(amount > 0, "need to buy at least 1 token");
        require(basePrice[token] > 0, "Price in this token was not set");

        uint256 value = amount * basePrice[token];
        require(
            totalPrice >= value,
            "bid price should be greater than base price"
        );

        uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
        require(allowance >= totalPrice, "token allowance is not enough");

        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            totalPrice
        );

        _balances[msg.sender] += amount;
        totalSupply += amount;
        emit PurchasedWithBidPrice(msg.sender, token, totalPrice, amount);
    }

    /**
     * Fallback function is called when msg.data is empty
     */
    receive() external payable {
        buyWithEth();
    }

    /**
     * paid mint for sale.
     */
    function buyWithEth() public payable {
        require(isEnabled, "Sale is disabled");
        require(totalSupply < maxSupply, "Total Supply is already reached");
        require(msg.value >= basePrice[WETH], "Not enough ETH sent");

        _balances[msg.sender] += 1;
        totalSupply++;

        uint256 remaining = msg.value - basePrice[WETH];

        // _forwardFunds(basePrice[WETH]);

        if (remaining > 0) {
            TransferHelper.safeTransferETH(msg.sender, remaining);
        }

        emit Purchased(msg.sender, WETH, basePrice[WETH]);
    }

    function buyWithEthBidPrice(uint256 amount) public payable {
        require(amount > 0, "need to buy at least 1 token");
        require(isEnabled, "Sale is disabled");
        require(totalSupply < maxSupply, "Total Supply is already reached");
        require(msg.value >= basePrice[WETH] * amount, "Not enough ETH sent");

        _balances[msg.sender] += amount;
        totalSupply += amount;

        emit PurchasedWithBidPrice(msg.sender, WETH, msg.value, amount);
    }

    function _forwardToken(address token, uint256 amount) private {
        require(
            charitiesPercentile +
                carbonOffsetPercentile +
                ccFundPercentile +
                metaCarbonPercentile +
                extraPercentile ==
                100,
            "Sum of percentile should be 100"
        );
        require(amount > 0, "amount should be greater than zero");
        uint256 value = (amount * charitiesPercentile) / 100;
        uint256 remaining = amount - value;
        if (value > 0) {
            require(
                charitiesBeneficiary != address(0),
                "Charities wallet is not set"
            );
            TransferHelper.safeTransfer(token, charitiesBeneficiary, value);
        }

        value = (amount * carbonOffsetPercentile) / 100;
        if (value > 0) {
            require(
                carbonOffsetBeneficiary != address(0),
                "CarbonOffset wallet is not set"
            );
            TransferHelper.safeTransfer(token, carbonOffsetBeneficiary, value);
            remaining -= value;
        }

        value = (amount * ccFundPercentile) / 100;
        if (value > 0) {
            require(
                ccFundBeneficiary != address(0),
                "ccFund wallet is not set"
            );
            TransferHelper.safeTransfer(token, ccFundBeneficiary, value);
            remaining -= value;
        }

        value = (amount * extraPercentile) / 100;
        if (value > 0) {
            require(extraBeneficiary != address(0), "extra wallet is not set");
            TransferHelper.safeTransfer(token, extraBeneficiary, value);
            remaining -= value;
        }

        // no need to calculate, just send all remaining funds to extra
        if (remaining > 0) {
            require(
                metaCarbonBeneficiary != address(0),
                "metaCarbon wallet is not set"
            );
            TransferHelper.safeTransfer(
                token,
                metaCarbonBeneficiary,
                remaining
            );
        }
    }

    function _forwardETH(uint256 amount) private {
        require(amount > 0, "balance is not enough");
        uint256 value = (amount * charitiesPercentile) / 100;
        uint256 remaining = amount - value;
        if (value > 0) {
            require(
                charitiesBeneficiary != address(0),
                "Charities wallet is not set"
            );
            TransferHelper.safeTransferETH(charitiesBeneficiary, value);
        }

        value = (amount * carbonOffsetPercentile) / 100;
        if (value > 0) {
            require(
                carbonOffsetBeneficiary != address(0),
                "CarbonOffset wallet is not set"
            );
            TransferHelper.safeTransferETH(carbonOffsetBeneficiary, value);
            remaining -= value;
        }

        value = (amount * ccFundPercentile) / 100;
        if (value > 0) {
            require(
                ccFundBeneficiary != address(0),
                "ccFund wallet is not set"
            );
            TransferHelper.safeTransferETH(ccFundBeneficiary, value);
            remaining -= value;
        }

        value = (amount * extraPercentile) / 100;
        if (value > 0) {
            require(extraBeneficiary != address(0), "extra wallet is not set");
            TransferHelper.safeTransferETH(extraBeneficiary, value);
            remaining -= value;
        }

        // no need to calculate, just send all remaining funds to extra
        if (remaining > 0) {
            require(
                metaCarbonBeneficiary != address(0),
                "metaCarbon wallet is not set"
            );
            TransferHelper.safeTransferETH(metaCarbonBeneficiary, remaining);
        }
    }

    function withdrawEth() external onlyOwner {
        _forwardETH(address(this).balance);
    }

    function withdrawToken(address token) external onlyOwner {
        _forwardToken(token, IERC20(token).balanceOf(address(this)));
    }
}
