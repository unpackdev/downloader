// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./base64.sol";

contract TopClearanceCard is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public totalMint = 1500;
    uint256 public daoReserve = 100;
    uint256 public price = 0.5 ether;

    string[10] public URIs = [
        "https://sekerfactory.mypinata.cloud/ipfs/QmQ51zFLpCBhhi5h5sVr8Czi5CDaWWFvnvSkE9c1NexUiS",
        "https://sekerfactory.mypinata.cloud/ipfs/QmSSjyhK8nPZzFuPu33hiM8p6N4hYF615m1RbRimZuVY9e",
        "https://sekerfactory.mypinata.cloud/ipfs/Qmf7z53NFeEHx5Gu4PaVC4NfEVZj5DAdBG4rfpojqB5wNd",
        "https://sekerfactory.mypinata.cloud/ipfs/QmS2GzvNaTSqFCfhT4NUiMLsHDtwDBfDFe4d6vYUh3KpHp",
        "https://sekerfactory.mypinata.cloud/ipfs/QmXo1WUbZSW1SUowZ2YG6ZZFyWJyxrEBu1JikLdsvj1gy2",
        "https://sekerfactory.mypinata.cloud/ipfs/QmY2j7Ngbv2zMqYoXww5fAa185eEXVK1pZng8eGUtC1LT6",
        "https://sekerfactory.mypinata.cloud/ipfs/QmU6EiKGXhKJnUp47Nri2NURzTY1ZFxtbh1tC5pJ1zNCB4",
        "https://sekerfactory.mypinata.cloud/ipfs/QmU1kMfLu19ovnoGRtedicHEC7GdcJoA72ASmQabAtdkKu",
        "https://sekerfactory.mypinata.cloud/ipfs/QmY6jMvEXoCBFQ42D3qymMftua2WXkfgUBpbcvBmyZsF89",
        "https://sekerfactory.mypinata.cloud/ipfs/QmbExZ5rLx9i4TnGR8roNpCqy3iJFFpnFRLVpH8qcjftrb"
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

    constructor() ERC721("Seker Factory Top Clearance Cards", "SFTOP") {
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
            cardLevels[newNFT] = 1;
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
        require(cardLevels[_id] - _levels > 0, "level must be greater than 0");
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
            require(
                cardLevels[_ids[i]] - _levels[i] > 0,
                "level batch must be greater than 0"
            );
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
                                '{"name":"Seker Factory Top Clearance - DAO Member",',
                                '"description":"Top clearance membership to the Seker Factory DAOs. Holding this card secures your membership status and offers voting rights on proposals related to all factories. Level up this card to receive more perks and governance rights within the DAOs.",',
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
                                URIs[level - 1], // can place other image here
                                '",',
                                '"animation_url":"',
                                URIs[level - 1],
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
            cardLevels[tokenId] = 1;
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
