/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.8.9;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./L1GatewayRouter.sol";
import "./L1CustomGatewayWithMint.sol";
import "./IEthBridgedToken.sol";
import "./ICustomToken.sol";

/*
    L1 SubredditPoints ERC20 token, pairable to L2 and supports L1<->L2 withdrawals/deposits
*/

error AddressZero();
error UnexpectedCall();

contract EthSubredditPoints is OwnableUpgradeable, ERC20Upgradeable, IEthBridgedToken, ICustomToken {
    address public gateway;
    address public l2Address;
    bool private shouldRegisterGateway;

    modifier onlyGateway {
        require(msg.sender == address(gateway), "Call only from gateway");
        _;
    }

    function initialize(
        address owner_,
        string calldata name_,
        string calldata symbol_,
        address gateway_,
        address l2Address_)
    external initializer
    {
        if (gateway_ == address(0) || l2Address_ == address(0))
            revert AddressZero();

        gateway = gateway_;
        l2Address = l2Address_;

        OwnableUpgradeable.__Ownable_init();
        if (owner_ != _msgSender()) {
            OwnableUpgradeable.transferOwnership(owner_);
        }
        ERC20Upgradeable.__ERC20_init(name_, symbol_);
    }

    function registerTokenOnL2(
        address, // ignored
        uint256 maxSubmissionCostForCustomBridge,
        uint256 maxSubmissionCostForRouter,
        uint256 maxGasForCustomBridge,
        uint256 maxGasForRouter,
        uint256 gasPriceBid,
        uint256 valueForGateway,
        uint256 valueForRouter,
        address creditBackAddress
    ) external payable override onlyOwner {
        // we temporarily set `shouldRegisterGateway` to true for the callback in registerTokenToL2 to succeed
        bool prev = shouldRegisterGateway;
        shouldRegisterGateway = true;

        L1CustomGateway(gateway).registerTokenToL2{value: valueForGateway}(
            l2Address,
            maxGasForCustomBridge,
            gasPriceBid,
            maxSubmissionCostForCustomBridge,
            creditBackAddress
        );

        address router = L1CustomGatewayWithMint(gateway).router();
        L1GatewayRouter(router).setGateway{value: valueForRouter}(
            gateway,
            maxGasForRouter,
            gasPriceBid,
            maxSubmissionCostForRouter,
            creditBackAddress
        );

        shouldRegisterGateway = prev;
    }

    function bridgeMint(address account, uint256 amount) external override onlyGateway {
        _mint(account, amount);
    }

    function bridgeBurn(address account, uint256 amount) external override onlyGateway {
        _burn(account, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(ERC20Upgradeable, ICustomToken) returns (bool) {
        return ERC20Upgradeable.transferFrom(sender, recipient, amount);
    }

    function balanceOf(address account)
        public
        view
        override(ERC20Upgradeable, ICustomToken)
        returns (uint256)
    {
        return ERC20Upgradeable.balanceOf(account);
    }

    /// @dev we only set shouldRegisterGateway to true when in `registerTokenOnL2`
    function isArbitrumEnabled() external view override returns (uint8) {
        if (!shouldRegisterGateway)
            revert UnexpectedCall();

        return uint8(uint16(0xa4b1));
    }
}
