// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";


contract RoyaltyManager is Ownable {

    struct Data {
        uint256 royaltyBPS;
        bool    isVal;
    }

    address public royaltyRecipient = 0xE7229E461FD342899e7e1659E3ecA9F0E4f6FB08;
    uint256 public defaultRoyaltyBPS = 250;

    mapping(address => Data) public contractToRoyaltyBPS;

    event DefaultRoyaltiesUpdated(uint256 _newRoyaltyBPS);
    event RoyaltiesUpdated(address _contract, uint256 _newRoyaltyBPS);
    event RoyaltyRecipientUpdated(address _royaltyRecipient);
    
    function getRoyalties(address _contract) public view returns (uint256) {
        if (contractToRoyaltyBPS[_contract].isVal) {
            return contractToRoyaltyBPS[_contract].royaltyBPS;
        } else {
            return defaultRoyaltyBPS;
        }
    }

    function setRoyaltyRecipient(address _royaltyRecipient) public onlyOwner {
        royaltyRecipient = _royaltyRecipient;
        emit RoyaltyRecipientUpdated(_royaltyRecipient);
    }

    function setContractRoyalties(address _contract, uint256 _royaltyBPS) public onlyOwner {
        contractToRoyaltyBPS[_contract] = Data(_royaltyBPS, true);
        emit RoyaltiesUpdated(_contract, _royaltyBPS);
    }

    function setDefaultRoyaltyBPS(uint256 _royaltyBPS) public onlyOwner {
        defaultRoyaltyBPS = _royaltyBPS;
        emit DefaultRoyaltiesUpdated(_royaltyBPS);
    }
}