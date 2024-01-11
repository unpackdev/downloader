// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";

contract LennyBirds is ERC721A, Ownable {
    using Strings for uint256;

    string public hiddenUri;
    string public metadataUri;
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintPerTx;
    uint256 public defaultFreeMints;

    bool public paused = true;
    bool public revealed = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _hiddenUri,
        string memory _metadataUri,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintPerTx,
        uint256 _defaultFreeMints
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        setMaxSupply(_maxSupply);
        setMaxMintPerTx(_maxMintPerTx);
        setDefaultFreeMints(_defaultFreeMints);
        setHiddenUri(_hiddenUri);
        setMetadataUri(_metadataUri);
    }

    function mint() public payable {
        require(tx.origin == _msgSender(), "The caller is another contract");
        require(!paused, "Contract is paused!");
        uint256 count = calculateMint();
        require(
            count <= maxMintPerTx,
            "Tnx limit of 10 reached! Please try again with less ETH."
        );
        require(
            count > 0,
            "You are out of free mints! To mint additional tokens, please include the corrisponding ETH in your transaction."
        );
        require(
            totalSupply() + count <= maxSupply,
            "Max supply exceeded! Please try again with less ETH."
        );
        _safeMint(_msgSender(), count);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        if (!revealed) {
            return hiddenUri;
        } else {
            string memory baseURI = _baseURI();
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(baseURI, _tokenId.toString(), ".json")
                    )
                    : "";
        }
    }

    function checkFreeMints(address _wallet) public view returns (uint256) {
        uint256 freeMints = defaultFreeMints;
        uint256 minted = balanceOf(_wallet);
        uint256 remainingFreeMints = freeMints > minted
            ? freeMints - minted
            : 0;
        return remainingFreeMints;
    }

    /**
     * INTERNAL
     */
    function calculateMint() internal view returns (uint256) {
        uint256 divCost = cost;
        uint256 userInput = msg.value;
        require(
            userInput % divCost == 0,
            "Incorrect ETH value! Double check your math and try again."
        );
        uint256 paidMints = userInput / divCost;
        uint256 freeMints = defaultFreeMints;
        uint256 minted = balanceOf(_msgSender());
        uint256 remainingFreeMints = freeMints > minted
            ? freeMints - minted
            : 0;
        uint256 count = remainingFreeMints + paidMints;
        return count;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataUri;
    }

    /**
     * ONLY OWNER
     */
    function airdrop(uint256 count, address _receiver) public onlyOwner {
        require(totalSupply() + count <= maxSupply, "Max supply exceeded!");
        _safeMint(_receiver, count);
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setDefaultFreeMints(uint256 _defaultFreeMints) public onlyOwner {
        defaultFreeMints = _defaultFreeMints;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintPerTx(uint256 _maxMintPerTx) public onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    function setHiddenUri(string memory _hiddenUri) public onlyOwner {
        hiddenUri = _hiddenUri;
    }

    function setMetadataUri(string memory _metadataUri) public onlyOwner {
        metadataUri = _metadataUri;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
