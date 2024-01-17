// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IGobblers.sol";

contract GooHolder is Ownable {
    using SafeERC20 for IERC20;
    
    uint256 public feeAmount;
    uint256 public feePercentRate = 50;
    uint256 private constant MAX_FEE_RATE = 200;
    uint256 private constant FEE_BASE = 1000;

    uint256 lastTracked;
    IERC20 constant public goo = IERC20(0x600000000a36F3cD48407e35eB7C5c910dc1f7a8);
    IGobblers constant public Gobblers = IGobblers(0x60bb1e2AA1c9ACAfB4d34F71585D7e959f387769);
    address public wGooMinter;
    constructor() {}

    event Mint(uint256 indexed maxPrice);
    event Withdraw(uint256 indexed amount, address indexed whom);
    modifier onlywGoo() {
        require(msg.sender == wGooMinter || msg.sender == owner(), "Not the owner or minter");
        _;
    }

    modifier update() {
        feeAmount = feeAmount + (Gobblers.gooBalance(address(this)) - lastTracked) * feePercentRate / FEE_BASE;
        _;
        lastTracked = Gobblers.gooBalance(address(this));

    }

    function depositGoo(uint256 amount) external update onlywGoo {
        Gobblers.addGoo(amount);
    }

    function withdrawGoo(uint256 amount, address whom) external update onlywGoo {
        Gobblers.removeGoo(amount);
        goo.safeTransfer(whom, amount);
        if (goo.balanceOf(address(this)) > 0) {        
            Gobblers.addGoo(goo.balanceOf(address(this)));
        }
        emit Withdraw(amount, whom);
    }

    function mintGobblerWithFee(uint256 maxPrice) external onlyOwner {
        require(feeAmount > maxPrice, "not enough");
        uint256 before = Gobblers.gooBalance(address(this));
        Gobblers.mintFromGoo(maxPrice, true);
        feeAmount = feeAmount + Gobblers.gooBalance(address(this)) - before;    
        lastTracked = Gobblers.gooBalance(address(this));
        emit Mint(before - Gobblers.gooBalance(address(this)));
    }

    function changeMinter(address wGooNew) external onlyOwner {
        wGooMinter = wGooNew;
    }

    function totalGoo() external view returns (uint256) {
        return Gobblers.gooBalance(address(this)) - feeAmount;
    }

    
    function addFee(uint256 amount) external onlywGoo {
        feeAmount = feeAmount + amount;
    }

    function changeFeeRate(uint256 newFee) external onlyOwner {
        require(newFee < MAX_FEE_RATE, "too big");
        feePercentRate = newFee;
    }

    function takeFee(address whom) external onlyOwner {
        Gobblers.removeGoo(feeAmount);
        goo.safeTransfer(whom, feeAmount);
        feeAmount = 0;
        lastTracked = Gobblers.gooBalance(address(this));
    }

    function takeNFT(uint256[] memory ids) external onlyOwner{
        for (uint j = 0; j < ids.length; j++) {
            Gobblers.transferFrom(address(this), owner(), ids[j]); //probably better to any address not owner
        }
    }

    function arbitraryCall(address target, uint256 value, bytes calldata data) external payable onlyOwner {  //in case of stuck
        (bool success, bytes memory result) = payable(target).call{value: value}(data);
        if (!success) {
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }
}
