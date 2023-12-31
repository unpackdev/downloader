// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./BasicCoin.sol";

/// @custom:security-contact developer@candydao.io

contract Sweet is BasicCoin {
    constructor(
        string memory name,
        string memory symbol,
        uint256 amount,
        address[3] memory dao
    ) BasicCoin(name, symbol, dao) {
        _mint(address(this), amount * 10 ** uint256(decimals()));
    }

    // 2. external functions
    function claimSweet(
        uint256 nonce,
        uint256 amount,
        uint256 tag,
        bytes memory signature
    ) external {
        require(
            _verifyBasicSingleData(
                address(this),
                msg.sender,
                nonce,
                amount,
                tag,
                this.claimSweet.selector,
                signature
            ),
            "invalid signer, on claiming Sweet"
        );
        _claimCoin(nonce, amount, tag);
    }

    function spendSweet(
        uint256 nonce,
        uint256 amount,
        uint256 tag,
        bytes memory signature
    ) external {
        require(
            _verifyBasicSingleData(
                address(this),
                msg.sender,
                nonce,
                amount,
                tag,
                this.spendSweet.selector,
                signature
            ),
            "invalid signer, on spending Sweet"
        );
        _spendCoin(nonce, amount, tag);
    }

    function stakeSweet(
        address conStake,
        uint256 nonce,
        uint256[] memory aryTime,
        uint256[] memory aryAmount,
        bytes memory signature
    ) external {
        require(
            _verifyBasicArrayData(
                address(this),
                conStake,
                msg.sender,
                nonce,
                aryTime,
                aryAmount,
                this.stakeSweet.selector,
                signature
            ),
            "invalid signer, on staking Sweet"
        );
        _stakeCoin(
            IBasicStake(conStake),
            msg.sender,
            nonce,
            aryTime,
            aryAmount
        );
    }

    function viewSweetInfo() external view returns (address, address, uint256) {
        uint256 remain = balanceOf(address(this));
        return (m_OpSigner, m_Treasury, remain);
    }
}
