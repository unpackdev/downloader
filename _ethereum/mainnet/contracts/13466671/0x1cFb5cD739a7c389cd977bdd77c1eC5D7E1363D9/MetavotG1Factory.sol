// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./MetavotG1.sol";

/**
 * @title MetavotG1Factory
 * https://metavots.com/
 */
contract MetavotG1Factory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public metavotAddress;
    string public baseURI = "https://vod.metavots.com/gen1/meta/";
    bool private initialized = false;

    uint256 public constant NUM_OPTIONS = 1;  // factory only mints bots

    constructor(address _proxyRegistryAddress, address _metavotAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        metavotAddress = _metavotAddress;   
    }

    function initialize() public onlyOwner {
        require(!initialized,  "Already initialized.");
        fireTransferEvents(address(0), owner()); // mint the factories
        initialized = true;
    }

    // factory owner can pull factory balance
    function sendBalance() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // factory owner can pull balance of bot contract
    function sendBotBalance() public payable onlyOwner {
        MetavotG1 metavot = MetavotG1(metavotAddress);
        metavot.sendBalanceTo(owner());
    }

    // Use metavot.transferOwnership to return it to the factory.
    function lendBotContract() public onlyOwner {
        MetavotG1 metavot = MetavotG1(metavotAddress);
        metavot.transferOwnership(owner());
    }

    function pause() public onlyOwner {
        MetavotG1 metavot = MetavotG1(metavotAddress);
        metavot.pause();
    }

    function unpause() public onlyOwner {
        MetavotG1 metavot = MetavotG1(metavotAddress);
        metavot.unpause();
    }

    function name() override external pure returns (string memory) {
        return "Metavot G1 Factory";
    }

    function symbol() override external pure returns (string memory) {
        return "MTVF1";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function numOptions() override public view returns (uint256) {
        return NUM_OPTIONS;
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 1; i <= NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    // Mint on behalf of bot contract
    function mint(uint256 _optionId, address _toAddress) override public {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            owner() == _msgSender() || address(proxyRegistry.proxies(owner())) == _msgSender()      
        );
        require(canMint(_optionId), "Can't mint, out of supply or invalid factory token.");
        MetavotG1 metavot = MetavotG1(metavotAddress);
        metavot.mintRandomBot(_toAddress);
    }

    // Factory can mint if optionId is not invalid and the metavot contract has supply.
    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId > NUM_OPTIONS) {
            return false;
        }
        MetavotG1 metavot = MetavotG1(metavotAddress);
        return metavot.canMint();
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
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
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
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
}
