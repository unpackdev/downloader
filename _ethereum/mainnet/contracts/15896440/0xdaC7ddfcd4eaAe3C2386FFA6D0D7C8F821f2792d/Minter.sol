// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./SafeERC20.sol";

interface IHolderContract {
    function totalGoo() external view returns (uint256);
    function depositGoo(uint256) external;
    function withdrawGoo(uint256, address) external;
    function addFee(uint256) external;
}

interface IxGoo is IERC20 {
    function mint(address who, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
}

contract xGooMinter is Ownable {
    using SafeERC20 for IERC20;
    event Minted(address indexed from, uint256 indexed gooAmount, uint256 indexed feeAmount);
    event Redeemed(address indexed from, uint256 indexed gooAmount, uint256 indexed feeAmount);

    IxGoo public immutable xGoo;
    IERC20 public immutable goo;
    IHolderContract public HolderContract;
    uint256 wrapFee = 100;
    uint256 unWrapFee = 300;
    mapping (address => bool) public Updater;

    constructor (address _xGoo, address _goo, address _HolderContract) {
        xGoo = IxGoo(_xGoo);
        goo = IERC20(_goo);
        HolderContract = IHolderContract(_HolderContract);
    }

    function setHolderContract(address _HolderContract) external onlyOwner {
        require(_HolderContract!= address(0), "Invalid reactor address");
        HolderContract = IHolderContract(_HolderContract);
    }

    function xGooWrapFee() public view returns (uint256) {
        return wrapFee;
    }

    function xGooUnwrapFee() public view returns (uint256) {
        return unWrapFee;
    }

    function changeWrapFee(uint256 newFee) external onlyOwner {
        require(newFee < 5000, "too big");
        wrapFee = newFee;
    }

    function changeunWrapFee(uint256 newFee) external onlyOwner {
        require(newFee < 10000, "too big");
        unWrapFee = newFee;
    }

    function wrap(uint256 gooAmount) external {
        goo.transferFrom(msg.sender, address(HolderContract), gooAmount);
        uint256 fee = gooAmount * (10000-xGooWrapFee())/10000;
        uint256 xGooAmount = gooAmount-fee;
        if (HolderContract.totalGoo() > 0) {
            xGooAmount = (gooAmount-fee) * xGoo.totalSupply() / HolderContract.totalGoo(); 
        } 
        HolderContract.depositGoo(gooAmount);
        HolderContract.addFee(fee);
        xGoo.mint(msg.sender, xGooAmount);
    }

    function unwrap(uint256 xGooAmount) external {
        uint256 noFeeAmount = xGooAmount * (10000-xGooUnwrapFee())/10000;
        uint256 gooAmount = noFeeAmount * HolderContract.totalGoo()/ xGoo.totalSupply();  
        HolderContract.addFee((xGooAmount - noFeeAmount) * HolderContract.totalGoo()/ xGoo.totalSupply());
        xGoo.burnFrom(msg.sender, xGooAmount);
        HolderContract.withdrawGoo(gooAmount, msg.sender);
    }
}