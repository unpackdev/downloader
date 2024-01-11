// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";

error Paused();
error NotMintingTimeYet();
error MintZeroAmount();
error MaxMintAmount();
error SupplyExceeded();
error NotEnoughValue();
error WalletBalanceExceeded();

contract GrupoVIP is ERC721A, Ownable {
    string baseURI;
    uint256 public cost = 29e17; // 2.9 ETH
    uint256 public maxSupply = 25;
    uint256 public maxMintAmount = 3;
    uint256 public timeDeployed;
    uint256 public allowMintingAfter = 0;
    bool public isPaused = false;

    mapping(address => uint256) public tokensPerWallet;

    constructor(
        uint256 _allowMintingOn,
        string memory _initBaseURI
    ) ERC721A("Grupo VIP NFT", "GVIP") {
        if (_allowMintingOn > block.timestamp) {
            allowMintingAfter = _allowMintingOn - block.timestamp;
        }

        timeDeployed = block.timestamp;

        setBaseURI(_initBaseURI);
    }

    receive() external payable {
        uint256 mintAmount = msg.value / cost;
        __mint(mintAmount);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        __mint(_mintAmount);
    }

    function __mint(uint256 _mintAmount) internal {
        if (block.timestamp < timeDeployed + allowMintingAfter)
            revert NotMintingTimeYet();
        if (_mintAmount == 0) revert MintZeroAmount();
        if (_mintAmount > maxMintAmount) revert MaxMintAmount();

        uint256 supply = totalSupply();

        if (supply + _mintAmount > maxSupply) revert SupplyExceeded();

        if (msg.sender != owner()) {
            if (isPaused) revert Paused();
            if (msg.value < cost * _mintAmount) revert NotEnoughValue();
        }

        if (msg.value > 0) {
            uint256 change = msg.value - cost * _mintAmount;
            if (change > 0) Address.sendValue(payable(msg.sender), change);
        }

        if (tokensPerWallet[msg.sender] + _mintAmount > maxMintAmount) {
            revert WalletBalanceExceeded();
        }

        tokensPerWallet[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        // run ERC721A validation - ignore returned value
        ERC721A.tokenURI(tokenId);

        return _baseURI();
    }

    function getSecondsUntilMinting() public view returns (uint256) {
        if (block.timestamp < timeDeployed + allowMintingAfter) {
            return (timeDeployed + allowMintingAfter) - block.timestamp;
        } else {
            return 0;
        }
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setIsPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    function withdraw() public onlyOwner {
        Address.sendValue(payable(0x85b0C041033F808deADac913da7351F9393268eC), address(this).balance); 
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
