// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Salvator is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    string private baseURI;
    string private notRevealedUri;
    uint256 public cost = 0.05 ether;
    uint256 public maxSupply = 10000;
    uint256 public nftPerAddressLimit = 10;
    uint256 public tokenCount = 0;
    bool public paused = false;
    bool public reveal;
    bool public presaleActive = true;
    bool public mainSaleActive;
    address[] public whitelistedAddresses;
    uint256 public winner1 = 0;
    uint256 public winner2 = 0;
    uint256 public winner3 = 0;
    uint256 public winner4 = 0;
    uint256 public winner5 = 0;

    mapping(address => uint256) public addressMintedBalance;

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri)
        ERC721("Salvator World", "SALVATOR")
    {
        baseURI = _initBaseURI;
        notRevealedUri = _initNotRevealedUri;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (reveal) {
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            baseURI,
                            "/",
                            tokenId.toString(),
                            ".json"
                        )
                    )
                    : "";
        } else {
            return bytes(notRevealedUri).length > 0 ? notRevealedUri : "";
        }
    }

    function preSaleMint(uint256 _amount) external payable {
        require(!paused, "the contract is paused");
        require(presaleActive, "Salvator World - Presale is not active.");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        uint256 supply = totalSupply();
        require(supply + _amount <= maxSupply, "max NFT limit exceeded");
        if (msg.sender != owner()) {
            require(
                ownerMintedCount + _amount <= nftPerAddressLimit,
                "max NFT per address exceeded"
            );
            require(
                isWhitelisted(_msgSender()),
                "Salvator World - Presale Only for Whitelist users."
            );
            require(_amount <= nftPerAddressLimit);
            require(
                msg.value == cost * _amount,
                "Salvator World::preSaleMint: insufficient ethers"
            );
        }

        for (uint256 i = 1; i <= _amount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, ++tokenCount);
        }
    }

    function mint(uint256 _amount) external payable {
        require(!paused, "the contract is paused");
        require(mainSaleActive, "Salvator World::mint: Mint is not active.");
        uint256 supply = totalSupply();
        require(supply + _amount <= maxSupply, "max NFT limit exceeded");
        if (msg.sender != owner()) {
            require(_amount <= nftPerAddressLimit);
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(
                ownerMintedCount + _amount <= nftPerAddressLimit,
                "max NFT per address exceeded"
            );
            require(
                msg.value >= cost * _amount,
                "Salvator World::mint: insufficient ethers"
            );
        }
        for (uint256 i = 1; i <= _amount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, ++tokenCount);
        }
    }

    //only owner
    function revealNFT() external onlyOwner {
        reveal = !reveal;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function pause() public onlyOwner {
        paused = !paused;
    }

    function activateMainSale() external onlyOwner {
        presaleActive = !presaleActive;
        mainSaleActive = !mainSaleActive;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function LotteryWinner() public onlyOwner {
        uint256 LotterySeed = uint256(
            keccak256(
                abi.encodePacked(
                    _msgSender(),
                    msg.sig,
                    block.timestamp,
                    block.difficulty,
                    block.coinbase
                )
            )
        );
        winner1 = (((LotterySeed) % tokenCount) + 1);
        winner2 = ((uint256(keccak256(abi.encodePacked(winner1))) %
            tokenCount) + 1);
        winner3 = ((uint256(keccak256(abi.encodePacked(winner2))) %
            tokenCount) + 1);
        winner4 = ((uint256(keccak256(abi.encodePacked(winner3))) %
            tokenCount) + 1);
        winner5 = ((uint256(keccak256(abi.encodePacked(winner4))) %
            tokenCount) + 1);
    }

    function withdraw() public onlyOwner {
        LotteryWinner();
        uint256 amount = address(this).balance;
        (bool os1, ) = payable(ownerOf(winner1)).call{
            value: amount.mul(2).div(100)
        }("");
        require(os1);
        (bool os2, ) = payable(ownerOf(winner2)).call{
            value: amount.mul(2).div(100)
        }("");
        require(os2);
        (bool os3, ) = payable(ownerOf(winner3)).call{
            value: amount.mul(2).div(100)
        }("");
        require(os3);
        (bool os4, ) = payable(ownerOf(winner4)).call{
            value: amount.mul(2).div(100)
        }("");
        require(os4);
        (bool os5, ) = payable(ownerOf(winner5)).call{
            value: amount.mul(2).div(100)
        }("");
        require(os5);
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
