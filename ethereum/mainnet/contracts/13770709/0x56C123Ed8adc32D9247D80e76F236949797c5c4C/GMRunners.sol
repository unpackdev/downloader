// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./ChainRunnersTypes.sol";
import "./IChainRunnersRenderer.sol";
import "./IChainRunners.sol";

/*
   _____                 _   _           _ _
  / ____|               | | (_)         | | |
 | |  __  ___ _ __   ___| |_ _  ___ __ _| | |_   _
 | | |_ |/ _ \ '_ \ / _ \ __| |/ __/ _` | | | | | |
 | |__| |  __/ | | |  __/ |_| | (_| (_| | | | |_| |
  \_____|\___|_| |_|\___|\__|_|\___\__,_|_|_|\__, |
  __  __           _ _  __ _          _       __/ |
 |  \/  |         | (_)/ _(_)        | |     |___/
 | \  / | ___   __| |_| |_ _  ___  __| |
 | |\/| |/ _ \ / _` | |  _| |/ _ \/ _` |
 | |  | | (_) | (_| | | | | |  __/ (_| |
 |_|__|_|\___/ \__,_|_|_| |_|\___|\__,_|
 |  __ \
 | |__) |   _ _ __  _ __   ___ _ __ ___
 |  _  / | | | '_ \| '_ \ / _ \ '__/ __|
 | | \ \ |_| | | | | | | |  __/ |  \__ \
 |_|  \_\__,_|_| |_|_| |_|\___|_|  |___/


Take Control of Evolution. Design Your Baby. Break The Chain.
    made by abranti.eth (twitter.com/joaoabrantis)
*/

contract GMRunners is ERC721Enumerable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    address public genesisContractAddress;
    address public nextGenContractAddress;

    mapping(uint256 => ChainRunnersTypes.ChainRunner) runners;

    uint256 private constant MAX_RUNNERS = 420;
    uint256 mint_price;

    constructor(address _genesisContractAddress, address _nextGenContract, uint256 _mintPrice) ERC721("Genetically Modified Runners", "GMR") {
        genesisContractAddress = _genesisContractAddress;
        nextGenContractAddress = _nextGenContract;
        mint_price = _mintPrice;
    }

    function mint(uint256 dna, uint256 tokenId, bytes calldata signature) external payable nonReentrant {
        IERC721Enumerable genesis = IChainRunners(genesisContractAddress);
        require(tokenId == totalSupply() + 1, "Invalid tokenId");
        require(tx.origin == msg.sender, "No contracts");
        require(totalSupply() < MAX_RUNNERS, "Sold out");
        require(msg.value >= mint_price, "invalid eth");
        // Only holders of Chain Runners, Next-gen Runners, or GMR can access the CRISPR Lab
        if (genesis.balanceOf(msg.sender) == 0 && balanceOf(msg.sender) == 0) {
            IERC721Enumerable nextGen = IERC721Enumerable(nextGenContractAddress);
            require(nextGen.balanceOf(msg.sender) > 0, "No Access");
        }
        // The CRISPR Lab ensures that every GMR is unique and different from every original runner.
        require(verify(abi.encodePacked(dna, tokenId, msg.sender), signature), "Duplicated");

        ChainRunnersTypes.ChainRunner memory runner;
        runner.dna = dna;
        runners[tokenId] = runner;

        _safeMint(msg.sender, tokenId);
    }

    function verify(bytes memory message, bytes calldata signature) internal view returns (bool){
        return keccak256(message).toEthSignedMessageHash().recover(signature) == owner();
    }

    function getDna(uint256 _tokenId) public view returns (uint256) {
        return runners[_tokenId].dna;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        IChainRunnersRenderer renderer = IChainRunnersRenderer(IChainRunners(genesisContractAddress).renderingContractAddress());
        return renderer.tokenURI(_tokenId, runners[_tokenId]);
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mint_price = price;
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        require(success, "Withdrawal failed");
    }
}