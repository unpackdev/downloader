// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IFactoryERC721.sol";
import "./Kn0wbot.sol";

contract Kn0wbotFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    uint256 TOKEN_SUPPLY = 11111;
    uint256 NUM_OPTIONS = 1;

    string public baseURI =
        "ipfs://QmUc2C6Ax5up4LnaJgJJxUBhsmrgDKSrR5ABg5emGpiaZp/";

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;
        fireTransferEvents(address(0), owner());
    }

    function name() external pure override returns (string memory) {
        return "Kn0wbots";
    }

    function symbol() external pure override returns (string memory) {
        return "UMS";
    }

    function contractURI() public view returns (string memory) {
        return "ipfs://QmZfrNGe9yiggGymNMCsGtEuUFMyYaQNsFEHvr1wasXmKV/0";
    }

    function supportsFactoryInterface() public pure override returns (bool) {
        return true;
    }

    function numOptions() public view override returns (uint256) {
        return NUM_OPTIONS;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function transferNftOwnership(address newOwner) public onlyOwner {
        Kn0wbot kn0wbot = Kn0wbot(nftAddress);
        kn0wbot.transferOwnership(newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function setNftBaseURI(string memory visibleBaseURI) public onlyOwner {
        Kn0wbot kn0wbot = Kn0wbot(nftAddress);
        kn0wbot.setBaseURI(visibleBaseURI);
    }

    function mint(uint256 _optionId, address _toAddress) public override {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() ||
                owner() == _msgSender()
        );

        require(canMint(_optionId));
        Kn0wbot kn0wbot = Kn0wbot(nftAddress);
        kn0wbot.safeMint(_toAddress);
    }

    function canMint(uint256 _optionId) public view override returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }

        Kn0wbot kn0wbot = Kn0wbot(nftAddress);
        uint256 creatureSupply = kn0wbot.totalSupply();

        return (creatureSupply + 1) <= TOKEN_SUPPLY;
    }

    function tokenURI(uint256 _optionId)
        external
        view
        override
        returns (string memory)
    {
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
