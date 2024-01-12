// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";


contract BALC is ERC721A, Ownable {
    using Strings for uint256;

    string  public baseTokenURI;
    string  public defaultTokenURI;
    uint256 public maxSupply = 3333;
    bytes32 private _merkleRoot = 0xe8d4a95a1ed9108ea7e57ce5bda30490470d09cf7d7c449192aeda6478ee5faf;
    mapping(address => uint256) public allowlistuserinfo;

    enum EPublicMintStatus {
        CLOSED,
        ALLOWLIST_MINT,
        PUBLIC_MINT
    }
    EPublicMintStatus public publicMintStatus;


    constructor(
        string memory _baseTokenURI
    ) ERC721A("Bored Ape Legs Club", "BALC") {
        baseTokenURI = _baseTokenURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function mint(uint256 _quantity) external callerIsUser payable  {
        require(publicMintStatus==EPublicMintStatus.PUBLIC_MINT, "Public sale closed");
        require(_quantity > 0, "Invalid quantity");
        require(_quantity < 3, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupply, "Exceed supply");

        _safeMint(msg.sender, _quantity);

    }


    function allowlistmint(uint256 _quantity,bytes32[] calldata merkleProof) external callerIsUser payable  {
        require(publicMintStatus==EPublicMintStatus.ALLOWLIST_MINT, "Allowlist sale closed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, _merkleRoot, leaf), "Invalid merkle proof");
        require(totalSupply() + _quantity <= maxSupply, "Exceed supply");
        require(allowlistuserinfo[msg.sender]+_quantity<=20,"Exceed allowlist Sale");

        _safeMint(msg.sender, _quantity);
        allowlistuserinfo[msg.sender]+=_quantity;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
        bytes(currentBaseURI).length > 0 ? string(
            abi.encodePacked(
                currentBaseURI,
                tokenId.toString(),
                ".json"
            )
        ) : defaultTokenURI;
    }


    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function setPublicMintStatus(uint256 status)external onlyOwner{
        publicMintStatus = EPublicMintStatus(status);
    }


    function reversemint(address[] memory _reversemintaddress,uint256[] memory _quantity) external payable onlyOwner {
        require(publicMintStatus==EPublicMintStatus.PUBLIC_MINT || publicMintStatus==EPublicMintStatus.ALLOWLIST_MINT , "Reversemint sale closed");
        for (uint256 i=0;i<_reversemintaddress.length;i++){
            require(totalSupply() +_quantity[i] <= maxSupply , "Exceed supply");
            _safeMint(_reversemintaddress[i], _quantity[i]);
        }
    }


    function withdrawMoney() external onlyOwner  {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;

                    ownedTokenIndex++;
                }
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

}

