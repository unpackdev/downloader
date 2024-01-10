//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";

contract ETC is ERC721Enumerable, ERC721URIStorage, Ownable, Pausable {
    using Strings for uint256;

    string private _baseURIextended;
    string private _unrevealBaseURI;
    string public baseExtension = ".json";
    bool public revealed = false;
    address payable receiverWallet;
    uint256 pricePerNFT = 0.06 ether;
    uint256 lastTokenId;
    uint256 maxAmountOfMint = 10000;

    event BatchMintFinished(address _to, uint256 _amount);
    event PresaleNFTsFinished(address _to, uint256 _amount);

    /**
     * @dev Sets the values for {name} and {symbol}.
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address payable _receiverWallet)
        ERC721("Escobars Treasure Collection", "ETC")
    {
        require(address(_receiverWallet) != address(0), "zero wallet address");
        receiverWallet = _receiverWallet;
    }

    /**
     * @dev Public function(only Owner) to set the modifier to pause
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Public function(only Owner) to set the modifier to unpause
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice A method to set baseURI with new one.
     * @param baseURI_ new baseURI.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    /**
     * @notice An overrride function to get the baseURI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @notice tokenURI overrride function.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        string memory __baseURI;
        __baseURI = _baseURI();
        // Concatenate the unrevealBaseURI and tokenId (via abi.encodePacked).
        return
            bytes(__baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        __baseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /**
     * @notice _burn internal overrride function.
     */
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    /**
     * @notice _beforeTokenTransfer internal overrride function.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice supportsInterface overrride function.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice A method to allow for only owner to batchmint NFTs to anyone.
     * @param _to the address of receiver to get batchminted.
     * @param _amount the amount of tokens.
     */
    function BatchMint(address _to, uint256 _amount) public onlyOwner {
        require(
            lastTokenId + _amount <= maxAmountOfMint,
            "Reached to the max amount of mint"
        );
        require(_amount > 0, "Should be the positive value");
        for (uint256 _i = 0; _i < _amount; _i++) {
            uint256 _tokenId = nextTokenId();
            _safeMint(_to, _tokenId, "");
            incrementTokenId();
        }
        emit BatchMintFinished(_to, _amount);
    }

    /**
     * @notice A method to allow for the buyer to get minted for presale.
     * @param _to the address of receiver to get presold.
     * @param _amount the amount of tokens.
     */
    function PresaleNFTs(address _to, uint256 _amount)
        external
        payable
        whenNotPaused
    {
        require(_amount > 0, "Should be the positive value");
        require(
            lastTokenId + _amount <= maxAmountOfMint,
            "Reached to the max amount of mint"
        );
        require(_amount <= 10, "Can't buy over 10 NFTs");
        require(_to != address(0), "Zero address");

        uint256 priceNFTs = pricePerNFT * _amount;
        require(msg.value >= priceNFTs, "Insufficient ETH received");

        receiverWallet.transfer(msg.value);
        for (uint256 _i = 0; _i < _amount; _i++) {
            uint256 _tokenId = nextTokenId();
            _safeMint(_to, _tokenId, "");
            incrementTokenId();
        }

        emit PresaleNFTsFinished(_to, _amount);
    }

    /**
     * @return The list of all tokens enumerated.
     */
    function getAllTokensList() public view returns (uint256[] memory) {
        uint256[] memory _tokensList = new uint256[](
            ERC721Enumerable.totalSupply()
        );
        uint256 i;

        for (i = 0; i < ERC721Enumerable.totalSupply(); i++) {
            _tokensList[i] = ERC721Enumerable.tokenByIndex(i);
        }
        return (_tokensList);
    }

    /**
     * @notice A method to get the list of all tokens owned by any user.
     * @param _owner the owner address.
     * @return The list of tokens owned by any user.
     */
    function getTokensListOwnedByUser(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _tokensOfOwner = new uint256[](
            ERC721.balanceOf(_owner)
        );
        uint256 i;

        for (i = 0; i < ERC721.balanceOf(_owner); i++) {
            _tokensOfOwner[i] = ERC721Enumerable.tokenOfOwnerByIndex(_owner, i);
        }
        return (_tokensOfOwner);
    }

    function setReceiverWallet(address payable _receiverWallet) public onlyOwner {
        receiverWallet = _receiverWallet;
    }

    function getReceiverWallet() public view returns (address) {
        return receiverWallet;
    }
    function setPricePerNFT(uint256 _newPrice) public onlyOwner {
        pricePerNFT = _newPrice;
    }

    function getPricePerNFT() public view returns (uint256) {
        return pricePerNFT;
    }

    function nextTokenId() public view returns (uint256) {
        return lastTokenId + 1;
    }

    function incrementTokenId() internal {
        lastTokenId++;
    }

    /**
     * @notice get the Last token id.
     */
    function getLastTokenId() public view returns (uint256) {
        return lastTokenId;
    }
}
