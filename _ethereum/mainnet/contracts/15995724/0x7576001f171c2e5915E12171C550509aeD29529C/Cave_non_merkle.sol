// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ECDSA.sol";

contract CaveV2 is ERC721A, Ownable {
    using ECDSA for bytes32;
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;

    uint256 public constant maxCaveSupply = 101;
    uint256 public constant allowance = 2;

    address private _signerAddress;

    mapping(address => uint256) public Minted;

    bool public revealed = false;
    bool public salelive = false;
    bool public nftLocked = true;

    constructor(
        string memory _BaseURI,
        string memory _NotRevealedUri,
        address signerAddress_
    ) ERC721A("Cave2", "CAVE") {
        setBaseURI(_BaseURI);
        setNotRevealedURI(_NotRevealedUri);
        _signerAddress = signerAddress_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setLockState(bool _nftLocked) public onlyOwner {
        nftLocked = _nftLocked;
    }

    function setBaseExtension(string calldata _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        if (revealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function setSaleState(bool _state) public onlyOwner {
        salelive = _state;
    }

    function reveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 _startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, _startTokenId, quantity);
        require(from == address(0) || !nftLocked, "Transfer is not allowed");
    }

    function mint(uint64 _mintAmount, bytes calldata signature)
        public
        callerIsUser
    {
        uint64 minted = _getAux(msg.sender);
        require(
            minted + _mintAmount < allowance,
            "Exceeds white list mint Allowance"
        );
        require(salelive, "minting is not currently available"); //ensure Public Mint is on
        require(
            totalSupply() + _mintAmount < maxCaveSupply,
            "Sorry, this would exceed maximum Cave mints"
        ); //require that the max number has not been exceeded
        require(
            _signerAddress ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(uint256(uint160(msg.sender)))
                    )
                ).recover(signature),
            "Signer address mismatch."
        ); //verify if address is whitelisted

        _mint(msg.sender, _mintAmount);
        _setAux(msg.sender, minted + _mintAmount);
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_ownershipOf(_tokenIds[i]).addr != account) return false;
        }

        return true;
    }
}
