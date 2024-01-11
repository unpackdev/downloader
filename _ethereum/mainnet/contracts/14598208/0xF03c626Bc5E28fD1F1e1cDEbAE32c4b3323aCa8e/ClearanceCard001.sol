// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./base64.sol";

contract ClearanceCard001 is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public totalMint = 3000;
    uint256 public daoReserve = 200;
    uint256 public price = 0.15 ether;

    string[11] public URIs = [
        "https://sekerfactory.mypinata.cloud/ipfs/QmUkuyxyLR9UskihBcKBpkxHV5PuzmuCNwp1jPty811PwQ",
        "https://sekerfactory.mypinata.cloud/ipfs/QmfQFT67reWzd9DKohtmC8EfdnrQFEm7N4cHSCYT9sHuZC",
        "https://sekerfactory.mypinata.cloud/ipfs/QmQFHWJHFjYMogti4XEq9BALbuosjkdXTK5jGykdCKoHUt",
        "https://sekerfactory.mypinata.cloud/ipfs/QmSTC2gTipuWTPBxDvERZyp1Axoi7vgWPnrCX5yrHxTmKp",
        "https://sekerfactory.mypinata.cloud/ipfs/QmU1XWHwSMx95dYTyYxx6JaU1i81TDzcWFGYFYNU2B1QVH",
        "https://sekerfactory.mypinata.cloud/ipfs/QmTPmEBNJTVfDkAK7eDEZceqXzQ37co3QM1EssZKa1xdiB",
        "https://sekerfactory.mypinata.cloud/ipfs/QmWii6TdmVJAic5b5qeUr2uXDbd5izdAD8EYk9382Ew7cB",
        "https://sekerfactory.mypinata.cloud/ipfs/QmNYKTGxeMWo64KT8yzXzZLhMS2FR5dGQtLxkkkTHAJagi",
        "https://sekerfactory.mypinata.cloud/ipfs/QmegFhaEwpioKbuGVo3cbQGvoc6FauMaKyczFEfXqtWAyj",
        "https://sekerfactory.mypinata.cloud/ipfs/QmXkaN7DuXSF2X2hGF7tSEyTnDyMoCiMmvqLpvjh1ZSGEV",
        "https://sekerfactory.mypinata.cloud/ipfs/QmR6wRWH9N3sNhuroBGFZMR37G4ME85q25tTYZfvaz3RxM"
    ];

    mapping(uint256 => uint256) public cardLevels;

    event CardLevelUp(
        uint256 indexed id,
        uint256 indexed levels,
        uint256 indexed newLevel
    );
    event CardLevelDown(
        uint256 indexed id,
        uint256 indexed levels,
        uint256 indexed newLevel
    );

    constructor() ERC721("Seker Factory Clearance Cards 001", "SF001") {
        _transferOwnership(address(0x181e1ff49CAe7f7c419688FcB9e69aF2f93311da));
    }

    function mint(uint256 _amount) public payable {
        require(
            Counters.current(_tokenIds) <= totalMint,
            "minting has reached its max"
        );
        require(msg.value == price * _amount, "Incorrect eth amount");
        for (uint256 i; i <= _amount - 1; i++) {
            uint256 newNFT = _tokenIds.current();
            _safeMint(msg.sender, newNFT);
            _tokenIds.increment();
            cardLevels[newNFT] = 0;
        }
    }

    function mintDAO(uint256 _amount) public onlyOwner {
        require(
            Counters.current(_tokenIds) <= totalMint,
            "minting has reached its max"
        );
        for (uint256 i; i <= _amount - 1; i++) {
            require(daoReserve > 0, "dao reserve fully minted");
            uint256 newNFT = _tokenIds.current();
            _safeMint(msg.sender, newNFT);
            _tokenIds.increment();
            cardLevels[newNFT] = 10;
            daoReserve--;
        }
    }

    function levelUpCard(uint256 _id, uint256 _levels) public onlyOwner {
        require(cardLevels[_id] + _levels <= 10, "max level is 10");
        require(_exists(_id), "nonexistent id");
        cardLevels[_id] += _levels;
        emit CardLevelUp(_id, _levels, cardLevels[_id]);
    }

    function levelUpCardBatch(uint256[] memory _ids, uint256[] memory _levels)
        public
        onlyOwner
    {
        require(_ids.length == _levels.length, "length missmatch");
        for (uint256 i = 0; i < _ids.length; i++) {
            require(cardLevels[_ids[i]] + _levels[i] <= 10, "max level is 10");
            require(_exists(_ids[i]), "nonexistent id");
            cardLevels[_ids[i]] += _levels[i];
            emit CardLevelUp(_ids[i], _levels[i], cardLevels[_ids[i]]);
        }
    }

    function levelDownCard(uint256 _id, uint256 _levels) public onlyOwner {
        require(_exists(_id), "nonexistent id");
        cardLevels[_id] -= _levels;
        emit CardLevelDown(_id, _levels, cardLevels[_id]);
    }

    function levelDownCardBatch(uint256[] memory _ids, uint256[] memory _levels)
        public
        onlyOwner
    {
        require(_ids.length == _levels.length, "length missmatch");
        for (uint256 i = 0; i < _ids.length; i++) {
            require(_exists(_ids[i]), "nonexistent id");
            cardLevels[_ids[i]] -= _levels[i];
            emit CardLevelDown(_ids[i], _levels[i], cardLevels[_ids[i]]);
        }
    }

    function updateTotalMint(uint256 _newSupply) public onlyOwner {
        require(_newSupply > _tokenIds.current(), "new supply less than already minted");
        totalMint = _newSupply;
    }

    function updatePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "Clearance Cards: URI query for nonexistent token"
        );
        return generateCardURI(tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function generateCardURI(uint256 _id) public view returns (string memory) {
        uint256 level = cardLevels[_id];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Seker Factory 001 - DAO Member",',
                                '"description":"Membership to the Seker Factory 001 DAO. Holding this card secures your membership status and offers voting rights on proposals related to the 001 Los Angeles Factory and the 000 Metaverse Factory. Level up this card to receive more perks and governance rights within the 001 and 000 DAOs.",',
                                '"attributes": ',
                                "[",
                                '{"trait_type":"Level","value":"',
                                Strings.toString(level),
                                '"},',
                                '{"trait_type":"Membership Number","value":"',
                                Strings.toString(_id),
                                "/",
                                Strings.toString(totalMint),
                                '"}',
                                "],",
                                '"image":"',
                                URIs[level],
                                '",',
                                '"animation_url":"',
                                URIs[level],
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (to != address(0) && from != address(0)) {
            // we are transfering
            // reset level
            cardLevels[tokenId] = 0;
        }
    }

    // Withdraw
    function withdraw(address payable withdrawAddress)
        external
        payable
        onlyOwner
    {
        require(
            withdrawAddress != address(0),
            "Withdraw address cannot be zero"
        );
        require(address(this).balance >= 0, "Not enough eth");
        (bool sent, ) = withdrawAddress.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}
