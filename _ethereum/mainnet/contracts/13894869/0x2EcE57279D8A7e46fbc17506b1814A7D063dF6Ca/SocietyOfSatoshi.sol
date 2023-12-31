// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

contract SocietyOfSatoshi is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public constant maxTokens = 10000;
    uint256[5] public mintPrice = [
        10000000 ether,
        15000000 ether,
        20000000 ether,
        30000000 ether,
        50000000 ether
    ];

    bool public mintStarted = true;
    uint256 public batchLimit = 5;
    string public baseURI =
        "https://satoshi.mypinata.cloud/ipfs/QmZqZ5dfSQMtkmioUHpbHzGywWw4LtkuQb3BHEivoCrMXw";

    IERC20 public sosToken;

    constructor(address sosTokenAddress) ERC721("SocietyOfSatoshi", "SOS") {
        sosToken = IERC20(sosTokenAddress);
    }

    function mint(uint256 tokensToMint) public payable {
        uint256 supply = totalSupply();
        require(mintStarted, "Mint is not started");
        require(tokensToMint <= batchLimit, "Not in batch limit");
        require(
            (supply % 2000) + tokensToMint <= 2000,
            "Minting crosses price bracket"
        );
        require(
            supply.add(tokensToMint) <= maxTokens,
            "Minting exceeds supply"
        );

        uint256 cost = tokensToMint.mul(
            mintPrice[uint256(supply) / uint256(2000)]
        );
        uint256 allowance = sosToken.allowance(msg.sender, address(this));
        require(allowance >= cost, "Not enough allowance of SOS");

        sosToken.transferFrom(msg.sender, address(this), cost);

        for (uint16 i = 1; i <= tokensToMint; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function withdraw() public onlyOwner {
        sosToken.transfer(owner(), sosToken.balanceOf(address(this)));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function startMint() external onlyOwner {
        mintStarted = true;
    }

    function pauseMint() external onlyOwner {
        mintStarted = false;
    }

    function reserveSOS(uint256 numberOfMints) public onlyOwner {
        uint256 supply = totalSupply();
        for (uint256 i = 1; i <= numberOfMints; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
}
