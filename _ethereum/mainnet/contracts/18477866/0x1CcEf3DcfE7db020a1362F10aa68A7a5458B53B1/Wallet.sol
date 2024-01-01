// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC20.sol";
// import "./IConnext.sol";

import "./ISwap.sol";
import "./IWeth.sol";

contract Wallet {

    address private recipient;
    uint private dscChainId;
    address public constant XSwapperAddress = 0x4315f344a905dC21a08189A117eFd6E1fcA37D57; // need to change each chains.
    // address public constant ContextAddress = 0x8898B472C54c31894e3B9bb83cEA802a5d0e63C6; // need to change each chains.
    address public constant ETHER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // IConnext public immutable connext = IConnext(ContextAddress);
    ISwap immutable public XSwapper = ISwap(XSwapperAddress);

    constructor(address _recipient, uint _dscChainId) {
        recipient = _recipient;
        dscChainId = _dscChainId;
    } 

    function transfer() external {
        uint amount = address(this).balance;
        // uint relayerFee = 1000000;
        // payable(recipient).transfer(amount);
        SwapDescription memory swapData;
        swapData.fromToken = IERC20(ETHER_ADDRESS);
        swapData.toToken = IERC20(ETHER_ADDRESS);
        swapData.receiver = recipient;
        swapData.amount = amount;
        swapData.minReturnAmount = amount;

        ToChainDescription memory chainData;
        chainData.toChainId = uint32(dscChainId);
        chainData.toChainToken = IERC20(ETHER_ADDRESS);
        chainData.expectedToChainTokenAmount = amount;
        chainData.slippage = uint32(100);
        XSwapper.swap{value: amount}(
            address(0),
            swapData, // swapDesc
            "",
            chainData // chainDesc
        );
            // Wrap ETH into WETH to send with the xcall
        // IWeth(WETH).deposit{value: amount - relayerFee}();

        // // This contract approves transfer to Connext
        // IWeth(WETH).approve(address(connext), amount - relayerFee);

        // // Encode the recipient address for calldata
        // bytes memory callData = abi.encode(recipient);
        // // xcall the Unwrapper contract to unwrap WETH into ETH on destination
        // connext.xcall{value: relayerFee}(
        //     1634886255,    // _destination: Domain ID of the destination chain
        //     0x429b9eb01362b2799131EfCC44319689b662999D, // _to: Unwrapper contract
        //     WETH,                 // _asset: address of the WETH contract
        //     msg.sender,           // _delegate: address that can revert or forceLocal on destination
        //     amount - relayerFee,               // _amount: amount of tokens to transfer
        //     30,                   // _slippage: the maximum amount of slippage the user will accept in BPS (e.g. 30 = 0.3%)
        //     callData              // _callData: calldata with encoded recipient address
        // );
    }

    receive() external payable {}
    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw(address _user) external {
        uint amount = address(this).balance;
        payable(_user).transfer(amount);
    }
}
