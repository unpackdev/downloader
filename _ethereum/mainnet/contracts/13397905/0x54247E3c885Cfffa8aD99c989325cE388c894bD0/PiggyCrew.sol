// SPDX-License-Identifier: MIT
/*
    ▄█▀▀▀█▄█    ▄█▀▀▀█▄█
    ██    ▀██   ██    ▀█
    ██     ██   ██
    █▀████▀     ██
    ██          ██    ▄█
    ██          ▀█▄▄▄█▀█

    PiggyCrew / 2021 / V1.0
*/

pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./SignatureChecker.sol";
import "./ECDSA.sol";
import "./PiggyStorageV0.sol";

contract PiggyCrew is ERC721, Ownable, PiggyStorageV0 {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    using SignatureChecker for address;

    // reserve batch size
    uint256 public constant reserveBatchNum = 1;

    // withdraw ETH address
    address public t1;

    modifier onlyOwnerOrAdmin {
        require(msg.sender == owner() || msg.sender == whitelistSigner, "onlyOwnerOrAdmin: sender have not access");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _price,
        uint256 _whitelistPrice,
        uint256 _maxPurchaseNum,
        uint256 _maxSupply,
        uint256 _reserveNum,
        address _signer
    ) ERC721(_name, _symbol) {
        baseURI = _uri;
        price = _price;
        whitelistPrice = _whitelistPrice;
        t1 = msg.sender;
        maxPurchaseNum = _maxPurchaseNum;
        maxSupply = _maxSupply;
        reserveNum = _reserveNum;
        whitelistSigner = _signer;
    }

    /**
     * @dev Override _baseURI, so that tokenURI could use it as base.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev withdraw eth paid in mint and presale
     */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(t1).transfer(balance);
    }

    /**
     * @dev give away NFTs
     */
    function giveAway(address _to, uint256 _amount) external onlyOwnerOrAdmin {
        for (uint256 i; i < _amount; i++) {
            if (id.current() < maxSupply) {
                uint256 id = _nextId();
                _safeMint(_to, id);
            }
        }
    }
    /**
     * @dev reserve some NFTs aside
     */
    function reserve() public onlyOwner {
        uint256 toReserve = reserveNum - mintedReserveNum;
        uint256 batch = reserveBatchNum < toReserve ? reserveBatchNum : toReserve;
        uint256 beforeReserve = id.current();
        require(beforeReserve + batch <= maxSupply, "Reserving would exceed max supply");
        for (uint256 i = 0; i < batch; i++) {
            _mint();
        }
        uint256 afterReserve = id.current();
        mintedReserveNum += afterReserve - beforeReserve;
    }

    function setMintingState(bool _value) external onlyOwnerOrAdmin {
        isMintingActive = _value;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setWhitelistPrice(uint256 _whitelistPrice) external onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    function setOwner(address _owner) external onlyOwner {
        transferOwnership(_owner);
    }

    function setSigner(address _signer) external onlyOwner {
        whitelistSigner = _signer;
    }

    function setWithdrawAddress(address _owner) external onlyOwner {
        t1 = _owner;
    }

    /**
     * @dev mint multiple
     */
    function mint(uint256 _num) external payable {
        require(isMintingActive, "mint: Minting must be active");
        require(_num <= maxPurchaseNum, "mint: Cannot mint this many at a time");
        require(id.current() + _num <= maxSupply, "mint: Minting would exceed max supply");
        require(price * _num <= msg.value, "mint: Ether value sent is not correct");

        for (uint i = 0; i < _num; i++) {
            _mint();
        }
    }

    /**
     * @dev whitelist claim
     */
    function whitelistMint(uint256 _whitelistID, bytes calldata _signature, uint256 _num) external payable {
        require(id.current() + _num <= maxSupply, "whitelistMint: Minting would exceed max supply");
        require(_num <= maxPurchaseNum, "whitelistMint: Cannot mint this many at a time");
        require(whitelistPrice * _num <= msg.value, "whitelistMint: Ether value sent is not correct");

        require(!hasMinted[_whitelistID], "whitelistMint: Whitelist already claimed");

        for (uint i = 0; i < _num; i++) {
            require(_verify(getMessageHash(_msgSender(), _whitelistID), _signature), "whitelistMint: Invalid Signature");
            hasMinted[_whitelistID] = true;
            _mint();
        }
    }

    /**
     * @dev set base URI
     */
    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function _nextId() internal returns (uint256) {
        id.increment();
        return id.current();
    }

    function _mint() internal {
        if (id.current() < maxSupply) {
            uint256 id = _nextId();
            _safeMint(_msgSender(), id);
        }
    }

    function getMessageHash(
        address _account,
        uint256 _whitelistID
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _whitelistID));
    }

    function _verify(bytes32 hash, bytes calldata signature) internal view returns (bool) {
        return whitelistSigner.isValidSignatureNow(hash.toEthSignedMessageHash(), signature);
    }
}