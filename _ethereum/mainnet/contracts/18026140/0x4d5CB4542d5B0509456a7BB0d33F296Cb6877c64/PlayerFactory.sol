// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

struct PlayerProcessData {
    uint256 creationBlock;
    bytes createBytes;
}

/**
 * @title PlayerFactory
 * PlayerFactory - ERC721 contract that creates unique CRPTL players
 */
contract PlayerFactory is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _nextTokenId;

    uint256 private firstNamesLength = 2048;
    uint256 private lastNamesLength = 2048;
    mapping(uint256 => PlayerProcessData) private playerProcess;
    mapping(uint256 => uint256) private players;
    mapping(uint256 => string) private tokenURIs;
    address private manager;
    uint256 private basePrice = 0.001 ether;
    uint256 private priceStep = 0.001 ether;
    uint private maxPlayers = 5555;
    string private dataURI;
    string private enhancerURI;
    string[] private positions = ["GK", "DF", "MF", "FW"];

    event seedCreated(uint256 _tokenId);

    constructor () ERC721("Crptl", "CRPTL")
    {
        _nextTokenId.increment();
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can do this");
        _;
    }

    function setContractDataURI(string memory _uri) public onlyManager {
        dataURI = _uri;
    }

    function setContractEnhancerURI(string memory _uri) public onlyManager {
        enhancerURI = _uri;
    }

    function contractDataURI() public view returns (string memory) {
        return dataURI;
    }

    function contractEnhancerURI() public view returns (string memory) {
        return enhancerURI;
    }

    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }

    /**
     * @dev Set URI for the token metadata for AI-generation step
     * @param _tokenId ID of the tokent to set info
     * @param _uri URI of the token metadata
     */
    function setTokenURI(uint256 _tokenId, string calldata _uri) public onlyManager {
        require(_tokenId <= totalSupply());
        tokenURIs[_tokenId] = _uri;
    }

    /**
     * @dev Returns the price of the new player
     */
    function currentPrice() public view returns (uint256) {
        return basePrice + totalSupply() * priceStep;
    }

    /**
     * @dev Returns URI for the player metadata
     * @param _tokenId ID of the tokent to get info
     */
    function tokenURI(uint256 _tokenId) override virtual public view returns (string memory) {
        require(_tokenId <= totalSupply());
        return tokenURIs[_tokenId];
    }

    function _getSeedSegment(uint256 _tokenId, uint _start, uint _end) view internal returns(uint256) {
        uint256 seed = players[_tokenId];
        require (seed != 0);
        uint256 mask = (1 << (_end - _start)) - 1;
        return ((seed >> _start) & mask);
    }

    function createSeed(uint256  _tokenId) public onlyManager {
        PlayerProcessData memory pd = playerProcess[_tokenId];
        require(pd.creationBlock != 0);
        uint256 seed = uint256(
            keccak256(abi.encodePacked(
                pd.createBytes,
                blockhash(block.number - ((block.number - pd.creationBlock) % 256))
        )));
        players[_tokenId] = seed;
        delete playerProcess[_tokenId];
        emit seedCreated(_tokenId);
    }

    /**
     * @dev Generates a new player token
     * @param _to address of the future owner of the token
     */
    function newPlayer(address _to) public payable {
        require(msg.value >= currentPrice(), "Value is not enough for creating player");
        require(totalSupply() < maxPlayers, "All players have been created");
        uint256 currentTokenId = _nextTokenId.current();
        playerProcess[currentTokenId] = PlayerProcessData({
            creationBlock: block.number, 
            createBytes: abi.encodePacked(msg.sender, currentTokenId)
        });
        _safeMint(_to, currentTokenId);
        _nextTokenId.increment();
    }

    /**
      @dev Returns the total tokens minted so far.
      1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view override returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    /**
     * @dev Returns the first name index of the player
     * @param _tokenId ID of the tokent to get info
     */
    function firstNameIndex(uint256 _tokenId) public view returns(uint256) {
        return _getSeedSegment(_tokenId, 0, 10) % firstNamesLength;
    }

    /**
     * @dev Returns the last name index of the player
     * @param _tokenId ID of the tokent to get info
     */
    function lastNameIndex(uint256 _tokenId) public view returns(uint256) {
        return _getSeedSegment(_tokenId, 10, 20) % lastNamesLength;
    }

    /**
     * @dev Returns the skill level of the player
     * @param _tokenId ID of the tokent to get info
     */
    function skill(uint256 _tokenId) public view returns(uint) {
        return 36 + _getSeedSegment(_tokenId, 20, 26);
    }

    /**
     * @dev Returns the pace level of the player
     * @param _tokenId ID of the tokent to get info
     */
    function pace(uint256 _tokenId) public view returns(uint) {
        return 36 + _getSeedSegment(_tokenId, 26, 32);
    }

    /**
     * @dev Returns the physical level of the player
     * @param _tokenId ID of the tokent to get info
     */
    function physical(uint256 _tokenId) public view returns(uint) {
        return 36 + _getSeedSegment(_tokenId, 32, 38);
    }

    /**
     * @dev Returns the encoded player position
     * @param _tokenId ID of the tokent to get info
     */
    function position(uint256 _tokenId) public view returns(string memory) {
        return positions[_getSeedSegment(_tokenId, 38, 40)];
    }

    /**
     * @dev Returns the rating of the player
     * @param _tokenId ID of the tokent to get info
     */
    function rating(uint256 _tokenId) public view returns(uint) {
        return _getSeedSegment(_tokenId, 40, 42);
    }


    /**
     * @dev Returns the seed used to generate player's face
     * @param _tokenId ID of the tokent to get info
     */
    function faceSeed(uint256 _tokenId) public view returns(uint8[512] memory) {
        uint256 preSeed = _getSeedSegment(_tokenId, 42, 256);
        uint8[512] memory result;
        bytes32 hash;
        for (uint i=0; i < 16; i++) {
            hash = keccak256(abi.encodePacked(preSeed, i));
            for (uint j=0; j < 32; j++) {
                result[32*i + j] = uint8(hash[j]);
            }
        }
        return result;
    }

    /**
     * @dev Returns the balance of the smart contract
     */
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    /**
     * @dev Allows owner to withdraw all the ethereum stored on the contract
     */
    function withdraw() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    function getAllTokensByOwner(address _owner) external view returns (uint256[] memory) {
        uint256 bal = balanceOf(_owner);
        uint256[] memory ids = new uint256[](bal);
        for (uint256 i = 0; i < bal; i++) {
            ids[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return ids;
    }
}
