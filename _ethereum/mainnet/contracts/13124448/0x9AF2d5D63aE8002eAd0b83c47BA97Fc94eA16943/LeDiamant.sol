// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721Pausable.sol";
import "./Ownable.sol";

contract LeDiamant is ERC721Pausable, Ownable {
    string private constant metadataURI =
        "ipfs://QmUCF7QKb7y65wFUkaBZbvbYz9uG8EEadEpxLNSdgcN81e";
    string private constant exOwnerMetadataURI =
        "ipfs://QmY7rBdJQe9P2T3eHvs1U1PTGgE1pNKbqEXJY1Z5DKgwh9";

    uint256 public value = 0.2 ether;
    uint256 public valueDeux = 0;

    mapping(address => uint256) private bank;
    uint256 private bankTotal = 0;

    event Procurement(address addr, uint256 value);
    event Withdrawal(address addr, uint256 value);

    constructor() ERC721("LeDiamant", "DMNT") {
        _safeMint(owner(), 1);
        _safeMint(owner(), 2);
        _pause();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (tokenId == 1) {
            return metadataURI;
        } else if (tokenId == 2) {
            return exOwnerMetadataURI;
        } else return "";
    }

    function leProprietaire() public view returns (address) {
        return ownerOf(1);
    }

    function lAncienProprietaire() public view returns (address) {
        return ownerOf(2);
    }

    function procurementPrice() public view returns (uint256) {
        return value + valueDeux / 7;
    }

    function _addToBank(address addr, uint256 amount) internal {
        bank[addr] += amount;
        bankTotal += amount;
    }

    function procure() external payable {
        uint256 _procurementPrice = procurementPrice();
        require(
            msg.value >= _procurementPrice,
            "Not enough value to procure Le Diamant..."
        );

        _addToBank(lAncienProprietaire(), valueDeux / 10);
        _safeTransfer(lAncienProprietaire(), leProprietaire(), 2, "");
        valueDeux = value;

        _addToBank(leProprietaire(), value);
        _safeTransfer(leProprietaire(), _msgSender(), 1, "");
        value = _procurementPrice;

        emit Procurement(_msgSender(), _procurementPrice);
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
