// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC20.sol";
import "./WmbApp.sol";

// Adapte the same message interface with CCPoolV1
contract MCTokenV2 is ERC20, WmbApp {
    event CrossChainMint(bytes32 indexed messageId, uint256 indexed fromChainId, address indexed to, uint256 amount, address fromSC);

    constructor(
        string memory _name, 
        string memory _symbol, 
        uint256 _supply, 
        address _admin, 
        address _wmbGateway
    ) ERC20(_name, _symbol) {
        _mint(_admin, _supply);
        initialize(_admin, _wmbGateway);
    }

    function _wmbReceive(
        bytes calldata data,
        bytes32 messageId,
        uint256 fromChainId,
        address fromSC
    ) internal override {
        (, address to, uint256 amount,) = abi.decode(data, (address, address, uint256, string));
        _mint(to, amount);
        emit CrossChainMint(messageId, fromChainId, to, amount, fromSC);
    }

    function crossTo(
        uint256 toChainId,
        address toSC,
        address toUser,
        uint256 amount,
        uint256 gasLimit
    ) public payable {
        _burn(msg.sender, amount);
        uint fee = estimateFee(toChainId, gasLimit);
        _dispatchMessage(toChainId, toSC, abi.encode(msg.sender, toUser, amount, "crossTo"), fee);
    }
}

