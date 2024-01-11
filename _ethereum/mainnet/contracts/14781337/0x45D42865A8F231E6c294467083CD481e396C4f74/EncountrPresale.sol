// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "./IERC20.sol";
import "./IENCTR.sol";
import "./IERC20Metadata.sol";
import "./ITreasury.sol";

import "./EncountrAccessControlled.sol";

import "./SafeERC20.sol";
import "./SafeMath.sol";

contract EncountrPresale is EncountrAccessControlled {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event SaleStarted(uint256 tokenPrice, IERC20 purchaseToken);
    event SaleEnded();
    event BuyerApproved(address indexed buyer);

    ITreasury public treasury;
    IERC20 public purchaseToken;
    IERC20 public enctr;

    uint256 public min;
    uint256 public max;
    uint256 public price;

    mapping(address => bool) public allowed;
    mapping(address => uint256) public orderSize;

    // If both are false, the nothing can be done other than buyer approval. This will be the case
    // before the sale has started.
    // If active is true but finished is false, then the sale is ongoing and people can make their
    // orders.
    // It finished is true but active is false, the sale is over and people can claim their tokens.
    // It should not be the case that _both_ are true.
    bool public active; // Is the sale running?
    bool public finished; // Has the sale finished?

    constructor(
        address _authority,
        address _treasury,
        uint256 _min,
        uint256 _max,
        address _purchaseToken,
        address _enctr,
        uint256 _price
    ) EncountrAccessControlled(IEncountrAuthority(_authority)) {
        require(_authority != address(0), "zero address.");

        require(_treasury != address(0), "zero address.");
        treasury = ITreasury(_treasury);

        require(_purchaseToken != address(0), "zero address.");
        purchaseToken = IERC20(_purchaseToken);
        require(_enctr != address(0), "zero address.");
        enctr = IENCTR(_enctr);

        require(_max > _min, "min is higher than max.");
        min = _min;
        max = _max;

        require(_price >= 10**IERC20Metadata(address(purchaseToken)).decimals(), "need ENCTR backing");
        price = _price;
    }

    function start() external onlyGovernor() {
        require(!finished, "this sale has already finished.");
        active = true;
        emit SaleStarted(price, purchaseToken);
    }

    function stop() external onlyGovernor() {
        require(active, "this sale has already stopped.");
        active = false;
    }

    function finish() external onlyGovernor() {
        require(!active, "this sale is ongoing.");
        finished = true;
        emit SaleEnded();
    }

    function _approveBuyer(address _buyer) internal {
        allowed[_buyer] = true;
        emit BuyerApproved(_buyer);
    }

    function approveBuyer(address _buyer) external onlyGovernor() {
        _approveBuyer(_buyer);
    }

    function approveBuyers(address[] calldata _newBuyers) external onlyGovernor() {
        for(uint256 i = 0; i < _newBuyers.length; i++) {
            _approveBuyer(_newBuyers[i]);
        }
    }

    function _buyFromTreasury(address _buyer, uint256 _amountOfEnctr) internal {
        (uint256 totalPrice, uint256 decimals) = _totalPrice(_amountOfEnctr);
        purchaseToken.safeApprove(address(treasury), totalPrice);
        treasury.deposit(
            totalPrice,
            address(purchaseToken),
            totalPrice.div(10**decimals).sub(_amountOfEnctr)
        );

        enctr.safeTransfer(_buyer, _amountOfEnctr);
    }

    function _totalPrice(uint256 _amountOfEnctr) public view returns (uint256 _amount, uint256 _decimals) {
        _decimals = IERC20Metadata(address(enctr)).decimals();
        _amount = price.mul(_amountOfEnctr).div(10**_decimals);
    }

    function buy(uint256 _amountOfEnctr) external {
        require(active, "sale is not active");
        require(allowed[msg.sender], "buyer not approved");

        uint256 size = orderSize[msg.sender];
        uint256 total = size + _amountOfEnctr;
        require(total >= min, "below minimum for sale.");
        require(total <= max, "above maximum for sale.");

        (uint256 totalPrice,) = _totalPrice(_amountOfEnctr);
        purchaseToken.safeTransferFrom(msg.sender, address(this), totalPrice);
        orderSize[msg.sender] = total;
    }

    function _claim(address _buyer) internal {
        require(finished, "this sale is not been finalized.");
        require(orderSize[_buyer] > 0, "this address has not ordered.");
        _buyFromTreasury(_buyer, orderSize[_buyer]);
        orderSize[_buyer] = 0;
    }

    function claim() external {
        _claim(msg.sender);
    }

    function batchClaim(address[] calldata _buyers) external {
        for(uint256 i = 0; i < _buyers.length; i++) {
            _claim(_buyers[i]);
        }
    }

    function refund() external {
        uint256 size = orderSize[msg.sender];
        require(size > 0, "nothing to refund.");
        (uint256 totalPrice,) = _totalPrice(size);
        purchaseToken.safeTransfer(msg.sender, totalPrice);
        orderSize[msg.sender] = 0;
    }

    function withdrawTokens(address _tokenToWithdraw) external onlyGovernor() {
        IERC20(_tokenToWithdraw).transfer(msg.sender, IERC20(_tokenToWithdraw).balanceOf(address(this)));
    }
}
