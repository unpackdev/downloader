// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./VPoolBase.sol";
import "./IToken.sol";

//solhint-disable no-empty-blocks
contract VETH is VPoolBase {
    string public constant VERSION = "3.0.3";
    TokenLike public constant WETH = TokenLike(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    constructor(string memory _name, string memory _symbol)
        VPoolBase(_name, _symbol, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
    {}

    function initialize(
        string memory _name,
        string memory _symbol,
        address _poolAccountant,
        address _addressListFactory
    ) external initializer {
        _initializeBase(
            _name,
            _symbol,
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            _poolAccountant,
            _addressListFactory
        );
    }

    /// @dev Handle incoming ETH to the contract address.
    receive() external payable {
        if (msg.sender != address(WETH)) {
            deposit();
        }
    }

    /// @dev Burns tokens/shares and returns the ETH value, after fee, of those.
    function withdrawETH(uint256 _shares) external whenNotShutdown nonReentrant {
        withdrawInETH = true;
        _withdraw(_shares);
        withdrawInETH = false;
    }

    /**
     * @dev After burning hook, it will be called during withdrawal process.
     * It will withdraw collateral from strategy and transfer it to user.
     */
    function _afterBurning(uint256 _amount) internal override returns (uint256) {
        if (withdrawInETH) {
            WETH.withdraw(_amount);
            Address.sendValue(payable(_msgSender()), _amount);
        } else {
            super._afterBurning(_amount);
        }
        return _amount;
    }

    /**
     * @dev Receives ETH and grants new tokens/shares to the sender depending
     * on the value of pool's share.
     */
    function deposit() public payable whenNotPaused nonReentrant {
        _claimRewards(_msgSender());
        uint256 _shares = _calculateShares(msg.value);
        // Wraps ETH in WETH
        WETH.deposit{value: msg.value}();
        _mint(_msgSender(), _shares);
        emit Deposit(_msgSender(), _shares, msg.value);
    }
}
