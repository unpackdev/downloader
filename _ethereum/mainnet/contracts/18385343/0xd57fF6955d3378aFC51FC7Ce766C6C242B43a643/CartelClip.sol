// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721.sol";
import "./IERC4906.sol";
import "./IERC20.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./IERC20Receive.sol";
import "./console.sol";

/// @title NFT of Blockchain Cartel
contract CartelClip is
    IERC4906,
    ERC721,
    ERC721URIStorage,
    ERC721Burnable,
    ERC2981,
    Ownable,
    IERC20Receive
{
    using Counters for Counters.Counter;

    IERC20 private cartelCoin;
    string public baseURI;
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint256) public tokenBalances;

    /// @dev Initializes the CartelClip contract.
    constructor() ERC721("Street Cred", "CRED") {
        baseURI = "";
    }

    /// @dev Returns the base URI for token metadata.
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @dev Sets the base URI for token metadata.
    /// @param _uri The new base URI.
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
        emit BatchMetadataUpdate(0, _tokenIdCounter.current());
    }

    /// @dev Sets the CartelCoin contract's address
    /// @param _cartelCoinAddress The new CartelCoin contract address.
    function setCartelCoin(address _cartelCoinAddress) external onlyOwner {
        cartelCoin = IERC20(_cartelCoinAddress);
    }

    /// @dev Mints a new CartelClip token to the caller's address.
    function mint() external {
        require(
            balanceOf(msg.sender) == 0,
            "Only one token per address is allowed"
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _mint(msg.sender, tokenId);

        _setTokenURI(
            tokenId,
            string(abi.encodePacked(Strings.toString(tokenId), ".json"))
        );
        tokenBalances[tokenId] = 0;
    }

    /// @dev Receives ERC20 tokens on behalf of the CartelClip contract.
    /// @param _sender The original sender of the tokens.
    /// @param _tokenId The token ID associated with the transfer.
    /// @param _amount The amount of tokens being transferred.
    function receiveFor(
        address _sender,
        uint256 _tokenId,
        uint256 _amount
    ) external override {
        require(address(cartelCoin) == msg.sender, "Only CartelCoin can call.");
        cartelCoin.transferFrom(_sender, address(this), _amount);
        tokenBalances[_tokenId] += _amount;
        emit ReceivedFor(msg.sender, _sender, _tokenId, _amount);
        emit MetadataUpdate(_tokenId);
    }

    /// @dev Withdraws ERC20 tokens from the CartelClip contract.
    /// @param _token The address of the ERC20 token to withdraw.
    /// @param _amount The amount of tokens to withdraw.
    function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    /// @dev Sets the default royalty receiver and fee for the CartelClip contract.
    /// @param receiver The address of the royalty receiver.
    /// @param feeNumerator The fee numerator for the royalty.
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @dev Deletes the default royalty for the CartelClip contract.
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /// @dev Sets the royalty receiver and fee for a specific token.
    /// @param tokenId The token ID for which to set the royalty.
    /// @param receiver The address of the royalty receiver.
    /// @param feeNumerator The fee numerator for the royalty.
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    // The following functions are overrides required by Solidity.
    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC2981, ERC721, ERC721URIStorage, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
