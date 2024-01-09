// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ECDSA.sol";

contract YellowDAO is ERC721, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    enum Status {
        Pending,
        Claimable,
        Sale,
        Finished
    }

    Status public status;
    string public baseURI;
    address private _signer;
    uint256 public MAX_SUPPLY = 2000;
    uint256 public PRICE = 1E16;

    mapping(address => bool) public minted;

    event Minted(address minter);
    event StatusChanged(Status status);
    event SignerChanged(address signer);
    event BaseURIChanged(string newBaseURI);
    event SupplyChanged(uint256 supply);
    event PriceChanged(uint256 price);

    constructor(
        string memory initBaseURI,
        address signer,
        address recipient
    ) ERC721("YellowDAO", "Yellow") {
        baseURI = initBaseURI;
        _signer = signer;

        _safeMint(recipient, _tokenIds.current());
        _tokenIds.increment();
    }

    function _hash(string calldata salt, address _address)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(salt, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory token)
        internal
        view
        returns (bool)
    {
        return (_recover(hash, token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory token)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function claim(string calldata salt, bytes calldata token) external {
        require(
            status == Status.Claimable,
            "YellowDAO: NFT is not claimable now."
        );
        require(
            tx.origin == msg.sender,
            "YellowDAO: contract is now allowed to claim."
        );
        require(
            _verify(_hash(salt, msg.sender), token),
            "YellowDAO: Invalid token."
        );
        require(!minted[msg.sender], "YellowDAO: Already claimed.");
        uint256 _nextTokenId = _tokenIds.current();
        require(
            _nextTokenId + 1 <= MAX_SUPPLY,
            "YellowDAO: Max supply exceeded."
        );
        _safeMint(msg.sender, _nextTokenId);
        _tokenIds.increment();
        minted[msg.sender] = true;
        emit Minted(msg.sender);
    }

    function buy() external payable {
        require(status == Status.Sale, "YellowDAO: NFT is not on sale.");
        require(
            tx.origin == msg.sender,
            "YellowDAO: contract is now allowed to buy."
        );
        require(!minted[msg.sender], "YellowDAO: Already minted.");
        require(
            msg.value >= PRICE,
            "YellowDAO: Ether value sent is not enough."
        );
        uint256 _nextTokenId = _tokenIds.current();
        require(
            _nextTokenId + 1 <= MAX_SUPPLY,
            "YellowDAO: Max supply exceeded."
        );
        _safeMint(msg.sender, _nextTokenId);
        _tokenIds.increment();
        minted[msg.sender] = true;
        emit Minted(msg.sender);
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(_status);
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
        emit SignerChanged(signer);
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        MAX_SUPPLY = supply;
        emit SupplyChanged(supply);
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
        emit PriceChanged(_price);
    }
}
