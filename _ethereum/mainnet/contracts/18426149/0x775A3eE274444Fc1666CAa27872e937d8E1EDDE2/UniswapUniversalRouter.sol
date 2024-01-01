// SPDX-License-Identifier: MIT
// @credits : Salman Haider

pragma solidity 0.8.17;
import "./Commands.sol";
import "./Constants.sol";

interface IUniversalRouter  {
    /// @notice Executes encoded commands along with provided inputs. Reverts if deadline has expired.
    /// @param commands A set of concatenated commands, each 1 byte in length
    /// @param inputs An array of byte strings containing abi encoded inputs for each command
    /// @param deadline The deadline by which the transaction must be executed
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable;
}
interface IPermit2 {
    function approve(address token, address spender, uint160 amount, uint48 expiration) external ;
}
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract UniswapUniversalRouter{
    IUniversalRouter router;
    IPermit2 constant PERMIT2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    constructor(address _routerAddress) {
        router=IUniversalRouter(_routerAddress); //0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD
    }
    function swap(address token0,address token1,uint amount_in)public {
        IERC20(token0).transferFrom(msg.sender,address(this),amount_in);
        IERC20(token0).approve(address(PERMIT2), amount_in);
        PERMIT2.approve(token0, address(router), type(uint160).max, type(uint48).max);
        bytes memory commands = abi.encodePacked(bytes1(uint8(Commands.V2_SWAP_EXACT_IN)));
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(Constants.MSG_SENDER, amount_in, 0, path, true);

        router.execute(commands, inputs,type(uint48).max);
    }
    function withdraw(address destToken)public payable {
        IERC20(destToken).transfer(msg.sender, IERC20(destToken).balanceOf(address(this)) );
        require(IERC20(destToken).balanceOf(address(this))==0,"Withdraw Failed !" );

    }

}