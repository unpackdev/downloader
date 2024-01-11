// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Tradable.sol";

contract DAOMembership is ERC721Tradable {
    using Counters for Counters.Counter;
    uint16 public MAX_MEMBERS;
    uint64 public PRICE;
    address payable public DAO;

    Counters.Counter private _tokenIdCounter;

    event Rug(uint256 amount);
    event DAOChanged(address newDAO);

    constructor()
        ERC721Tradable(
            "DAO Membership",
            "DAO",
            0x7f268357A8c2552623316e2562D90e642bB538E5
        )
    {
        MAX_MEMBERS = 420;
        PRICE = 420 * 10**14;
        DAO = payable(msg.sender);
    }

    receive() external payable {
        mint();
    }

    function mint() public payable returns (uint256) {
        require(msg.value == PRICE, "Minting price is incorrect");
        require(
            _tokenIdCounter.current() < MAX_MEMBERS,
            "Maximum number of members reached"
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);
        return tokenId;
    }

    function rug() external {
        uint256 balance = address(this).balance;
        address payable to = payable(owner());
        to.transfer(address(this).balance);
        emit Rug(balance);
    }

    function setDAO(address newDAO) public onlyOwner {
        DAO = payable(newDAO);
        emit DAOChanged(DAO);
    }

    function baseTokenURI() public pure override returns (string memory) {
        return
            "https://raw.githubusercontent.com/32DAO/membership-nft/main/metadata/";
    }
}
