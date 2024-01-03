pragma solidity 0.6.12;

import "./IERC20.sol";
import "./Ownable.sol";

interface iCHI is IERC20 {
    function freeFromUpTo(address from, uint256 value) external returns (uint256);
}
interface UniLayerSale {
    function setupLiquidity() external;
    function transferOwnership(address _newOwner) external;
}

contract ProxyChiCaller is Ownable {

    iCHI chi = iCHI(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    UniLayerSale test = UniLayerSale(0xa205D797243126F312aE63bB0A5EA9A32FB14f41);
    receive() external payable {}

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chi.freeFromUpTo(address(this), (gasSpent + 14154) / 41130);
    }

    constructor () public {
        require(chi.approve(address(this), uint256(-1)));
    }

    function setProxyTarget(address proxy ) public onlyOwner {
        test = UniLayerSale(proxy);
    }

    function proxyCall() public discountCHI{
        test.setupLiquidity();
    }

    function transferOwnershipBack() public onlyOwner {
        test.transferOwnership(msg.sender);
    }
}