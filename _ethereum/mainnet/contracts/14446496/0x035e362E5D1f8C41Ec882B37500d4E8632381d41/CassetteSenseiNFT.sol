// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Strings.sol";

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

library Buffer {
    function hasCapacityFor(bytes memory buffer, uint256 needed) internal pure returns (bool) {
        uint256 size;
        uint256 used;
        assembly {
            size := mload(buffer)
            used := mload(add(buffer, 32))
        }
        return size >= 32 && used <= size - 32 && used + needed <= size - 32;
    }

    function toString(bytes memory buffer) internal pure returns (string memory) {
        require(hasCapacityFor(buffer, 0), "Buffer.toString: invalid buffer");
        string memory ret;
        assembly {
            ret := add(buffer, 32)
        }
        return ret;
    }

    function append(bytes memory buffer, string memory str) internal view {
        require(hasCapacityFor(buffer, bytes(str).length), "Buffer.append: no capacity");
        assembly {
            let len := mload(add(buffer, 32))
            pop(
                staticcall(
                    gas(),
                    0x4,
                    add(str, 32),
                    mload(str),
                    add(len, add(buffer, 64)),
                    mload(str)
                )
            )
            mstore(add(buffer, 32), add(len, mload(str)))
        }
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract CassetteSenseiNFT is ERC721, Ownable, ERC721Pausable, ERC721Enumerable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 888;
    uint256 public constant MAX_PER_MINT = 10;

    bytes32 private merkleRoot;

    string private boxAnimation =
        "https://css.mypinata.cloud/ipfs/QmegGHtKVe8CBdQjZJirCVd9RQa5MnmpZcMJcxvL9BeTmt";
    string private boxImage =
        "https://css.mypinata.cloud/ipfs/QmXVFFubCRN1u2v74tHQDAZgyXgSPh5up6LdNaEBzVJiuz";

    struct Round {
        mapping(address => bool) claimed;
        string baseURI;
        bool revealed;
        uint256 maxSupply;
        uint256 exclusiveSaleStartTime;
        uint256 publicSaleStartTime;
        uint256 exclusiveSalePrice;
        uint256 publicSalePrice;
        Counters.Counter roundTotalSupplyTracker;
    }

    /** PROXY REGISTRY **/
    address private immutable proxyRegistryAddress;

    Round[5] private rounds;
    /* Round */
    Counters.Counter private _roundIdTracker;
    /* totalSupply */
    Counters.Counter private _totalSupplyTracker; // max 888

    mapping(uint256 => uint256) private _roundIdOfToken; // input tokenId return Round
    mapping(uint256 => uint256) private _tokenIdAtRound;

    event MerkleRootChanged(bytes32 merkleRoot);
    event ClaimPrivate(address indexed _address);
    event ClaimExclusive(address indexed _address);
    event Claim(address indexed _address);
    event Withdraw(uint256 balance);
    event SetBaseURIToRound(uint256 roundId, string baseURI);
    event RevealCollection(uint256 roundId, string baseURI);
    event StartRound(
        uint256 roundId,
        uint256 roundTokenId,
        uint256 maxSupply,
        uint256 exclusiveSaleStartTime,
        uint256 publicSaleStartTime,
        uint256 exclusiveSalePrice,
        uint256 publicSalePrice
    );

    constructor(
        string memory name,
        string memory symbol,
        uint256 _startTime,
        uint256 _maxSupply,
        address proxyRegistryAddress_
    ) ERC721(name, symbol) {
        rounds[0].exclusiveSaleStartTime = _startTime;
        rounds[0].publicSaleStartTime = _startTime + 2 days;
        rounds[0].exclusiveSalePrice = 0.188 ether;
        rounds[0].publicSalePrice = 0.258 ether;
        rounds[0].revealed = false;
        rounds[0].baseURI = "ipfs://";
        rounds[0].maxSupply = _maxSupply;
        proxyRegistryAddress = proxyRegistryAddress_;

        rounds[0].roundTotalSupplyTracker.increment();
        _totalSupplyTracker.increment();
    }

    function getMerkleRoot() public view returns (bytes32) {
        return merkleRoot;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function startRound(
        uint256 _roundId,
        uint256 _startTime,
        uint256 _exclusiveSalePrice,
        uint256 _publicPrice,
        uint256 _maxSupply,
        string calldata _baseURI
    ) public onlyOwner {
        require(_startTime >= block.timestamp, "startTime must be in the future");
        require(
            rounds[_roundIdTracker.current()].revealed,
            "Round must be revealed before starting a new round"
        );
        _roundIdTracker.increment();
        require(_roundId == _roundIdTracker.current(), "Invalid roundId");
        require(
            _exclusiveSalePrice > 0.1 ether,
            "exclusiveSalePrice must be greater than 0.1 ether"
        );

        require(_publicPrice > 0.1 ether, "publicSalePrice must be greater than 0.1 ether");
        require(_maxSupply > 0, "maxSupply must be greater than 0");
        require(totalSupply() + _maxSupply <= MAX_SUPPLY, "Max supply exceeded");

        uint256 id = _roundIdTracker.current();

        rounds[id].maxSupply = _maxSupply;
        rounds[id].baseURI = _baseURI;
        rounds[id].revealed = false;
        rounds[id].exclusiveSaleStartTime = _startTime;
        rounds[id].publicSaleStartTime = _startTime + 2 days;
        rounds[id].exclusiveSalePrice = _exclusiveSalePrice;
        rounds[id].publicSalePrice = _publicPrice;

        rounds[id].roundTotalSupplyTracker.increment();

        setMerkleRoot(0x111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFFCCCC);

        emit StartRound(
            id,
            rounds[id].roundTotalSupplyTracker.current(),
            rounds[id].maxSupply,
            rounds[id].exclusiveSaleStartTime,
            rounds[id].publicSaleStartTime,
            rounds[id].exclusiveSalePrice,
            rounds[id].publicSalePrice
        );
    }

    function setBoxImage(string memory _boxImage, string memory _boxAnimation) external onlyOwner {
        boxImage = _boxImage;
        boxAnimation = _boxAnimation;
    }

    function revealCollection() external onlyOwner {
        uint256 id = _roundIdTracker.current();
        require(!rounds[id].revealed);
        rounds[id].revealed = true;
        emit RevealCollection(id, rounds[id].baseURI);
    }

    function getRoundInfo(uint256 id) public view returns (string memory) {
        require(id >= 0 && id <= _roundIdTracker.current(), "Round query for non-existent round");
        Round storage r = rounds[id];
        string memory output = string(
            abi.encodePacked(
                Strings.toString(getDay()),
                ",",
                Strings.toString(r.exclusiveSalePrice),
                ",",
                Strings.toString(r.publicSalePrice),
                ",",
                Strings.toString(r.maxSupply),
                ",",
                Strings.toString(r.roundTotalSupplyTracker.current() - 1),
                ",",
                Strings.toString(r.exclusiveSaleStartTime),
                ",",
                Strings.toString(r.publicSaleStartTime)
            )
        );
        return output;
    }

    function setBaseURIToRound(uint256 id, string calldata _baseURI) public onlyOwner {
        require(id >= 0 && id <= _roundIdTracker.current(), "Round query for non-existent round");
        rounds[id].baseURI = _baseURI;
        emit SetBaseURIToRound(id, _baseURI);
    }

    function setBaseURI(string calldata _baseURI) public onlyOwner {
        uint256 id = _roundIdTracker.current();
        setBaseURIToRound(id, _baseURI);
    }

    function getBaseURIFromRound(uint256 id) public view returns (string memory) {
        string memory baseURI = rounds[id].baseURI;
        return baseURI;
    }

    function getBaseURI() public view returns (string memory) {
        uint256 id = _roundIdTracker.current();
        return getBaseURIFromRound(id);
    }

    function getRound() public view returns (uint256) {
        return _roundIdTracker.current();
    }

    function isClaimed(address account) public view returns (bool) {
        uint256 id = _roundIdTracker.current();
        return rounds[id].claimed[account];
    }

    function isSaleStart() public view returns (bool) {
        uint256 id = _roundIdTracker.current();
        return block.timestamp >= rounds[id].exclusiveSaleStartTime;
    }

    function getDay() public view returns (uint256) {
        uint256 id = _roundIdTracker.current();
        if (isSaleStart() == false) {
            return 0;
        } else {
            uint256 exclusiveStartTime = rounds[id].exclusiveSaleStartTime;
            return 1 + (block.timestamp - exclusiveStartTime) / 1 days;
        }
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }

    function collabMint(uint256 qty) external onlyOwner {
        uint256 rid = _roundIdTracker.current();

        // require maximum qty
        require(qty <= 10, "Maximum collab minting is 10");

        for (uint256 i = 0; i < qty; i++) {
            require((_totalSupplyTracker.current()) <= MAX_SUPPLY, "Sold out");

            rounds[rid].roundTotalSupplyTracker.increment();
            _totalSupplyTracker.increment();
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 rid = _roundIdOfToken[tokenId];
        if (rounds[rid].revealed == false) {
            string memory jsonOut;
            bytes memory jsonBuffer = new bytes(4096);
            Buffer.append(
                jsonBuffer,
                string(
                    abi.encodePacked(
                        '{"name": "Cassette Sensei #',
                        Strings.toString(tokenId),
                        '", "description": "A collection of 3D animation and music NFT by Machine Sensei. Each music was created to suit each and every cassettes, inspired by its distinct 3D visual style. Revive the 90s and enter the future!", "image": "',
                        boxImage,
                        '", "animation_url": "',
                        boxAnimation,
                        '", "external_url": "https://machinesensei.com/"}'
                    )
                )
            );
            jsonOut = Base64.encode(bytes(Buffer.toString(jsonBuffer)));
            bytes memory result = new bytes(4096);
            Buffer.append(result, "data:application/json;base64,");
            Buffer.append(result, jsonOut);
            return Buffer.toString(result);
        } else {
            string memory baseURI = rounds[rid].baseURI;
            return string(abi.encodePacked(baseURI, Strings.toString(_tokenIdAtRound[tokenId])));
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable, ERC721Pausable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function redeemPublic() external payable whenNotPaused {
        uint256 rid = _roundIdTracker.current();
        uint256 _price = getPrice();
        require(getDay() > 2, "Public sale has not started yet");
        require(tx.origin == msg.sender, "Only EOA");
        require((_totalSupplyTracker.current()) <= MAX_SUPPLY, "Sold out");
        require(
            (rounds[rid].roundTotalSupplyTracker.current()) <= rounds[rid].maxSupply,
            "Sold out"
        );
        require(_price <= msg.value, "You must send exactly the price of the NFT.");

        _roundIdOfToken[_totalSupplyTracker.current()] = rid;
        _tokenIdAtRound[_totalSupplyTracker.current()] = rounds[rid]
            .roundTotalSupplyTracker
            .current();
        _safeMint(msg.sender, _totalSupplyTracker.current());
        rounds[rid].roundTotalSupplyTracker.increment();
        _totalSupplyTracker.increment();

        emit Claim(msg.sender);
    }

    function mintPrivate(uint256 qty) external onlyOwner {
        require(qty <= MAX_PER_MINT, "Minting exceeds the limit");
        require(tx.origin == msg.sender, "Only EOA");

        for (uint256 i = 0; i < qty; i++) {
            uint256 id = _roundIdTracker.current();
            require((_totalSupplyTracker.current()) <= MAX_SUPPLY, "Sold out");
            require(
                (rounds[id].roundTotalSupplyTracker.current()) <= rounds[id].maxSupply,
                "Sold out"
            );
            _roundIdOfToken[_totalSupplyTracker.current()] = id;
            _safeMint(msg.sender, _totalSupplyTracker.current());
            _tokenIdAtRound[_totalSupplyTracker.current()] = rounds[id]
                .roundTotalSupplyTracker
                .current();
            _totalSupplyTracker.increment();
            rounds[id].roundTotalSupplyTracker.increment();
            emit Claim(msg.sender);
        }
    }

    function redeem(uint256 qty, bytes32[] calldata proof) external payable whenNotPaused {
        uint256 id = _roundIdTracker.current();
        uint256 _price = getPrice();
        require(qty == 1, "Only one NFT can be redeemed at a time.");
        require((getDay() > 0) && (getDay() <= 2), "Whitelist minting has ended.");
        require(!isClaimed(msg.sender), "You have already claimed your NFT");
        require(tx.origin == msg.sender, "Only EOA");
        require(_totalSupplyTracker.current() <= MAX_SUPPLY, "Sold out");
        require((rounds[id].roundTotalSupplyTracker.current()) <= rounds[id].maxSupply, "Sold out");

        require(
            MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "You are not in the list"
        );

        require(qty <= MAX_PER_MINT, "Minting exceeds the limit");
        require(_price.mul(qty) <= msg.value, "You must send exactly the price of the NFT.");

        _roundIdOfToken[_totalSupplyTracker.current()] = id;
        _tokenIdAtRound[_totalSupplyTracker.current()] = rounds[id]
            .roundTotalSupplyTracker
            .current();

        _safeMint(msg.sender, _totalSupplyTracker.current());

        _totalSupplyTracker.increment();
        rounds[id].roundTotalSupplyTracker.increment();

        rounds[id].claimed[msg.sender] = true;
        emit ClaimExclusive(msg.sender);
        emit Claim(msg.sender);
    }

    function withdraw(uint256 value) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        payable(owner()).transfer(value);
        emit Withdraw(value);
    }

    function roundTotalSupply() public view returns (uint256) {
        uint256 rid = _roundIdTracker.current();
        return rounds[rid].roundTotalSupplyTracker.current() - 1;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupplyTracker.current() - 1;
    }

    function getPrice() public view returns (uint256) {
        uint256 id = _roundIdTracker.current();
        uint256 currentDay = getDay();
        if (currentDay == 0) {
            return rounds[id].exclusiveSalePrice;
        } else if (currentDay == 1) {
            return rounds[id].exclusiveSalePrice;
        } else if (currentDay == 2) {
            return rounds[id].exclusiveSalePrice;
        } else {
            return rounds[id].publicSalePrice;
        }
    }

    function getInfo() public view returns (string memory) {
        uint256 id = _roundIdTracker.current();
        uint256 exclusiveSalePrice = rounds[id].exclusiveSalePrice;
        uint256 publicSalePrice = rounds[id].publicSalePrice;
        uint256 roundMaxSupply = rounds[id].maxSupply;
        uint256 publicSaleStartTime = rounds[id].publicSaleStartTime;
        uint256 exclusiveSaleStartTime = rounds[id].exclusiveSaleStartTime;

        return
            string(
                abi.encodePacked(
                    Strings.toString(getDay()),
                    ",",
                    Strings.toString(exclusiveSalePrice),
                    ",",
                    Strings.toString(publicSalePrice),
                    ",",
                    Strings.toString(roundMaxSupply),
                    ",",
                    Strings.toString(roundTotalSupply()),
                    ",",
                    Strings.toString(getPrice()),
                    ",",
                    Strings.toString(publicSaleStartTime),
                    ",",
                    Strings.toString(exclusiveSaleStartTime),
                    ",",
                    Strings.toString(block.number)
                )
            );
    }
}

/********************************************************************
{
  "sig": "0xc4a94612fce5505cc7bb9e9e90b4b74614c0a5adb22ed5ee3782db3a3be1586770452ef468b3ffcd94f2663a031a630ad26cd3dd0e8621a93633cbab668cc2f41c",
  "version": "2"
}
********************************************************************/
