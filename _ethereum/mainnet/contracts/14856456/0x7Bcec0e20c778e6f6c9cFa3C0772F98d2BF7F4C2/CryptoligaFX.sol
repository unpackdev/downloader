// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title CryptoligaFX
 * @author Peter Smith
 * @dev CryptoligaFX enables purchases in any ERC20 coin
 *
 **/

import "./SafeERC20.sol";

abstract contract CryptoligaFX {
    using SafeERC20 for IERC20;

    mapping(string => address) private coinAddress;
    mapping(string => uint256) private coinPrice;
    mapping(string => bool) private coinActive;
    string[] private coins;

    event RemovedCoin(string coin);
    event AddedCoin(string coin, address _address, uint256 _price);

    function _addCoin(
        string memory _symbol,
        address _address,
        uint256 _price
    ) internal virtual {
        require(!coinActive[_symbol], "CoinExists");

        coinAddress[_symbol] = _address;
        coinPrice[_symbol] = _price;
        coinActive[_symbol] = true;
        coins.push(_symbol);
        emit AddedCoin(_symbol, _address, _price);
    }

    function _setCoinPrice(string memory _coinSymbol, uint256 _price)
        internal
        virtual
    {
        coinPrice[_coinSymbol] = _price;
    }

    function _getCoinPrice(string memory _coinSymbol)
        internal
        view
        virtual
        returns (uint256)
    {
        return coinPrice[_coinSymbol];
    }

    function _removeCoin(string memory _coinSymbol) internal virtual {
        require(coinActive[_coinSymbol], "CoinNotFound");

        delete coinAddress[_coinSymbol];
        delete coinPrice[_coinSymbol];
        delete coinActive[_coinSymbol];
        uint i = 0;
        while (i < coins.length) {
            if (
                keccak256(abi.encodePacked(coins[i])) ==
                keccak256(abi.encodePacked(_coinSymbol))
            ) {
                coins[i] = coins[coins.length - 1];
                coins.pop();
                emit RemovedCoin(_coinSymbol);
            } else {
                i++;
            }
        }
    }

    /**
     * @dev Handles the payment part of fx minting.
     * Child contracts must call the mint function after calling this.
     *
     */
    function _fxPurchase(uint256 numberToMint, string memory _coinSymbol)
        internal
        virtual
    {
        uint256 _totalPrice = numberToMint * coinPrice[_coinSymbol];

        IERC20 paymentToken = IERC20(coinAddress[_coinSymbol]);

        require(coinPrice[_coinSymbol] > 0, "CoinInvalid");

        require(
            paymentToken.balanceOf(msg.sender) >= _totalPrice,
            "NoBalance"
        );

        require(
            paymentToken.allowance(msg.sender, address(this)) >= _totalPrice,
            "NoAllowance"
        );

        paymentToken.safeTransferFrom(msg.sender, address(this), _totalPrice);
    }

    function _withdrawAll() internal virtual {
        for (uint i = 0; i < coins.length; i++) {
            string memory _token = coins[i];
            _withdrawCoin(_token);
        }
    }

    function _withdrawCoin(string memory _coinSymbol) internal virtual {
        address _address = coinAddress[_coinSymbol];
        IERC20 _tokenContract = IERC20(_address);
        uint _balance = _tokenContract.balanceOf(address(this));
        if (_balance > 0) {
            _tokenContract.safeTransfer(msg.sender, _balance);
        }
    }
}
