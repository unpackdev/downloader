import "./BaseModule.sol";
pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT

interface IWETH {
    function withdraw(uint amount) external;
    function approve(address spender, uint amount) external;
    function transfer(address to, uint amount) external;
}

contract Weth is BaseModule{
    address public immutable weth;

    constructor(address weth_)BaseModule("Weth") {
        weth = weth_;
    }


    /// @notice Wraps ether
    /// @custom:version 1
    /// @custom:in 1
    /// @custom:out wEth
    /// @custom:equal false
    /// @custom:override oWethWrap
    /// @custom:event uint256 amount
    /// @custom:mirror oWethUnwrap
    /// @custom:getter none
    function wethWrap(uint amount) public payable returns (TokenAmt[] memory) {
        (bool success, ) = weth.call{value: amount}("");
        if (!success) revert FacetError(this.wethWrap.selector, 0);
        TokenAmt[] memory tokenAmts = new TokenAmt[](1);
        tokenAmts[0] = TokenAmt({token: weth, amt: amount});
        emit Event(this.wethWrap.selector, 0, abi.encode(amount));
        return tokenAmts;
    }

    /// @notice Unwraps Ether
    /// @custom:version 1
    /// @custom:in 1
    /// @custom:out Eth
    /// @custom:equal false
    /// @custom:override oWethUnwrap
    /// @custom:event uint256 amount
    /// @custom:mirror none
    /// @custom:getter none
    function wethUnwrap(uint amount) public payable returns (TokenAmt[] memory) {
        IWETH(weth).approve(weth, amount);
        IWETH(weth).withdraw(amount);
        TokenAmt[] memory tokenAmts = new TokenAmt[](1);
        tokenAmts[0] = TokenAmt({token: address(0), amt: amount});
        emit Event(this.wethUnwrap.selector, 0, abi.encode(amount));
        return tokenAmts;
    }

    function oWethWrap(bytes memory, TokenAmt[] memory tokenAmts) public pure returns(bytes memory){
        /// @dev only 1 input expected
        return abi.encode(tokenAmts[0].amt);
    }
    function oWethUnwrap(bytes memory, TokenAmt[] memory tokenAmts) public pure returns(bytes memory){
        /// @dev only 1 input expected
        return abi.encode(tokenAmts[0].amt);
    }
}
