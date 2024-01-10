// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";

import "./SafeERC20.sol";

import "./IDummyToken.sol";

/**
 * @title Dummy output token
 */
contract OutputTokenDummy is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint8 private immutable _decimals;

    address private supplyToken;

    uint256 private lastHarvestBlockNum;

    uint256 public harvestPerBlock;  

    address public controller; // st comp
    modifier onlyController() {
        require(msg.sender == controller, "caller is not controller");
        _;
    }

    event ControllerUpdated(address controller);

    constructor(
        address _supplyToken,
        address _controller,
        uint256 _harvestPerBlock
    ) ERC20(string(abi.encodePacked("Celer ", IDummyToken(_supplyToken).name())), string(abi.encodePacked("celr", IDummyToken(_supplyToken).symbol()))) {
        _decimals = IDummyToken(_supplyToken).decimals();
        supplyToken = _supplyToken;
        controller = _controller;
        lastHarvestBlockNum = block.number;
        harvestPerBlock = _harvestPerBlock;
    }
    
    function buy(uint _amount) external onlyController {
        require(_amount > 0, "invalid amount");
        IERC20(supplyToken).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }
    
    function sell(uint _amount) external {
        require(_amount > 0, "invalid amount");
        require(totalSupply() >= _amount, "not enough supply");

        IDummyToken(supplyToken).mint(address(this), harvestPerBlock * (block.number - lastHarvestBlockNum));
        lastHarvestBlockNum = block.number;

        IERC20(supplyToken).safeTransfer(msg.sender, _amount * IERC20(supplyToken).balanceOf(address(this)) / totalSupply());
        _burn(msg.sender, _amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function underlyingToken() public view returns (address) {
        return supplyToken;
    }

    function updateController(address _controller) external onlyOwner {
        controller = _controller;
        emit ControllerUpdated(_controller);
    }

    function updateHarvestPerBlock(uint256 newVal) external onlyOwner {
        harvestPerBlock = newVal;
    }
}