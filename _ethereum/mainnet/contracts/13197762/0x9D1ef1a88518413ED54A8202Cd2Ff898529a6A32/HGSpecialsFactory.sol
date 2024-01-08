// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./HashGarageSpecials.sol";

contract HashGarageSpecialsFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    string public baseURI = "https://hashgarage.com/api/metadata/factory/specials/";

    /** Single mint or multiple */
    uint256 NUM_OPTIONS = 5;

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;

        fireTransferEvents(address(0), owner());
    }

    function name() external override pure returns (string memory) {
        return "HashGarage Specials Minter";
    }

    function symbol() external override pure returns (string memory) {
        return "HGSM";
    }

    function supportsFactoryInterface() public override pure returns (bool) {
        return true;
    }

    function numOptions() public override view returns (uint256) {
        return NUM_OPTIONS;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function mint(uint256 _optionId, address _toAddress) public override {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == msg.sender ||
                owner() == msg.sender
        );
        require(canMint(_optionId));
        HashGarageSpecials hg = HashGarageSpecials(nftAddress);
        for (uint256 i = 0; i <= _optionId; i++) {
            hg.mintTo(_toAddress);
        }
    }

    function canMint(uint256 _optionId) public override view returns (bool) {
        return _optionId < NUM_OPTIONS;    
    }

    function tokenURI(uint256 _optionId) external override view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
    }

    function multimint(uint8 amount, address _to) public onlyOwner {
        HashGarageSpecials hg = HashGarageSpecials(nftAddress);
        for (uint8 i = 0; i < amount; i++) {
            require(canMint(0));
            hg.mintTo(_to);
        }
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() != _owner) {
            return false;
        }
        if (_owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }

    function transferOwnershipOfChild(address newOwner) public onlyOwner {
        HashGarageSpecials hg = HashGarageSpecials(nftAddress);
        hg.transferOwnership(newOwner);
    }
}
