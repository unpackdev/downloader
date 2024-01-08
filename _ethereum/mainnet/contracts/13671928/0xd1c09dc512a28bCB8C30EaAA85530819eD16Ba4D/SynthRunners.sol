// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./ChainRunnersTypes.sol";
import "./IChainRunnersRenderer.sol";

contract SynthRunners is ERC721, Ownable {
    uint public constant MINT_PRICE = 0.01 ether;
    address public renderingContractAddress;
    
    mapping(uint256 => ChainRunnersTypes.ChainRunner) runners;
    
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    
    mapping(address => bool) public minted;
    
    constructor() ERC721("Synth Runners", "SRUN") {}
    
    function setRenderingContractAddress(address _renderingContractAddress) public onlyOwner {
        renderingContractAddress = _renderingContractAddress;
    }
    
    function mint() external payable returns (uint256) {
        require(msg.value == MINT_PRICE, "Incorrect amount of ether sent");
        require(!minted[msg.sender], "Already minted");
        
        uint tokenId = tokenIds.current();
        
        minted[msg.sender] = true;
        tokenIds.increment();

        _safeMint(msg.sender, tokenId);
        runners[tokenId] = runner(msg.sender);
        
        return tokenId;
    }
    
    function runner(address _address) public pure returns (ChainRunnersTypes.ChainRunner memory) {
        uint256 dna = uint256(uint160(_address));
        return ChainRunnersTypes.ChainRunner(dna);
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        return tokenURI(_tokenId, runners[_tokenId]);
    }
    
    function tokenURI(address _address) public view returns (string memory) {
        return tokenURI(0, runner(_address));
    }
    
    function tokenURI(uint256 _tokenId, ChainRunnersTypes.ChainRunner memory _runnerData) internal view returns (string memory) {
        if (renderingContractAddress == address(0)) {
            return '';
        }
        IChainRunnersRenderer renderer = IChainRunnersRenderer(renderingContractAddress);
        return renderer.tokenURI(_tokenId, _runnerData);
    }
    
    receive() external payable {}

    function withdraw() public onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        require(success, "Withdrawal failed");
    }
}