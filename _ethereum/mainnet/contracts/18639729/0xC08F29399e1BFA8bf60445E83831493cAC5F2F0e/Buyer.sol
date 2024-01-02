pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT
import "WETH.sol";
import "IERC20.sol";
import "Math.sol";
import "IDEXRouter.sol";
import "IDEXFactory.sol";

contract Buyer {
    address private owner;
    mapping(address => bool) private allowed;
    address private routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IDEXRouter private router;
    address private WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor() {
        owner = msg.sender;
        allowed[owner] = true;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    function rescueToken(address token) external onlyOwner {
        IERC20 tokenToRescue = IERC20(token);
        tokenToRescue.transfer(owner, tokenToRescue.balanceOf(address(this)));
    }

    function allowAddy(address token) external onlyOwner {
        allowed[token] = true;
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getAddressBalance(address addy) public view returns (uint256) {
        return addy.balance;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}

    function abstractFunction(
        address target,
        address[] memory _addys,
        uint256 amount
    ) public payable {
        require(allowed[tx.origin]);

        router = IDEXRouter(routerAddress);
        address[] memory path = new address[](2);
        address[] memory tempPath2 = new address[](2);
        uint256[] memory costForAmount;
        path[1] = target;
        path[0] = WETHAddress;
        tempPath2[0] = target;
        tempPath2[1] = WETHAddress;

        for (uint256 i = 0; i < _addys.length; i++) {
            IERC20 tokenCA = IERC20(target);
            costForAmount = router.getAmountsIn(amount, path);
            if (address(this).balance > costForAmount[0]) {
                router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: costForAmount[0]
                }(0, path, address(this), block.timestamp);
                tokenCA.transfer(_addys[i], tokenCA.balanceOf(address(this)));
            } else {
                break;
            }
        }
    }
}
