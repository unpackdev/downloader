// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/****************************************
 * A KostbarFurimmer CONTRACT
 * @author: @itsanishjain
 ****************************************/

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract KostbarFurimmer is ERC721A, Ownable {
    uint256 public presaleStart = 1659639600;
    uint256 public presaleEnd = 1659729600;
    uint256 public tokenTransferedToTeam;

    uint256 public maxSupply = 6100;
    uint256 public maxPerTx = 10;
    uint256 public presalePrice = 0.05 ether;
    uint256 public publicPrice = 0.08 ether;

    bytes32 public root;

    string public baseTokenURI;
    string public uriSuffix = ".json";

    bool public revealed;
    bool public paused;

    modifier onlyWhenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "NonEOA");
        _;
    }

    constructor(
        string memory _baseTokenURI,
        bytes32 _root,
        address _treasury
    ) ERC721A("Kostbar Fur immer", "KF") {
        baseTokenURI = _baseTokenURI;
        root = _root;
        _mint(_treasury, 192);
    }

    function isValid(bytes32[] memory proof, bytes32 leaf)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    function presaleMint(uint256 quantity, bytes32[] memory proof)
        external
        payable
        onlyWhenNotPaused
        callerIsUser
    {
        require(
            block.timestamp > presaleStart && block.timestamp < presaleEnd,
            "NonPresalePeriod"
        );

        require(quantity <= maxPerTx, "ExceededMaxPerTx");

        require(
            isValid(proof, keccak256(abi.encodePacked(msg.sender))),
            "NonWhitelisted"
        );

        require(_totalMinted() + quantity <= maxSupply, "SupplyExceeded");

        require(msg.value >= presalePrice * quantity, "InvalidEtherAmount");

        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity)
        external
        payable
        onlyWhenNotPaused
        callerIsUser
    {
        require(block.timestamp > presaleEnd, "NonPublicPeriod");

        require(quantity <= maxPerTx, "ExceededMaxPerTx");

        require(_totalMinted() + quantity <= maxSupply, "SupplyExceeded");

        require(msg.value >= publicPrice * quantity, "InvalidEtherAmount");

        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "InvalidTokenId");

        string memory baseURI = _baseURI();
        if (!revealed) return baseURI;

        return string(abi.encodePacked(baseURI, _toString(tokenId), uriSuffix));
    }

    function mintMany(address[] calldata _to, uint256[] calldata _amount)
        external
        onlyOwner
    {
        for (uint256 i; i < _to.length; ) {
            _mint(_to[i], _amount[i]);
            unchecked {
                i++;
            }
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "WithdrawFailed");
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setPaused(bool _pasused) public onlyOwner {
        paused = _pasused;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setRevealed(bool _state) external onlyOwner {
        revealed = _state;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPresalePrice(uint256 _price) external onlyOwner {
        presalePrice = _price;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_totalMinted() > _maxSupply, "InvalidMaxSupply");
        maxSupply = _maxSupply;
    }

    function setSaleTimings(uint256 _presaleStart, uint256 _presaleEnd)
        external
        onlyOwner
    {
        presaleStart = _presaleStart;
        presaleEnd = _presaleEnd;
    }

    function transferToTeam(address[] calldata tos) external onlyOwner {
        for (uint256 i; i < tos.length; ) {
            for (uint256 j; j < 4; ) {
                transferFrom(msg.sender, tos[i], j + tokenTransferedToTeam);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
                tokenTransferedToTeam += 4;
            }
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
