// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

abstract contract Obligations {
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        private _obligations;

    event ObligationCreated(
        uint256 amount,
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    );

    event ObligationPaidOff(
        uint256 amount,
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    );

    function payOffObligation(
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    ) public {
        require(
            block.timestamp >= releaseTime ||
                _currentPricePerToken() >= targetPrice,
            "too early"
        );
        require(
            _obligations[recipient][releaseTime][targetPrice] > 0,
            "nothing to pay off"
        );

        uint256 amount = _obligations[recipient][releaseTime][targetPrice];
        _obligations[recipient][releaseTime][targetPrice] = 0;

        _transferTokens(address(this), recipient, amount);
        emit ObligationPaidOff(amount, recipient, releaseTime, targetPrice);
    }

    function obligation(
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    ) public view returns (uint256) {
        return _obligations[recipient][releaseTime][targetPrice];
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual;

    function _currentPricePerToken() internal virtual returns (uint256);

    function _createObligation(
        address account,
        uint256 amount,
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    ) internal {
        _transferTokens(account, address(this), amount);
        _obligations[recipient][releaseTime][targetPrice] += amount;
        emit ObligationCreated(
            _obligations[recipient][releaseTime][targetPrice],
            recipient,
            releaseTime,
            targetPrice
        );
    }

    uint256[49] private __gap;
}
