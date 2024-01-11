//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Ownable.sol";
import "./IMinter.sol";
import "./INFT.sol";

contract Minter is IMinter, Ownable {
    uint16 public immutable devReserve;
    uint16 public devMinted;
    uint16 public whitelistMinted;
    uint16 public genesisMinted;
    uint256 public publicMintPrice;
    address private _signer;
    address private _panda;
    bool public whitelistMintActive = false;
    bool public publicMintActive = false;
    bool public genesisMintActive = false;

    using ECDSA for bytes32;

    struct MintConf {
        uint16 maxMint;
        uint16 maxPerAddrMint;
        uint256 price;
    }
    MintConf public whitelistMintConf;
    MintConf public genesisMintConf;

    mapping(address => uint16) private _whitelistAddrMinted;
    mapping(address => uint16) private _genesisAddrMinted;

    constructor(address nft_, uint16 devReserve_) {
        _panda = nft_;
        _signer = msg.sender;
        require(
            (devReserve_ * 5 <= _getOverall()),
            "No more than 20% of overall supply"
        );
        devReserve = devReserve_;

        // TODO: need be change for mainnet.
        publicMintPrice = 0.075 ether;
        whitelistMintConf = MintConf(6000, 5, 0.05 ether);
        genesisMintConf = MintConf(500, 1, 0 ether);
    }

    function togglePublicMintStatus() external override onlyOwner {
        publicMintActive = !publicMintActive;
    }

    function toggleWhitelistMintStatus() external override onlyOwner {
        whitelistMintActive = !whitelistMintActive;
    }

    function toggleGenesisMintStatus() external override onlyOwner {
        genesisMintActive = !genesisMintActive;
    }

    /**
     * dev
     */
    function devMint(uint16 quantity, address to) external override onlyOwner {
        _devMint(quantity, to);
    }

    function devMintToMultiAddr(uint16 quantity, address[] calldata addresses)
        external
        override
        onlyOwner
    {
        require(addresses.length > 0, "Invalid addresses");

        for (uint256 i = 0; i < addresses.length; i++) {
            _devMint(quantity, addresses[i]);
        }
    }

    function devMintVaryToMultiAddr(
        uint16[] calldata quantities,
        address[] calldata addresses
    ) external override onlyOwner {
        require(addresses.length > 0, "Invalid addresses");

        require(
            quantities.length == addresses.length,
            "addresses does not match quantities length"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _devMint(quantities[i], addresses[i]);
        }
    }

    /**
     * whitelist
     */
    function setWhitelistMintConf(
        uint16 maxMint,
        uint16 maxPerAddrMint,
        uint256 price
    ) external override onlyOwner {
        require((maxMint <= _getMaxSupply()), "Max supply exceeded");

        whitelistMintConf = MintConf(maxMint, maxPerAddrMint, price);
        emit WhitelistMintConfChanged(maxMint, maxPerAddrMint, price);
    }

    function isWhitelist(string calldata salt, bytes calldata token)
        external
        view
        override
        returns (bool)
    {
        return _isWhitelist(salt, token);
    }

    function whitelistMint(
        uint16 quantity,
        string calldata salt,
        bytes calldata token
    ) external payable override {
        require(whitelistMintActive, "Whitelist mint is not active");

        require(_isWhitelist(salt, token), "Not allowed");

        require(
            whitelistMinted + quantity <= whitelistMintConf.maxMint,
            "Max mint amount exceeded"
        );

        require(
            _whitelistAddrMinted[msg.sender] + quantity <=
                whitelistMintConf.maxPerAddrMint,
            "Max mint amount per account exceeded"
        );

        whitelistMinted += quantity;
        _whitelistAddrMinted[msg.sender] += quantity;
        _batchMint(msg.sender, quantity);
        _refundIfOver(uint256(whitelistMintConf.price) * quantity);
    }

    /**
     * genesisMint
     */
    function setGenesisMintConf(
        uint16 maxMint,
        uint16 maxPerAddrMint,
        uint256 price
    ) external override onlyOwner {
        require((maxMint <= _getMaxSupply()), "Max supply exceeded");

        genesisMintConf = MintConf(maxMint, maxPerAddrMint, price);
        emit GenesisMintConfChanged(maxMint, maxPerAddrMint, price);
    }

    function isGenesis(string calldata salt, bytes calldata token)
        external
        view
        override
        returns (bool)
    {
        return _isGenesis(salt, token);
    }

    function genesisMint(
        uint16 quantity,
        string calldata salt,
        bytes calldata token
    ) external payable override {
        require(genesisMintActive, "Genesis mint is not active");

        require(_isGenesis(salt, token), "Not allowed");

        require(
            genesisMinted + quantity <= genesisMintConf.maxMint,
            "Max mint amount exceeded"
        );

        require(
            _genesisAddrMinted[msg.sender] + quantity <=
                genesisMintConf.maxPerAddrMint,
            "Max mint amount per account exceeded"
        );

        genesisMinted += quantity;
        _genesisAddrMinted[msg.sender] += quantity;
        _batchMint(msg.sender, quantity);
        _refundIfOver(uint256(genesisMintConf.price) * quantity);
    }

    // /**
    //  * publicMint
    //  */
    function setPublicMintPrice(uint256 price) external override onlyOwner {
        publicMintPrice = price;
        emit PublicMintPriceChanged(price);
    }

    function publicMint(uint16 quantity, address to) external payable override {
        require(publicMintActive, "Public mint is not active");
        _batchMint(to, quantity);
        _refundIfOver(uint256(publicMintPrice) * quantity);
    }

    function whitelistAddrMinted(address sender)
        external
        view
        override
        returns (uint16)
    {
        return uint16(_whitelistAddrMinted[sender]);
    }

    function genesisAddrMinted(address sender)
        external
        view
        override
        returns (uint16)
    {
        return uint16(_genesisAddrMinted[sender]);
    }

    function getSigner() external view override returns (address) {
        return _signer;
    }

    function setSigner(address signer_) external override onlyOwner {
        _signer = signer_;
        emit SignerChanged(signer_);
    }

    function withdraw() external override onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function _devMint(uint16 quantity, address to) private {
        require(devMinted + quantity <= devReserve, "Max reserve exceeded");

        devMinted += quantity;
        _batchMint(to, quantity);
    }

    function _batchMint(address to, uint16 quantity) internal {
        require(quantity > 0, "Invalid quantity");
        require(to != address(0), "Mint to the zero address");

        INFT(_panda).mint(to, quantity);
    }

    function _isWhitelist(string memory salt, bytes memory token)
        internal
        view
        returns (bool)
    {
        return _verify(salt, msg.sender, token, "");
    }

    function _isGenesis(string memory salt, bytes memory token)
        internal
        view
        returns (bool)
    {
        return _verify(salt, msg.sender, token, "GENESIS");
    }

    function _verify(
        string memory salt,
        address sender,
        bytes memory token,
        string memory category
    ) internal view returns (bool) {
        return (_recover(_hash(salt, _panda, sender, category), token) ==
            _signer);
    }

    function _recover(bytes32 hash, bytes memory token)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function _hash(
        string memory salt,
        address contract_,
        address sender,
        string memory category
    ) internal pure returns (bytes32) {
        if (bytes(category).length == 0)
            return keccak256(abi.encode(salt, contract_, sender));
        return keccak256(abi.encode(salt, contract_, sender, category));
    }

    function _refundIfOver(uint256 spend) private {
        require(msg.value >= spend, "Need to send more ETH");

        if (msg.value > spend) {
            payable(msg.sender).transfer(msg.value - spend);
        }
    }

    function _getMaxSupply() internal returns (uint256) {
        return INFT(_panda).getMaxSupply();
    }

    function _getOverall() internal returns (uint256) {
        return INFT(_panda).getOverall();
    }
}
