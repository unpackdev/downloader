/*

   _____ _     _ _           _____               _ 
  / ____| |   (_) |         |  __ \             (_)
 | (___ | |__  _| |__   __ _| |__) |__ _ __  ___ _ 
  \___ \| '_ \| | '_ \ / _` |  ___/ _ \ '_ \/ __| |
  ____) | | | | | |_) | (_| | |  |  __/ |_) \__ \ |
 |_____/|_| |_|_|_.__/ \__,_|_|   \___| .__/|___/_|
                                      | |          
                                      |_|   
    https://t.me/shibapepsi

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
contract ShibaPepsi is ERC20, WithdrawExtension {
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
        require(presaleActive, "ShibaPepsi: Presale is not active");
        uint256 _msgValue = msg.value;
        address _msgSender = msg.sender;

        uint256 _tokensToBuy = _msgValue.mul(10**decimals()).div(priceInWei);
        require(
            _tokensToBuy <= balanceOf(address(this)),
            "ShibaPepsi: Looks like you are trying to buy too many tokens"
        );
        _transfer(address(this), _msgSender, _tokensToBuy);

        emit BuyTokens(_msgSender, _tokensToBuy, _msgValue);
    }
}
