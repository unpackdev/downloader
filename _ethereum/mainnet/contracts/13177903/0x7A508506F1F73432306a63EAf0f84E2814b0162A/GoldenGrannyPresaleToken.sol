// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC1155PresetMinterPauser.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./EnumerableSet.sol";

contract GoldenGrannyPresaleToken is ERC1155PresetMinterPauser, Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    EnumerableSet.AddressSet private allowedAddresses;
    EnumerableSet.AddressSet private allOwners;

    uint256 tokenPriceForUnallowedAddresses = 0.01 ether;

    constructor() ERC1155PresetMinterPauser("") {
    }

    function mintPublicFlag(uint256 tokenId) payable public whenNotPaused {
        require (
            tokenId <= _tokenIds.current() && (allowedAddresses.contains(msg.sender) || msg.value == tokenPriceForUnallowedAddresses),
            "Not allowed to mint"
        );
        allowedAddresses.remove(msg.sender);
        allOwners.add(msg.sender);
        _mint(msg.sender, tokenId, 1, "");
    }
    
    function tokenCount(address user) private view returns (uint256) {
        uint256 result = 0;
        for (uint index = 0; index < _tokenIds.current(); index++) {
            result += balanceOf(user, index);
        }
        return result;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            if (from != address(0x0) && balanceOf(from, ids[i]) == 1) {
                // The seller will not own any new tokens after the transaction
                if (tokenCount(from) == 1) {
                    allOwners.remove(from);
                }
            }
            allOwners.add(to);
        }
    }

    function setURI(string memory newuri) public virtual onlyOwner {
        _setURI(newuri);
    }

    function withdraw() public onlyOwner {
        uint256 withdrawableFunds = address(this).balance;
        payable(msg.sender).transfer(withdrawableFunds);
    }

    function allowAddresses(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowedAddresses.add(addresses[i]);
        }
    }

    function getAllowedAddresses() public view onlyOwner returns (address[] memory) {
        return allowedAddresses.values();
    }

    function getOwners() public view onlyOwner returns (address[] memory) {
        return allOwners.values();
    }

    function isAllowed() public view returns (bool) {
        return allowedAddresses.contains(msg.sender);
    }

    function isOwner(address add) public view returns (bool) {
        return allOwners.contains(add);
    }

    function disallowAddresses(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowedAddresses.remove(addresses[i]);
        }
    }

    function addNewFlags(uint256 count) public onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            allOwners.add(msg.sender);
            // Granny is international, she owns one token for each flag!
            _mint(msg.sender, newTokenId, 1, "");
        }
    }

    function changeTokenPriceForUnallowedAddresses(uint256 newPrice) public onlyOwner {
        tokenPriceForUnallowedAddresses = newPrice;
    }
}