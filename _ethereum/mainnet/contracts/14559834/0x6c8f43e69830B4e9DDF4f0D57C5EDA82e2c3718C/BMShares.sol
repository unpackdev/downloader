//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";

import "./AbstractDividends.sol";
import "./Killswitch.sol";

import "./IBMShares.sol";
import "./IHoney.sol";
import "./CCMath.sol";

contract BMShares is IBMShares, ERC20, AbstractDividends, Killswitch {
    using CCMath for uint256;

    IHoney private _honey;

    uint256 private priceHoney = 0;
    uint256 private priceEth = 0;

    uint256 private constant MAX_SUPPLY = 500e6;
    uint256 private constant MINTABLE_FOR_ETH_SUPPLY = 100e6;
    uint256 private mintedForEth = 0;

    constructor(string memory name_, string memory symbol_, IHoney honey) ERC20(name_, symbol_) {
        require(address(honey) != address(0), "IHoney must be specified");
        _honey = honey;
        _mintInternal(msg.sender, 10000);

        setPriceEth(1e14);
        setPriceHoney(10e18);
    }

    function mintForHoney(address for_, uint256 amount, uint256 value) external override killswitch {
        require(value >= amount * priceHoney, "value doesn't match");
        address spender = msg.sender;
        _honey.burn(spender, priceHoney * amount);
        _mintInternal(for_, amount);
    }

    function mintForEth(address for_, uint256 amount) external override payable killswitch {
        require(mintedForEth + amount <= MINTABLE_FOR_ETH_SUPPLY, "can't mint above allowed");
        require(msg.value >= amount * priceEth, "value doesn't match");
        mintedForEth = mintedForEth.add(amount);
        _mintInternal(for_, amount);

        _increaseOwnerBalance(msg.value);
    }

    function _mintInternal(address for_, uint256 amount) private {
        require(amount > 0, "0 amount");
        require(totalSupply() + amount <= MAX_SUPPLY, "can't mint above MAX_SUPPLY");
        _mint(for_, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function _sharesOf(address holder) internal override view returns (int256) {
        return int256(balanceOf(holder));
    }

    function _totalShares() internal override view returns (uint256)
    {
        return totalSupply();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (from != address(0)) {
            _unstake(from, amount);
        }

        if (to != address(0)) {
            _stake(to, amount);
        }
    }

    function getPriceEth() external view override returns (uint256) {
        return priceEth;
    }

    function getPriceHoney() external view override returns (uint256) {
        return priceHoney;
    }

    function availableForEth() external view override returns (uint256) {
        return MINTABLE_FOR_ETH_SUPPLY.sub(mintedForEth);
    }

    function setPriceEth(uint256 price) public override onlyOwner {
        priceEth = price;
    }

    function setPriceHoney(uint256 price) public override onlyOwner {
        priceHoney = price;
    }

    function withdrawDividends() external override {
        _withdrawFor(payable(msg.sender));
    }

    function withdraw() external override onlyOwner {
        uint256 amount = _getOwnerBalance();
        _decreaseOwnerBalance(amount);
        address payable to_ = payable(owner());
        to_.transfer(amount);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {
    }
}
