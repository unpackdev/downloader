// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/*ERC721A*/

contract Gyrfalcon is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string public uri = "";
    string private uriSuffix = ".json";
    string public hiddenMetadataUri;

    bytes32 public merkleRoot =
        0xd291a188604227d94b0abe9b1d415af81e10206c6f2b52a655710bbc4b25da5f;

    uint256 public publicCost = 0.25 ether;
    uint256 public WlCost = 0.2 ether;

    //max nft supply
    uint256 public maxSupply = 5555;
    //max mint per trx
    uint256 public maxMintAmountPerTx = 20;
    //max mint per wallet
    uint256 public maxMintPerWallet = 20;

    bool public paused = false;
    bool public revealed = false;
    //bool checking openTo  public
    bool public OpenToPublic = false;
    bool private enabled = false;

    //mapping variables checking NFT amount per wallet
    mapping(address => uint256) public amountPerWallet;

    constructor() ERC721("Gyrfalcon", "GYR") {
        setHiddenMetadataUri("https://gyrfalcon.mypinata.cloud/ipfs/QmPDGjZMvgNjz5rzg7nxiTHHvfn4LS7Yct5j66WSCjfxWB");
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(!paused, "the contract is paused");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid minting amount!"
        );
        require(
            _mintAmount + amountPerWallet[msg.sender] <= maxMintPerWallet,
            "Buy limit exceeded"
        );
        require(
            _tokenIdCounter.current() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
    {
        require(!OpenToPublic, "Presale is finished!");
        require(msg.value >= WlCost * _mintAmount, "Insufficient funds!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        _mintLoop(msg.sender, _mintAmount);
    }

    // public
    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
    {
        require(OpenToPublic, "Sales not open to public");
  
        if (msg.sender != owner()) {
            require(
                msg.value >= publicCost * _mintAmount,
                "insufficient funds"
            );
        }
        _mintLoop(msg.sender, _mintAmount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setPublicCost(uint256 _cost) public onlyOwner {
        publicCost = _cost;
    }

    function setWlCost(uint256 _cost) public onlyOwner {
        WlCost = _cost;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    //concat ipfs
    function setUri(string memory _newUri) public onlyOwner {
        uri = _newUri;
    }

    function setOpenToPublic() public onlyOwner {
        OpenToPublic = true;
    }

    function setMaxMintAmountPerTx(uint256 _max) public onlyOwner {
        maxMintAmountPerTx = _max;
    }

    function setMaxMintPerWallet(uint256 _max) public onlyOwner {
        maxMintPerWallet = _max;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setEnabled(bool _enabled) public onlyOwner {
        enabled = _enabled;
    }

    function withdraw() external onlyOwner {
        require(enabled, "Withdraw is not enabled");
        payable(msg.sender).transfer(address(this).balance);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(_receiver, _tokenIdCounter.current());
            amountPerWallet[_receiver] += 1;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }
}
