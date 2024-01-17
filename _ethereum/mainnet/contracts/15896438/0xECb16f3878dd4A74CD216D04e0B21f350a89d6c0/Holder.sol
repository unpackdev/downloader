// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

pragma solidity ^0.8.0;

interface IGobblers {
    function addGoo (uint256 amount) external;
    function removeGoo(uint256 amount) external;
    function mintFromGoo(uint256 maxPrice, bool useVirtual) external;
    function transferFrom(address maxPrice, address useVirtual, uint256 id) external;
    function gooBalance(address user) view external returns(uint256);
}

contract HolderContract is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    uint256 public feeAmount;
    uint256 public feePercent = 500;
    uint256 lastTracked;
    IERC20 constant public goo = IERC20(0x600000000a36F3cD48407e35eB7C5c910dc1f7a8);
    IGobblers public Gobblers = IGobblers(0x60bb1e2AA1c9ACAfB4d34F71585D7e959f387769);
    // admin address
    address public adminAddress;
    address public xGooMinter;
    constructor() {}

    event Mint(uint256 indexed maxPrice);
    event Withdraw(uint256 indexed amount, address indexed whom);
    event Claim(address indexed user, uint256 indexed poolId, uint256 rewardAmount, address to);
    modifier onlyxGoo() {
        require(msg.sender == xGooMinter || msg.sender == owner(), "not good");
        _;
    }
    function depositGoo(uint256 amount) external onlyxGoo {
        update();
        Gobblers.addGoo(amount);
    }

    function withdrawGoo(uint256 amount, address whom) external onlyxGoo {
        update();
        Gobblers.removeGoo(amount);
        goo.safeTransfer(whom, amount);
        if (Gobblers.gooBalance(address(this)) > 0) {        
            Gobblers.addGoo(Gobblers.gooBalance(address(this)));
        }
        emit Withdraw(amount, whom);
    }

    function mintGobblerWithFee(uint256 maxPrice) external onlyOwner {
        require(feeAmount > maxPrice, "not enough");
        uint256 before = Gobblers.gooBalance(address(this));
        Gobblers.mintFromGoo(maxPrice, true);
        feeAmount = feeAmount + Gobblers.gooBalance(address(this)) - before;
        emit Mint(Gobblers.gooBalance(address(this)) - before);
    }

    function changexGoo(address xGooNew) external onlyOwner {
        xGooMinter = xGooNew;
    }

    function TotalGoo() external view returns (uint256) {
        return Gobblers.gooBalance(address(this)) - feeAmount;
    }

    function update() internal {
        feeAmount = feeAmount + (Gobblers.gooBalance(address(this)) - lastTracked) * feePercent / 10000;
        lastTracked = Gobblers.gooBalance(address(this));
    }

    function addFee(uint256 amount) external onlyxGoo {
        feeAmount = feeAmount + amount;
    }

    function changeFee(uint256 newFee) external onlyOwner {
        require(newFee < 2000, "too big");
        feePercent = newFee;
    }

    function takeFee(address whom) external onlyOwner {
        Gobblers.removeGoo(feeAmount);
        goo.safeTransfer(whom, feeAmount);
        feeAmount = 0;
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
