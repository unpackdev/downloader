// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./VRFConsumerBase.sol";
import "./IERC721Enumerable.sol";
import "./AbstractERC1155Factory.sol";
import "./Counters.sol";

/*
* @title ERC1155 token for BlootDrip, including giveaways for Bloot holders with Chainlink VRF
*
* @author Niftydude
*/
contract BlootDripFactory is VRFConsumerBase, Ownable, AbstractERC1155Factory {
    using Counters for Counters.Counter;
    Counters.Counter private counter;     
    Counters.Counter public drawCounter;     

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    uint256 public lastDraw;

    mapping(uint256 => bool) public isMintingClosed;
    mapping(uint256 => string) public ipfsHashes;

    IERC721Enumerable public blootContract;

    event Winners(uint256 randomResult, uint256[] expandedResult);
    event Claimed(uint index, address indexed account, uint amount);

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee,
        address _blootContract,
        string memory _name, 
        string memory _symbol
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) ERC1155("ipfs://"){
        keyHash = _keyHash;
        fee = _fee;
        blootContract = IERC721Enumerable(_blootContract);
        name_ = _name;
        symbol_ = _symbol;        
    }

    function closeMinting(uint256 variant) external onlyOwner {
        require(counter.current() > variant, "closeMinting: nonexistent token");        

        isMintingClosed[variant] = true;
    }

    function addVariant(uint256 supply, string memory _ipfsMetadataHash) external onlyOwner {
        ipfsHashes[counter.current()] = _ipfsMetadataHash;
        
        if(supply > 0) {
            _mint(msg.sender, counter.current(), supply, "");
        }
        counter.increment();
    }  

    function increaseSupply(uint256 variant, uint256 additionalSupply) external onlyOwner {
        require(counter.current() > variant, "increaseSupply: nonexistent token");        
        require(!isMintingClosed[variant], "increaseSupply: Minting for variant is closed");
        require(additionalSupply > 0, "increaseSupply: must be bigger than 0");

        _mint(msg.sender, variant, additionalSupply, "");
    }        

    function editMetadata(uint256 variant, string memory _ipfsMetadataHash) external onlyOwner {
        require(counter.current() > variant, "EditMetadata: nonexistent token");

        ipfsHashes[variant] = _ipfsMetadataHash;
    }  

    function pickWinners(uint256 numWinners, uint256 variantId) external onlyOwner {
        require(counter.current() > variantId, "pickWinners: nonexistent token");        
        require(!isMintingClosed[variantId], "pickWinners: Minting for variant is closed");
        require(drawCounter.current() > lastDraw, "pickWinners: new VRF result not received yet");

        uint256[] memory expandedValues = new uint256[](numWinners);

        for (uint256 i = 0; i < numWinners; i++) {
            expandedValues[i] = (uint256(keccak256(abi.encode(randomResult, i))) % 8008) + 1;
            _mint(blootContract.ownerOf(expandedValues[i]), variantId, 1, "");
        }

        lastDraw += 1;
        emit Winners(randomResult, expandedValues);
    }

    function withdrawLink() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }

    function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    function uri(uint256 _id) public view override returns (string memory) {
            require(totalSupply(_id) > 0, "URI: nonexistent token");
            
            return string(abi.encodePacked(super.uri(_id), ipfsHashes[_id]));
    }       

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomResult = randomness;

        drawCounter.increment();        
    }
}
