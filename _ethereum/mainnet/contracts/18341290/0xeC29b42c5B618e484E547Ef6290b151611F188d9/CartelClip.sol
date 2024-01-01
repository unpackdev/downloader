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

    string public baseURI;
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint256) public tokenBalances;

    constructor() ERC721("Street Cred", "CRED") {
        baseURI = "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
        emit BatchMetadataUpdate(0, _tokenIdCounter.current());
    }

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

    function receiveFor(
        address _from,
        address _sender,
        uint256 _tokenId,
        uint256 _amount
    ) external override {
        IERC20(_from).transferFrom(_sender, address(this), _amount);
        tokenBalances[_tokenId] += _amount;
        emit ReceivedFor(_from, _sender, _tokenId, _amount);
        emit MetadataUpdate(_tokenId);
    }

    function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

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
