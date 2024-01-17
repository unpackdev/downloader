// SPDX-License-Identifier: MIT

import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./JoinDAOContract.sol";
import "./ReentrancyGuard.sol";

pragma solidity ^0.8.0;

contract DaoToken is ERC20Burnable, Pausable, ReentrancyGuard {
    uint256 private _limit;
    uint256 private _price;
    address private _join_contract_address;

    constructor(string memory name, string memory symbol, address owner_of, uint256 presale_, uint256 limit_, uint256 price_) ERC20(name, symbol) Pausable(owner_of) {
        if (limit_ > 0) {
            require(limit_ >= presale_, "Limit overrized");
            JoinDAOContract join = new JoinDAOContract(address(this), price_, owner_of);
            _mint(address(join), limit_ - presale_);
            _join_contract_address = address(join);
        }
        if (presale_ > 0) {
            _mint(owner_of, presale_);
        }
        _limit = limit_;
        _price = price_;
    }

    function mint(uint256 amount_) public payable notPaused nonReentrant {
        require(_limit == 0, "Permission denied");
        if (_price > 0) {
            require(msg.value >= (_price * amount_) / 1 ether);
            payable(_owner_of).transfer(msg.value);
        }
        _mint(msg.sender, amount_);
    }

    function setPrice(uint256 price_) public {
        require(msg.sender == _owner_of, "Permissin denied");
        _price = price_;
    }

    function price() public view virtual returns (uint256) {
        return _price;
    }

    function limit() public view virtual returns (uint256) {
        return _limit;
    }

    function joinAddress() public view virtual returns (address) {
        return _join_contract_address;
    }
}
