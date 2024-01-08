// SPDX-License-Identifier: UNLICENSED
// DELTA-BUG-BOUNTY
pragma solidity ^0.7.6;

import "./SafeMathUpgradeable.sol";
import "./IDeltaToken.sol";
import "./IRebasingLiquidityToken.sol";

contract DELTA_Reserve_Vault {
    using SafeMathUpgradeable for uint256;

    // constants and immutables
    address constant public DELTA_LSW = 0xdaFCE5670d3F67da9A3A44FE6bc36992e5E2beaB;
    IERC20 constant public WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IDeltaToken public constant DELTA = IDeltaToken(0x9EA3b5b4EC044b70375236A281986106457b20EF);
    address public constant RLP = 0xfcfC434ee5BfF924222e084a8876Eee74Ea7cfbA;

    // Storage slots
    uint256 public DELTA_PER_ONE_WHOLE_ETH;
    bool private lock;
    bool public floorExchangeOpen;

    modifier locked {
        require(lock == false,"Locked");
        lock = true;
        _;
        lock = false;
    }

    receive() external payable {
        revert("ETH not allowed");
    }

    function flashBorrowEverything() public locked {
        require(msg.sender != address(0));
        require(msg.sender == RLP);
        uint256 balanceDELTA = DELTA.balanceOf(address(this));
        uint256 balanceWETH = WETH.balanceOf(address(this));

        DELTA.transfer(RLP, balanceDELTA);
        WETH.transfer(RLP, balanceWETH);

        IRebasingLiquidityToken(RLP).reserveCaller(balanceDELTA,balanceWETH);

        require(DELTA.balanceOf(address(this)) == balanceDELTA, "Did not get DELTA back");
        require(WETH.balanceOf(address(this)) + 10 >= balanceWETH, "Did not get WETH back"); // DIVISION!
    }

    function openFloorExchange(bool open) public {
        onlyMultisig();
        floorExchangeOpen = open;
    }

    function setRatio(uint256 ratio) public {
        require(msg.sender == DELTA_LSW,"");
        DELTA_PER_ONE_WHOLE_ETH = ratio;
    }

    function exchangeDELTAForFloorPrice(uint256 _amount) public {
        require(floorExchangeOpen, "!open");
        require(DELTA.transferFrom(msg.sender, address(this), _amount), "Transfer poo poo, likely no allowance");
        uint256 ethDue = _amount.mul(1e18).div(DELTA_PER_ONE_WHOLE_ETH);
        WETH.transfer(msg.sender, ethDue);
    }

    function withdrawUnsupportedTokens(address token, uint256 amount) public {
        onlyMultisig();
        // require(token != address(WETH) && token != address(DELTA), "Cannot withdraw principle contracts");
        if(token == address(0)) { // eth
            (bool success,) = msg.sender.call{value : amount}("");
            require(success);
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    function deltaGovernance() public view returns (address) {
        if(address(DELTA) == address(0)) {return address (0); }
        return DELTA.governance();
    }

    function onlyMultisig() private view {
        require(msg.sender == deltaGovernance(), "!governance");
    }

}