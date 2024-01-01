// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC20.sol";

contract XZKitty is ERC721Enumerable, Ownable {
    bool private enabledBurn;
    mapping(uint256 => uint256) private config;
    string private baseURI;

    address private zkitty;

    address private constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    event MintToken(
        address indexed from,
        uint amountZkitty,
        uint amountXZkitty
    );

    constructor(address _zkitty) ERC721("xZKITTY", "xZKITTY") {
        zkitty = _zkitty;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function setEnableBurn(bool value) public onlyOwner {
        enabledBurn = value;
    }

    function getEnableBurn() public view returns (bool) {
        return enabledBurn;
    }

    // @notice Admin can set how many ZKitty tokens are required per each burn.
    // @notice 0 means that there is no such tier
    // @notice to receive the amount of NFT's that need burning getConfig(uint xZkittyAmount)
    // @param xZkittyAmount of NFT's that will be minted set the burn amount for
    // @param zkittyAmount Amounyt of tokens that need to be burned

    function setConfig(uint xZkittyAmount, uint zkittyAmount) public onlyOwner {
        config[xZkittyAmount] = zkittyAmount;
    }

    function getConfig(uint xZkittyAmount) public view returns (uint) {
        return config[xZkittyAmount];
    }

    modifier activeBurn() {
        require(enabledBurn, "ERROR: Disabled burn");
        _;
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    // @notice Burn has to be activated by admin using setEnableBurn, and can be checked by getEnableBurn
    // @param amount of NFT's that will be minted

    function mint(uint amount) public activeBurn {
        IERC20 zkittyToken = IERC20(zkitty);
        uint amountZkitty = config[amount];

        require(config[amount] > 0, "ERROR: Invalid burn amount");
        require(
            amountZkitty <= zkittyToken.balanceOf(_msgSender()),
            "ERROR: Amount exceeds balance"
        );

        zkittyToken.transferFrom(_msgSender(), DEAD_ADDRESS, amountZkitty);

        for (uint i = 0; i < amount; i++) {
            safeMint(_msgSender());
        }

        emit MintToken(_msgSender(), amountZkitty, amount);
    }

    function adminMint(address to, uint256 amount) external onlyOwner {
        for (uint i = 0; i < amount; i++) {
            safeMint(to);
        }
    }

    function getOwnedNftsIdsByAddress(
        address owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokenIds;
    }
}
