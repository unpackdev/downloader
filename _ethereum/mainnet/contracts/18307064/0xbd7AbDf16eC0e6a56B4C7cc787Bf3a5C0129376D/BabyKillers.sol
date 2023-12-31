// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Royalty.sol";
import "./ERC721Burnable.sol";
import "./ERC721URIStorage.sol";
import "./PaymentSplitter.sol";

// https://twitter.com/8abyKill3r

contract BabyKillers is ERC721, ERC721Enumerable, ERC721Royalty, Ownable {
    // To increment the id of the NFTs
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // To concatenate the URL of an NFT
    using Strings for uint256;

    // Number of NFTs in the collection
    uint256 public immutable maxSupply;

    // URI of the NFTs when revealed
    string public baseURI;

    //URI of the NFTs when not revealed
    string public notRevealedURI;

    // The extension of the file containing the metadata
    string public baseExtension = ".json";

    // Winners addresses
    address public shareWinner;
    address public nftWinner;

    enum Status {
        Before,
        Reveal
    }

    Status public status;
    event Revealed();

    // Event to notify when winners are picked
    event ShareWinnerPicked(uint256 tokenId, address shareWinner);
    event NftWinnerPicked(uint256 tokenId, address winner);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory theBaseURI_,
        uint maxSupply_,
        string memory notRevealedURI_
    ) ERC721(name_, symbol_) {
        _tokenIdCounter.increment();
        baseURI = theBaseURI_;
        maxSupply = maxSupply_;
        notRevealedURI = notRevealedURI_;
        _setDefaultRoyalty(msg.sender, 600);
        _initialMint();
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI_) external onlyOwner {
        baseURI = newBaseURI_;
    }

    function getNotRevealedURI() public view returns (string memory) {
        return notRevealedURI;
    }

    function setNotRevealedURI(
        string memory notRevealedURI_
    ) external onlyOwner {
        notRevealedURI = notRevealedURI_;
    }

    function getBaseExtension() public view returns (string memory) {
        return baseExtension;
    }

    function setBaseExtension(
        string memory newBaseExtension_
    ) external onlyOwner {
        baseExtension = newBaseExtension_;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "tokenURI: nonexistent token");
        if (getStatus() == Status.Before) {
            return notRevealedURI;
        }
        string memory currentBaseURI = getBaseURI();
        return bytes(currentBaseURI).length > 0
            ? string(
                abi.encodePacked(
                    currentBaseURI,
                    tokenId.toString(),
                    baseExtension
                )
            )
            : "";
    }

    function _getCurrentId() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    function getStatus() public view returns (Status) {
        return status;
    }

    function reveal() external onlyOwner {
        require(status == Status.Before, "Already revealed.");
        status = Status.Reveal;
        emit Revealed();
    }

    function _initialMint() private {
        uint256 tokenId;
        //Minting all the account NFTs
        for (uint i = 1; i <= maxSupply; i++) {
            tokenId = _getCurrentId();
            _tokenIdCounter.increment();
            _safeMint(_msgSender(), tokenId);
        }
    }

    function getShareWinner() public view returns (address) {
        require(shareWinner != address(0), "Share winner not picked yet.");
        return shareWinner;
    }

    function getNftWinner() public view returns (address) {
        require(nftWinner != address(0), "NFT winner not picked yet.");
        return nftWinner;
    }

    function pickWinners(uint random_) external onlyOwner {
        require(
            shareWinner == address(0) && nftWinner == address(0),
            "Winners already picked."
        );
        // Pick a random tokenId from the minted ones and set the winner
        uint winnerTokenId = _pickRandomTokenId(random_);
        shareWinner = ownerOf(winnerTokenId);
        emit ShareWinnerPicked(winnerTokenId, shareWinner);

        // Pick a random tokenId from the minted ones and set the winner
        // It can't be the same winner as the share winner
        uint nftWinnerTokenId = _pickRandomTokenId(winnerTokenId);
        uint randNonce = winnerTokenId;
        while (nftWinnerTokenId == winnerTokenId) {
            randNonce += 1;
            nftWinnerTokenId = _pickRandomTokenId(randNonce);
        }
        nftWinner = ownerOf(nftWinnerTokenId);
        emit NftWinnerPicked(nftWinnerTokenId, nftWinner);
    }

    function _pickRandomTokenId(uint random_) private view returns (uint256) {
        uint256 randomnumber = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, random_, block.prevrandao)
            )
        ) % totalSupply();
        return randomnumber + 1;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // functions used to handle eth sent to the contract

    receive() external payable {}

    fallback() external payable {}

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
