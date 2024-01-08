// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Token.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract EthSwap is Ownable {
    using SafeMath for uint256;
    string public name = "Instruaud Token Sale";
    Token public token;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 public rate = 99;

    // Amount of wei raised
    uint256 public weiRaised;

    // Amount of Tokens sold
    uint256 public tokensSold;

    uint256 private _saleCap = 7500e18;
    address payable ownerAccount;

    mapping(address => mapping(address => uint256)) public tokens;

    event TokensPurchased(
        address account,
        address token,
        uint256 amount,
        uint256 rate
    );

    constructor(Token _token) public {
        token = _token;
        ownerAccount = msg.sender;
    }

    /**
     * @dev Returns the saleCap of the contract.
     */
    function saleCap() public view returns (uint256) {
        return _saleCap;
    }

    // Update saleCap.
    function saleCapUpdate(uint256 _newSaleCap) public onlyOwner {
        _saleCap = _newSaleCap;
    }

    // o parâmetro do buyTokens é o msg.value
    function buyTokens() public payable {
        uint256 weiAmount = msg.value;
        // calculate token amount to be created
        uint256 tokenAmount = _getTokenAmount(weiAmount);

        // Check CAP
        require(tokensSold <= _saleCap);

        // Transfer tokens to the user
        token.mint(msg.sender, tokenAmount);

        // estou transferindo para mim o msg value.
        ownerAccount.transfer(msg.value);

        // update wei raised state
        weiRaised = weiRaised.add(weiAmount);
        // update tokens sold state
        tokensSold = tokensSold.add(tokenAmount);

        // Emit an event
        emit TokensPurchased(msg.sender, address(token), tokenAmount, rate);
    }

    function changeRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount)
        internal
        view
        returns (uint256)
    {
        return weiAmount.mul(rate);
    }
}
