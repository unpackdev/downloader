// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Address.sol";
import "./MerkleProof.sol";

contract Punks70s is ERC721A, Ownable {

    // Settings
    string private baseURI;
    uint256 public maxSupply = 5000;
    uint256 public freeSupply = 2500;
    uint256 public maxFreeMint = 2;
    uint256 public mintPrice = 0.0042 ether;
    uint256 private maxMintPerTxn = 2;
    mapping(address => uint256) private _mintedAmount;

    // Sale config
    enum MintStatus {
        CLOSED,
        PUBLIC
    }
    MintStatus public mintStatus = MintStatus.CLOSED;

    constructor(
        string memory _initialBaseURI
    ) ERC721A("Punks70s", "VIBEZ") {
        baseURI = _initialBaseURI;
    }

    // Metadata
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Sale metadata
    function setMintStatus(uint256 _status) external onlyOwner {
        mintStatus = MintStatus(_status);
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setFreeSupply(uint256 _newFreeSupply) external onlyOwner {
        freeSupply = _newFreeSupply;
    }

    function setMaxFreeMint(uint256 _newMaxFreeMint) external onlyOwner {
        maxFreeMint = _newMaxFreeMint;
    }

    function setMintPrice(uint256 _newMintPrice) external onlyOwner {
        mintPrice = _newMintPrice;
    }

    function withdraw() external payable onlyOwner {
        Address.sendValue(
            payable(0xcc41943bE04A42B0Eb3CaDca7F37442D97FFd03e),
            (address(this).balance * 25) / 100
        );

        Address.sendValue(
            payable(0x970713DaCb35E63037c549650763D32B26F12473),
            (address(this).balance)
        );
    }

    // Mint
    function mint(uint256 _amount)
        external
        payable
    {
        require(mintStatus != MintStatus.CLOSED, "Sale is inactive!");
        require(tx.origin == msg.sender, "Only humans are allowed to mint!");
        require(_amount <= maxMintPerTxn, "Max mint per transaction exceeded!");
        require(_amount > 0, "Can't mint zero!");

        uint256 totalSupply = totalSupply();
             
        require(totalSupply + _amount <= maxSupply, "Can't mint that many!");   

        if (totalSupply + _amount <= freeSupply) {
            require(_mintedAmount[msg.sender] + _amount <= maxFreeMint, "Can't mint that many over free mint!");
            
            _internalMint(msg.sender, _amount);
        } else {
            require(msg.value >= mintPrice * _amount, "The ether value sent is not correct!");

            _internalMint(msg.sender, _amount);
        }
    }

    function _internalMint(address to, uint256 _amount) private {
        _mintedAmount[to] += _amount;
        _safeMint(to, _amount);
    }
}
