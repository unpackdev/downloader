// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IMapifest.sol";
import "./pin.sol";
import "./IMapifestMarketplace.sol";
import "./IMapifestConfigurator.sol";

contract MapifestRouter is WithPin {
    address private _owner;
    IMapifest private _nft;
    IMapifestMarketplace private _marketplace;
    IMapifestConfigurator private _config;

    constructor() {
        _owner = msg.sender;
    }

    function setMarketplace(address _marketplaceAddress) external onlyOwner {
        _marketplace = IMapifestMarketplace(_marketplaceAddress);
    }

    function setNFT(address _nftAddress) external onlyOwner {
        _nft = IMapifest(_nftAddress);
    }

    function setConfigurator(address _address) external onlyOwner {
        _config = IMapifestConfigurator(_address);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _nft.ownerOf(tokenId);
    }

    function getPinInfo(uint256 _pinId)
        external
        view
        returns (
            uint32,
            uint32,
            uint8,
            uint256,
            address
        )
    {
        return _nft.getPinInfo(_pinId);
    }

    function makePin(
        uint256 _lat,
        uint256 _lng,
        uint256 _decimal,
        string calldata _message,
        uint256 _valueAmount
    ) external fromMarketplace returns (uint256) {
        return _nft.makePin(_lat, _lng, _decimal, _message, _valueAmount);
    }

    function makeId(
        uint256 _lat,
        uint256 _lng,
        uint256 _decimal
    ) external view fromMarketplace returns (uint256) {
        return _nft.makeId(_lat, _lng, _decimal);
    }

    function acquire(uint256 _fromPinId, uint256 _toPinId) external {
        _nft.acquire(_fromPinId, _toPinId);
    }

    function setImage(uint256 _pinId, string memory _image)
        external
        fromMarketplace
    {
        _nft.setImage(_pinId, _image);
    }

    function setVideo(uint256 _pinId, string memory _video)
        external
        fromMarketplace
    {
        _nft.setVideo(_pinId, _video);
    }

    function setMessage(uint256 _pinId, string memory _message)
        external
        fromMarketplace
    {
        _nft.setMessage(_pinId, _message);
    }

    function setValueAmount(uint256 _pinId, uint256 _valueAmount)
        external
        fromMarketplace
    {
        _nft.setValueAmount(_pinId, _valueAmount);
    }

    function getMessagePrice() external view returns (uint256) {
        return _config.getMessagePrice();
    }

    function getImagePrice() external view returns (uint256) {
        return _config.getImagePrice();
    }

    function getVideoPrice() external view returns (uint256) {
        return _config.getVideoPrice();
    }

    function getProfilePrice() external view returns (uint256) {
        return _config.getProfilePrice();
    }

    function valueAmountSplitByPercentage() external view returns (uint8) {
        return _config.valueAmountSplitByPercentage();
    }

    function pinPriceSplitByPercentage() external view returns (uint8) {
        return _config.pinPriceSplitByPercentage();
    }

    function getPinBasePrice(uint256 _decimal) external view returns (uint256) {
        return _config.getPinBasePrice(_decimal);
    }

    modifier fromMarketplace() {
        require(msg.sender == address(_marketplace));
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
}
