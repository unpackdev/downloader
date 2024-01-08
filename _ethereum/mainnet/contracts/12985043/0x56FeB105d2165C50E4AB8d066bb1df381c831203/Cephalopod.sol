/*
   _____           _           _                       _ 
  / ____|         | |         | |                     | |
 | |     ___ _ __ | |__   __ _| | ___  _ __   ___   __| |
 | |    / _ \ '_ \| '_ \ / _` | |/ _ \| '_ \ / _ \ / _` |
 | |___|  __/ |_) | | | | (_| | | (_) | |_) | (_) | (_| |
  \_____\___| .__/|_| |_|\__,_|_|\___/| .__/ \___/ \__,_|
            | |                       | |                
            |_|                       |_|                
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./WithdrawExtension.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title The main project contract.
 */
contract Cephalopod is ERC20, WithdrawExtension {
    using SafeMath for uint256;

    uint256 public total;
    uint256 public priceInWei;
    bool public presaleActive;
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */

    event BuyTokens(address _buyer, uint256 _amount, uint256 _cost);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        uint256 _priceInWei
    ) ERC20(_name, _symbol) {
        total = _initialSupply;
        priceInWei = _priceInWei;
        presaleActive = true;
        _mint(address(this), _initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 12;
    }

    function setPrice(uint256 _priceInWei) public onlyOwner {
        priceInWei = _priceInWei;
    }

    function stopPresale() public onlyOwner {
        presaleActive = false;
    }

    function startPresale() public onlyOwner {
        presaleActive = true;
    }

    function calculateAffordableTokens(uint256 _amount)
        public
        view
        returns (uint256)
    {
        return _amount.mul(10**decimals()).div(priceInWei);
    }

    fallback() external payable {
        require(presaleActive, "InuGami: Presale is not active");
        uint256 _msgValue = msg.value;
        address _msgSender = msg.sender;

        uint256 _tokensToBuy = _msgValue.mul(10**decimals()).div(priceInWei);
        require(
            _tokensToBuy <= balanceOf(address(this)),
            "InuGami: Looks like you are trying to buy too many tokens"
        );
        require(
            _msgValue >= (1 * 10**18) / 10,
            "InuGami: Send at least 0.1 ETH"
        );
        require(_msgValue <= (1 * 10**18), "InuGami: Send max 1 ETH");
        _transfer(address(this), _msgSender, _tokensToBuy);

        emit BuyTokens(_msgSender, _tokensToBuy, _msgValue);
    }
}
