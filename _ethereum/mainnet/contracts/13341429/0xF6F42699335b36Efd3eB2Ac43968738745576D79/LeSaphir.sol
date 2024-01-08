// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721Pausable.sol";
import "./Ownable.sol";

contract LeSaphir is ERC721Pausable, Ownable {
    uint256 private constant STARTING_PRICE = 0.2 ether;
    uint256 public numOwners = 0;

    uint256 public value = 0;
    uint256 public valueDeux = 0;

    mapping(address => uint256) private bank;
    uint256 private bankTotal = 0;

    event Procurement(address addr, uint256 value);
    event Withdrawal(address addr, uint256 value);

    constructor() ERC721("LeSaphir", "SAPHR") {
        _pause();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://remidutoit.com/lesaphir/metadata/";
    }

    function totalSupply() public pure returns (uint256) {
        return 1;
    }

    function leProprietaire() public view returns (address) {
        return ownerOf(0);
    }

    function lAncienProprietaire() public view returns (address) {
        return ownerOf(numOwners - 1);
    }

    function procurementPrice() public view returns (uint256) {
        if (numOwners == 0) {
            return STARTING_PRICE;
        } else {
            return value + valueDeux / 7;
        }
    }

    function _addToBank(address addr, uint256 amount) internal {
        bank[addr] += amount;
        bankTotal += amount;
    }

    function procure() external payable {
        if (numOwners == 0) {
            require(
                msg.value >= STARTING_PRICE,
                "Not enough value to procure Le Saphir..."
            );
            value = STARTING_PRICE;
            numOwners = 1;
            _safeMint(_msgSender(), 0);
            emit Procurement(_msgSender(), STARTING_PRICE);
        } else {
            uint256 _procurementPrice = procurementPrice();
            require(
                msg.value >= _procurementPrice,
                "Not enough value to procure Le Saphir..."
            );

            address _leProprietaire = leProprietaire();

            _addToBank(lAncienProprietaire(), valueDeux / 10);
            valueDeux = value;

            _addToBank(_leProprietaire, value);
            value = _procurementPrice;

            _safeMint(_leProprietaire, numOwners++);
            _safeTransfer(_leProprietaire, _msgSender(), 0, "");

            emit Procurement(_msgSender(), _procurementPrice);
        }
    }

    function balance() public view returns (uint256) {
        return bank[_msgSender()];
    }

    function withdraw() external {
        uint256 _balance = balance();
        require(_balance > 0, "No balance to withdraw");
        require(
            bankTotal >= _balance,
            "Not enough total money in the bank to withdraw"
        );
        delete bank[_msgSender()];
        bankTotal -= _balance;
        payable(_msgSender()).transfer(_balance);
        emit Withdrawal(_msgSender(), _balance);
    }

    function seeBalance(address payable addr)
        external
        view
        onlyOwner
        returns (uint256)
    {
        require(addr != address(0), "cannot see balance of the zero address");
        return bank[addr];
    }

    function ownerBalance() public view onlyOwner returns (uint256) {
        return address(this).balance - bankTotal;
    }

    function ownerWithdraw() external onlyOwner returns (bool) {
        uint256 _ownerBalance = ownerBalance();
        if (_ownerBalance > 0) {
            return payable(_msgSender()).send(_ownerBalance);
        }
        return true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    receive() external payable {}
}
