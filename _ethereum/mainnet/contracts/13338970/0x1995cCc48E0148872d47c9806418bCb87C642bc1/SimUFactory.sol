// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./Context.sol";

import "./IFactoryERC721.sol";
import "./SimU.sol";

contract SimUFactory is FactoryERC721, Context, Ownable {
    address public proxyRegistryAddress;
    address public nftAddress;
    string public baseURI = "https://www.simulateduniversenft.com/api/salefactory/";
    string private _name;
    string private _symbol;

    uint256 NUM_OPTIONS = 2;
    uint256 SINGLE_SYSTEM_OPTION = 0;
    uint256 MULTIPLE_SYSTEM_OPTION = 1;
    uint256 NUM_MULTIPLE_SYSTEM_OPTION = 4;

    constructor(address proxyRegistryAddress_, address nftAddress_, string memory name, string memory symbol) {
        proxyRegistryAddress = proxyRegistryAddress_;
        nftAddress = nftAddress_;
        _name = name;
        _symbol = symbol;

        fireTransferEvents(address(0), _msgSender());
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

    function updateBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function supportsFactoryInterface() public pure override returns (bool) {
        return true;
    }

    function numOptions() public view override returns (uint256) {
        return NUM_OPTIONS;
    }

    function mint(uint256 _optionId, address _toAddress) public override {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() ||
                owner() == _msgSender()
        );
        require(canMint(_optionId), "Cannot mint");
        SimU nft = SimU(nftAddress);
        if (_optionId == SINGLE_SYSTEM_OPTION) {
            nft.mint(_toAddress);
        } else if (_optionId == MULTIPLE_SYSTEM_OPTION) {
            for (uint256 i = 0; i < NUM_MULTIPLE_SYSTEM_OPTION; i++) {
                nft.mint(_toAddress);
            }
        }
    }

    function canMint(uint256 _optionId) public view override returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }

        SimU nft = SimU(nftAddress);
        uint256 nftSupply = nft.totalSupply();

        uint256 numItemsAllocated = 0;
        if (_optionId == SINGLE_SYSTEM_OPTION) {
            numItemsAllocated = 1;
        } else if (_optionId == MULTIPLE_SYSTEM_OPTION) {
            numItemsAllocated = NUM_MULTIPLE_SYSTEM_OPTION;
        }

        return nftSupply < ((10000 - nft.mintReserve()) - numItemsAllocated);
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

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
}
