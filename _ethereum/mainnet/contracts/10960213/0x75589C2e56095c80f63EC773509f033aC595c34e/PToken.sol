// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract PToken is ERC20, Ownable {
    using SafeMath for uint256;

    ERC20 acceptedToken;  // ERC20 that is used for purchasing pToken
    uint256 public price; // The amount of aToken to purchase pToken

    event Initialized(address owner, uint256 price, uint256 supply);

    event Purchased(address buyer, uint256 cost, uint256 amountReceived);

    event Redeemed(address seller, uint256 amountRedeemed);

    event PriceUpdated(address owner, uint256 newPrice);

    event Minted(address owner, uint256 amountMinted);

    event Burned(address owner, uint256 amountBurned);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _price,
        uint256 _initialSupply,
        address _acceptedERC20
    ) ERC20(_name, _symbol) public {
        acceptedToken = ERC20(_acceptedERC20);
        price = _price;
        _mint(address(this), _initialSupply);

        emit Initialized(msg.sender, _price, _initialSupply);
    }

    function purchase(uint256 _amount) public {
        uint256 _allowance = acceptedToken.allowance(msg.sender, address(this));
        uint256 _cost = price.mul(_amount).div(10**18);
        require(_allowance >= _cost, "PToken: Not enough token allowance");

        acceptedToken.transferFrom(msg.sender, owner(), _cost);
        this.transfer(msg.sender, _amount);

        emit Purchased(msg.sender, _cost, _amount);
    }

    function redeem(uint256 _amount) public {
        transfer(address(this), _amount);

        emit Redeemed(msg.sender, _amount);
    }

    function updatePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;

        emit PriceUpdated(msg.sender, _newPrice);
    }

    // Allow only the owner to mint to this pool and not to other accounts
    function mint(uint256 _amount) public onlyOwner {
        _mint(address(this), _amount);

        emit Minted(msg.sender, _amount);
    }

    // Allow only the owner to burn from this pool and not other accounts
    function burn(uint256 _amount) public onlyOwner {
        _burn(address(this), _amount);

        emit Burned(msg.sender, _amount);
    }
}
