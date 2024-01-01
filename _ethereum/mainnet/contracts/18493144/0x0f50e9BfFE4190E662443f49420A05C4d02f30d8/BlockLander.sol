// SPDX-License-Identifier: GNU LGPLv3
pragma solidity 0.8.13;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract blockLander is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bytes32 immutable DOMAIN_SEPARATOR;
    string public metadataFolderURI;
    mapping(uint256 => uint256) public minted;
    mapping(uint256 => address) public minterMap;
    address public validSigner;
    bool public mintActive;
    uint256 public mintsPerAddress;
    string public openseaContractMetadataURL;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _slug,
        string memory _metadataFolderURI,
        uint256 _mintsPerAddress,
        string memory _openseaContractMetadataURL,
        bool _mintActive,
        address _validSigner
    ) ERC721(_name, _symbol) {
        metadataFolderURI = string.concat(_metadataFolderURI, "/");
        mintsPerAddress = _mintsPerAddress;
        openseaContractMetadataURL = string.concat(_openseaContractMetadataURL, _slug);
        mintActive = _mintActive;
        validSigner = _validSigner;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(abi.encodePacked(_slug)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    function setValidSigner(address _validSigner) external onlyOwner {
        validSigner = _validSigner;
    }

    function setMetadataFolderURI(string calldata folderUrl) public onlyOwner {
        metadataFolderURI = folderUrl;
    }
    
    function setContractMetadataFolderURI(string calldata folderUrl) public onlyOwner {
        openseaContractMetadataURL = folderUrl;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(metadataFolderURI, Strings.toString(tokenId))
            );
    }

    function contractURI() public view returns (string memory) {
        return openseaContractMetadataURL;
    }

    function mintWithSignature(
        address minter,
        uint256 validatorIndex,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable returns (uint256) {
        // console.log("why doesn't this work", block.chainid);
        require(mintActive == true, "mint is not active rn..");
        // require(tx.origin == msg.sender, "dont get Seven'd");
        require(minter == msg.sender, "you have to mint for yourself");
        require(
            minted[validatorIndex] < mintsPerAddress,
            "only 1 mint per validator index"
        );

        bytes32 payloadHash = keccak256(abi.encode(DOMAIN_SEPARATOR, minter, validatorIndex));
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash)
        );

        address actualSigner = ecrecover(messageHash, v, r, s);


        require(actualSigner != address(0), "ECDSA: invalid signature");
        require(actualSigner == validSigner, "Invalid signer");

        _tokenIds.increment();

        minted[validatorIndex]++;

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);

        minterMap[tokenId] = minter;

        return tokenId;
    }

    function mintedCount() external view returns (uint256) {
        return _tokenIds.current();
    }

    function setMintActive(bool _mintActive) public onlyOwner {
        mintActive = _mintActive;
    }

    function getAddress() external view returns (address) {
        return address(this);
    }

    function minterOf(uint256 tokenId) public view returns (address) {
        return minterMap[tokenId];
    }
}
