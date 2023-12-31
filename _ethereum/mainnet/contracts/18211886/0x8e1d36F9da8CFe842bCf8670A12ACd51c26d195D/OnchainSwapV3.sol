// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./OnchainGateway.sol";
import "./Ownable.sol";



contract OnchainSwapV3  is Context, Ownable{

    uint256 public fee = 0.05 ether;

    event ClaimedTokens(address to, uint256 balance);
    event OnchainSwap(address token, uint256 amount, uint256 fee);

    OnchainGateway public onchainGateway;

    constructor() {
        onchainGateway = new OnchainGateway(address(this));
    }

    modifier hasFee() {
        require(msg.value >= fee);
        _;
    }

    function onswap(
        address token,
        uint256 amount,
        address dex,
        address dexgateway,
        bytes memory calldata_
    ) external payable hasFee {

        if(token!=address(0)) {
            onchainGateway.claimTokens(
                token,
                _msgSender(),
                amount
            );

            if (dexgateway == address(0)) {
                forceApprove(token, dex, amount);
            } else {
                forceApprove(token, dexgateway, amount);
            }
        }

        require(dex != address(onchainGateway), "OnchainSwap: call to onchain gateway");

        {
            uint256 size;
            address toCheck = dex;

            assembly {
                size := extcodesize(toCheck)
            }

            require(size != 0, "OnchainSwap: call for a non-contract account");
        }


        (bool swapPassed, ) = dex.call{value: msg.value - fee}(
            calldata_
        );

        require(swapPassed, "OnchainSwap: Fail to call");
        emit OnchainSwap(token, amount, fee);
    }

    function changeFee(uint256 _newFee) public onlyOwner {
        fee = _newFee;
    }

    function claimTokens(address _to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = _to.call{value: balance}("");
        require(sent, "Failed to send Ether");
        emit ClaimedTokens(_to, balance);
    }

    function forceApprove(address _token, address _recipient, uint256 _value) internal {
        IERC20 erc20token = IERC20(_token);
        if (erc20token.allowance(address(this), _recipient) < _value) {
            erc20token.approve(_recipient, 0);
            erc20token.approve(_recipient, type(uint256).max);
        }
    }
}