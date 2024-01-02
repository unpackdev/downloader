// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./WmbApp.sol";

interface IChainID {
    function chainId() external view returns (uint256);
}

contract MultichainNFT is WmbApp, ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    mapping(uint => address) public dstChainNftSC;

    constructor(address admin, address _wmbGateway) WmbApp() ERC721("MultichainNFT", "MCT") {
        initialize(admin, _wmbGateway);
    }

    // Transfer in enough native coin for fee.
    receive() external payable {}

    function configDstSc(
        uint dstChainId,
        address dstSc
    ) external onlyOwner {
        dstChainNftSC[dstChainId] = dstSc;
    }

    /**
     * Mint NFT to dstChainId
     * @param dstChainId destination chain id
     * @param to destination address
     * @param tokenId token id
     * @param uri token uri
     */
    function safeMint(uint dstChainId, address to, uint256 tokenId, string memory uri)
        public
        onlyOwner
    {
        _safeMint(dstChainId, to, tokenId, uri);
    }

    // nft cross chain 
    function crossChain(
        uint dstChainId,
        address to,
        uint256 tokenId,
        string memory uri
    ) public onlyOwner {
        // not support current chain 
        require(dstChainId != IChainID(wmbGateway).chainId(), "MultichainNFT: dstChainId was wrong");
        // check nft owner 
        require(ownerOf(tokenId) == msg.sender, "MultichainNFT: not owner");
        // burn nft
        _burn(tokenId);
        _safeMint(dstChainId, to, tokenId, uri);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _safeMint(uint dstChainId, address to, uint256 tokenId, string memory uri)
        internal
    {
        if (dstChainId == IChainID(wmbGateway).chainId()) {
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uri);
        } else {
            require(dstChainNftSC[dstChainId] != address(0), "MultichainNFT: dstChainNftSC not exists");

            uint fee = estimateFee(dstChainId, 1_000_000);
            _dispatchMessage(
                dstChainId,
                dstChainNftSC[dstChainId],
                abi.encode(
                    to,
                    tokenId,
                    uri
                ),
                fee
            );
        }
    }

    // _wmbReceive is called when a message is received from another chain.
    function _wmbReceive(
        bytes calldata data,
        bytes32 /*messageId*/,
        uint256 /*fromChainId*/,
        address /*from*/
    ) internal override {
        (address to, uint256 tokenId, string memory uri) = abi.decode(
            data,
            (address, uint256, string)
        );
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }


}
