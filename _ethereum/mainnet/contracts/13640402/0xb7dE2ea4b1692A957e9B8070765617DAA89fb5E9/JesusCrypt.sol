/*
JESUSCRYPT NFT
Web: https://jesuscrypt.io
Telegram: https://t.me/JesusCrypt
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Tradeable.sol";

contract JesusCrypt is ERC721Tradeable {
    uint256 public whitelistPrice = 0.04 ether;
    uint256 public price = 0.05 ether;
    uint256 public maxSupply = 10000;
    uint256 public reserved = 500;
    string private strBaseTokenURI;

    bool public whitelistActive = true;
    bytes32 private root =
        0xfc427ecf6a050a14e8edaf4d833dabaa0b21384beb89b703a698984f3f9060bd;

    constructor(string memory _strBaseTokenURI, address _proxyRegistryAddress)
        ERC721Tradeable("JesusCrypt", "JesusCrypt", _proxyRegistryAddress)
    {
        strBaseTokenURI = _strBaseTokenURI;
    }

    function baseTokenURI() public view override returns (string memory) {
        return strBaseTokenURI;
    }

    function getPrice() public view returns (uint256 actualPrice) {
        if (whitelistActive) {
            return whitelistPrice;
        } else {
            return price;
        }
    }

    function mintWhitelist(
        uint256 amount,
        bytes32 leaf,
        bytes32[] memory proof
    ) external payable {
        require(whitelistActive, "Whitelist is not active");
        require(
            amount <= 20,
            "JesusCrypt: Can only mint 20 JesusCrypt at a time!"
        );

        require(
            walletOfOwner(msg.sender).length + amount <= 20,
            "Max of 20 reached"
        );

        bool isWhitelisted = verifyWhitelist(leaf, proof);

        if (isWhitelisted) {
            mint(amount);
        } else {
            revert("Not whitelisted");
        }
    }

    function mintNormal(uint256 amount) external payable {
        require(!whitelistActive, "Whitelist is active");
        mint(amount);
    }

    function mint(uint256 amount) internal {
        uint256 supply = totalSupply();
        uint256 priceToMint = getPrice();
        require(!paused(), "JesusCrypt: Minting is paused!");
        require(amount > 0, "JesusCrypt: Must mint at least 1 JesusCrypt!");
        require(
            amount <= 20,
            "JesusCrypt: Can only mint 20 JesusCrypt at a time!"
        );
        require(
            supply + amount < maxSupply - reserved,
            "JesusCrypt: Mint will exceeded supply!"
        );
        require(
            msg.value >= priceToMint * amount,
            "JesusCrypt: Insufficient ETH sent!"
        );

        if (whitelistActive) {
            uint256 nftInWallet = walletOfOwner(msg.sender).length;
            if (nftInWallet >= 5) {
                revert("Only 20 tokens in whitelist allowe");
            }
        }

        // Mint  NFT
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
        // If pay more than price, return the difference
        if (msg.value > priceToMint * amount) {
            payable(msg.sender).transfer(msg.value - priceToMint * amount);
        }
    }

    function giveAway(address to, uint256 amount) external onlyOwner {
        require(amount <= reserved, "JesusCrypt: Reserve is empty!");

        uint256 supply = totalSupply();
        for (uint256 i; i < amount; i++) {
            _safeMint(to, supply + i);
        }
        reserved -= amount;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function changeBaseTokenURI(string memory newBaseTokenURI)
        external
        onlyOwner
    {
        strBaseTokenURI = newBaseTokenURI;
    }

    function changePrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function pause() external onlyOwner returns (bool) {
        _pause();
        return true;
    }

    function unpause() external onlyOwner returns (bool) {
        _unpause();
        return true;
    }

    function changeWhitelistState(bool newState) external onlyOwner {
        whitelistActive = newState;
    }

    function changeRoot(bytes32 newRoot) external onlyOwner {
        root = newRoot;
    }

    function verifyWhitelist(bytes32 leaf, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}
