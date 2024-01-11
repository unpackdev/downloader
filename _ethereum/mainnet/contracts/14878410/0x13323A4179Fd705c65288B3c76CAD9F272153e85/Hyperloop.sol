// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*

   ________  ________  ________  ________  ________  _______   ________  ________  ________ 
  ╱    ╱   ╲╱    ╱   ╲╱        ╲╱        ╲╱        ╲╱       ╲ ╱        ╲╱        ╲╱        ╲
 ╱         ╱         ╱         ╱         ╱         ╱        ╱╱         ╱         ╱         ╱
╱         ╱╲__      ╱       __╱        _╱        _╱        ╱╱         ╱         ╱       __╱ 
╲___╱____╱   ╲_____╱╲______╱  ╲________╱╲____╱___╱╲________╱╲________╱╲________╱╲______╱    

By Umberto Ciceri

Smart contract development by Alberto Granzotto <https://www.granzotto.net/>

*/

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";

contract Hyperloop is ERC1155, Ownable {
    using Strings for uint256;

    event CollectionCreated(address from, uint256 collectionId);
    event CollectionUpdated(address from, uint256 collectionId);
    event CollectionDeleted(address from, uint256 collectionId);

    struct Collection {
        uint256 offset;
        uint8 mintedSquare;
        uint8 minted;
        string cid;
    }

    mapping(uint256 => Collection) public collections;
    address public shop;
    string public ipfsGateway;

    modifier onlyMinter() {
        require(_msgSender() == owner() || _msgSender() == shop);
        _;
    }

    constructor() ERC1155("") {
        ipfsGateway = "https://nftstorage.link/ipfs/";
    }

    function setShop(address a) public onlyOwner {
        shop = a;
    }

    function setIPFSGateway(string calldata s) public onlyOwner {
        ipfsGateway = s;
    }

    function uri(uint256 id) public view override returns (string memory) {
        uint256 collectionId = id / 1000;
        uint256 tokenId = id - collectionId * 1000;
        Collection storage c = collections[collectionId];
        // If it's a square
        if (tokenId >= 100) {
            if (c.offset > 0) {
                uint256 finalTokenId = collectionId *
                    1000 +
                    100 +
                    ((tokenId + c.offset) % 150);
                return
                    string(
                        abi.encodePacked(
                            ipfsGateway,
                            c.cid,
                            "/",
                            finalTokenId.toString(),
                            ".json"
                        )
                    );
            } else {
                return
                    string(
                        abi.encodePacked(
                            ipfsGateway,
                            c.cid,
                            "/square-placeholder.json"
                        )
                    );
            }
        }
        return
            string(
                abi.encodePacked(
                    ipfsGateway,
                    c.cid,
                    "/",
                    id.toString(),
                    ".json"
                )
            );
    }

    function requireCollection(Collection memory c) internal pure {
        require(bytes(c.cid).length > 0, "Hyperloop: collection doesn't exist");
    }

    function addCollection(uint256 id, string memory cid_) public onlyOwner {
        Collection storage c = collections[id];
        require(bytes(c.cid).length == 0, "Hyperloop: collection exists");
        c.cid = cid_;
        emit CollectionCreated(_msgSender(), id);
    }

    function addCollections(uint256[] calldata ids, string[] memory cids)
        public
        onlyOwner
    {
        for (uint256 i; i < ids.length; i++) {
            addCollection(ids[i], cids[i]);
        }
    }

    function updateCollection(uint256 id, string memory cid_) public onlyOwner {
        Collection storage c = collections[id];
        requireCollection(c);
        c.cid = cid_;
        emit CollectionUpdated(_msgSender(), id);
    }

    function deleteCollection(uint256 id) public onlyOwner {
        Collection storage c = collections[id];
        requireCollection(c);
        require(
            c.minted == 0 && c.mintedSquare == 0,
            "Hyperloop: collection not empty"
        );
        delete collections[id];
        emit CollectionDeleted(_msgSender(), id);
    }

    function mintMatrix(address account, uint256 collectionId)
        public
        onlyMinter
    {
        // There is 1 matrix per collection
        Collection storage c = collections[collectionId];
        requireCollection(c);
        require(c.minted & 0x80 == 0, "Hyperloop: token exists");
        _mint(account, collectionId * 1000, 1, "");
        c.minted |= 0x80;
    }

    function mintCube(
        address account,
        uint256 collectionId,
        uint8 tokenId
    ) public onlyMinter {
        // There are 7 cube per collection
        require(tokenId < 7, "Hyperloop: wrong id");
        Collection storage c = collections[collectionId];
        requireCollection(c);
        require(c.minted & (1 << tokenId) == 0, "Hyperloop: token exists");
        _mint(account, collectionId * 1000 + 10 + tokenId, 1, "");
        c.minted |= uint8(1 << tokenId);
    }

    function mintSquare(
        address account,
        uint256 collectionId,
        uint8 amount
    ) public onlyMinter {
        // There are 150 square per collection
        Collection storage c = collections[collectionId];
        requireCollection(c);
        require(
            c.mintedSquare + amount <= 150,
            "Hyperloop: no tokens available"
        );

        if (amount == 1) {
            _mint(account, collectionId * 1000 + 100 + c.mintedSquare, 1, "");
        } else {
            uint256[] memory ids = new uint256[](amount);
            uint256[] memory amounts = new uint256[](amount);
            for (uint256 i = 0; i < amount; i++) {
                ids[i] = collectionId * 1000 + 100 + i + c.mintedSquare;
                amounts[i] = 1;
            }
            _mintBatch(account, ids, amounts, "");
        }

        c.mintedSquare += amount;

        if (c.mintedSquare == 150) {
            c.offset = uint256(blockhash(block.number - 1));
        }
    }
}
