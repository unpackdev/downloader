// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Royalty.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

//    ▄▄▄▄   ▓█████   ██████ ▄▄▄█████▓ ██▓ ▄▄▄       ██▀███ ▓██   ██▓   //
//   ▓█████▄ ▓█   ▀ ▒██    ▒ ▓  ██▒ ▓▒▓██▒▒████▄    ▓██ ▒ ██▒▒██  ██▒   //
//   ▒██▒ ▄██▒███   ░ ▓██▄   ▒ ▓██░ ▒░▒██▒▒██  ▀█▄  ▓██ ░▄█ ▒ ▒██ ██░   //
//   ▒██░█▀  ▒▓█  ▄   ▒   ██▒░ ▓██▓ ░ ░██░░██▄▄▄▄██ ▒██▀▀█▄   ░ ▐██▓░   //
//   ░▓█  ▀█▓░▒████▒▒██████▒▒  ▒██▒ ░ ░██░ ▓█   ▓██▒░██▓ ▒██▒ ░ ██▒▓░   //
//   ░▒▓███▀▒░░ ▒░ ░▒ ▒▓▒ ▒ ░  ▒ ░░   ░▓   ▒▒   ▓▒█░░ ▒▓ ░▒▓░  ██▒▒▒    //
//   ▒░▒   ░  ░ ░  ░░ ░▒  ░ ░    ░     ▒ ░  ▒   ▒▒ ░  ░▒ ░ ▒░▓██ ░▒░    //
//    ░    ░    ░   ░  ░  ░    ░       ▒ ░  ░   ▒     ░░   ░ ▒ ▒ ░░     //
//    ░         ░  ░      ░            ░        ░  ░   ░     ░ ░        //
//         ░                                                 ░ ░        //

contract Bestiary is
    ERC721,
    ERC721Enumerable,
    ERC721Royalty,
    Pausable,
    Ownable
{
    string private _collectionName;
    string private _collectionSymbol;
    string private _ipfsBaseUri;

    uint256 private _maxTokensPerTx;

    uint256 public mintPrice;
    uint256 public maxSupply;
    uint96 private _feeNumerator;

    mapping(uint256 => bool) private _mintedTokensMap;
    uint256[] private _mintedTokensList;

    // Events
    event Mint(uint256 tokenId, address recipient);
    event Withdraw(uint amount, uint when);
    event Transfer(address from, address to);

    constructor(
        string memory collectionName,
        string memory collectionSymbol,
        string memory ipfsBaseUri,
        uint256 maxTokensPerTx,
        uint256 initMintPrice,
        uint256 initMaxSupply,
        uint96 feeNumerator
    ) ERC721(collectionName, collectionSymbol) {
        _collectionName = collectionName;
        _collectionSymbol = collectionSymbol;
        _ipfsBaseUri = ipfsBaseUri;
        _maxTokensPerTx = maxTokensPerTx;
        mintPrice = initMintPrice;
        maxSupply = initMaxSupply;
        _feeNumerator = feeNumerator;
        _setDefaultRoyalty(owner(), _feeNumerator);
    }

    // <== == == == == == == OWNER == == == == == == ==>

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Balance is zero");
        emit Withdraw(address(this).balance, block.timestamp);

        payable(owner()).transfer(address(this).balance);
    }

    // Pausable
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Reserving

    function reserveTokens(address to, uint256[] calldata ids)
        public
        onlyOwner
    {
        for (uint i = 0; i < ids.length; i++) {
            _mintToken(to, ids[i]);
        }
    }

    // <== == == == == == == PUBLIC == == == == == == ==>
    function _baseURI() internal view override returns (string memory) {
        return _ipfsBaseUri;
    }

    // Minting

    function mintTokens(address to, uint256[] calldata ids) public payable {
        require(
            ids.length < _maxTokensPerTx,
            "Cant mint this many tokens at once."
        );

        require(msg.value >= mintPrice * ids.length, "Not enough ether sent.");

        for (uint i = 0; i < ids.length; i++) {
            _mintToken(to, ids[i]);
        }
    }

    function mintedTokensList() public view returns (uint256[] memory) {
        return _mintedTokensList;
    }

    // <== == == == == == == PRIVATE == == == == == == ==>
    function _mintToken(address to, uint256 id) private {
        // check totalSupply is less than maxSupply
        require(totalSupply() < maxSupply, "No more tokens to mint");
        // check if id wasn't minted before
        require(_mintedTokensMap[id] != true, "This NFT is not available.");

        _mintedTokensMap[id] = true;
        _mintedTokensList.push(id);

        _safeMint(to, id);
        emit Mint(id, to);
    }

    // Transfers

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _transfer(from, to, tokenId);
        emit Transfer(from, to);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
        emit Transfer(from, to);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override whenNotPaused {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _safeTransfer(from, to, tokenId, data);
        emit Transfer(from, to);
    }

    // <== == == == == == == Other Functions == == == == == == ==>

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
