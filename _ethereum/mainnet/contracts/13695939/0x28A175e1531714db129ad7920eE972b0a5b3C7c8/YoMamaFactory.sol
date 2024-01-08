// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./YoMama.sol";

contract YoMamaFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;

    uint256 TOTAL_SUPPLY = 960;

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;

        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "Yo mama NFT sale";
    }

    function symbol() override external pure returns (string memory) {
        return unicode'喲媽媽特賣';
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmShg3eTgA9YcHUpY8VCbQTiQ5saXvYiDenW6UW2Ug9az5";
    }

    function numOptions() override public view returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 1; i <= TOTAL_SUPPLY; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function mint(uint256 _tokenId, address _toAddress) override public {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(address(proxyRegistry.proxies(owner())) == _msgSender() || owner() == _msgSender());
        require(canMint(_tokenId));

        YoMama yoMamaNFT = YoMama(nftAddress);
        yoMamaNFT.mint(_toAddress, _tokenId);
    }

    function canMint(uint256 _tokenId) override public view returns (bool) {
        if (_tokenId < 1 || _tokenId > TOTAL_SUPPLY) {
            return false;
        }

        YoMama yoMamaNFT = YoMama(nftAddress);
        return !yoMamaNFT.exists(_tokenId);
    }

    function tokenURI(uint256 _tokenId) override external view returns (string memory) {
        YoMama yoMamaNFT = YoMama(nftAddress);
        return yoMamaNFT.tokenURI(_tokenId);
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