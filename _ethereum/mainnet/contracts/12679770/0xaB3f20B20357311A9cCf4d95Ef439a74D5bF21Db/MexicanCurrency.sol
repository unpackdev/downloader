pragma solidity >=0.7.0 <0.9.0;

// SPDX-License-Identifier: MIT OR Apache-2.0

// import "./ERC20.sol";
import "./ERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./BlackList.sol";

abstract contract MexicanCurrency is ERC20Upgradeable, BlackList {
    using SafeMathUpgradeable for uint256;
    uint256 constant CENT = 10**6;

    struct Params {
        uint256 basisPointsRate;
        uint256 maximumFee;
    }

    Params public params;

    /**
     * @dev Emitted when `value` tokens are minted for `to`
     * @param _to address to mint tokens for
     * @param _value amount of tokens to be minted
     */
    event Mint(address indexed _to, uint256 _value);

    /**
     * @dev Emitted when `value` tokens are transfer for `to`
     * @param _to address to mint tokens for
     * @param _value amount of tokens to be minted
     */
    event SendFee(address indexed _to, uint256 _value);

    modifier executeTransaction(
        address _from,
        address _to,
        uint256 _amount
    ) {
        require(
            balanceOf(_from) >= _amount,
            "MexicanCurrency: Not enough funds"
        );

        uint256 fee = (_amount.mul(params.basisPointsRate)).div(10000);
        if (fee > params.maximumFee) fee = params.maximumFee;

        _amount = _amount.sub(fee);

        if (fee > 0 && _from != this.owner()) {
            _transfer(_from, this.owner(), fee);
            emit SendFee(this.owner(), fee);
        }

        require(
            !isBlacklisted[_to],
            "MexicanCurrency: recipient is blacklisted"
        );

        if (isRedemptionAddress(_to)) {
            _transfer(_from, _to, _amount.sub(_amount.mod(CENT)));
            _burn(_to, _amount.sub(_amount.mod(CENT)));
        } else {
            _transfer(_from, _to, _amount);
        }

        _;
    }

    function mint(address _account, uint256 _amount) external onlyOwner {
        require(
            !isBlacklisted[_account],
            "MexicanCurrency: account is blacklisted"
        );
        require(
            !isRedemptionAddress(_account),
            "MexicanCurrency: account is a redemption address"
        );
        _mint(_account, _amount);
        emit Mint(_account, _amount);
    }

    function transfer(address _to, uint256 _amount)
        public
        override
        whenNotPaused
        executeTransaction(msg.sender, _to, _amount)
        returns (bool)
    {
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
        public
        override
        whenNotPaused
        executeTransaction(_from, _to, _amount)
        returns (bool)
    {
        uint256 currentAllowance = allowance(_from, _msgSender());
        require(
            currentAllowance >= _amount,
            "MexicanCurrency: transfer amount exceeds allowance"
        );

        _approve(_from, _msgSender(), currentAllowance.sub(_amount));

        return true;
    }

    function isRedemptionAddress(address account) internal pure returns (bool) {
        return account < REDEMPTION_ADDRESS_COUNT && account != address(0);
    }
}
