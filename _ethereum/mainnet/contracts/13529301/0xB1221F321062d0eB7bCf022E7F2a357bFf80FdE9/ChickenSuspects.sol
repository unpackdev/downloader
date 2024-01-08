// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./VRFConsumerBase.sol";

contract ChickenSuspects is  ERC721Enumerable, Ownable, VRFConsumerBase {
    
    using SafeMath for uint256;

    uint256 public constant MAX_TOKENS = 4419;
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 20;
    uint256 public constant PRICE = 50000000000000000; // 0.05 Ether
    
    address private constant ADRESS1 = 0x0F9382f1d6c190d7910050FfB0BE7E1b58D99a5a;
    address private constant ADRESS2 = 0x1f800bde92bAcFcf443F2C2443b0FEb7Fa16e7F3;
    address private constant ADRESS3 = 0xc90F889a63B82650AAc4980B712EaCD0F326fEDa;
    
    uint256 public randomResult;
    uint256 public constant TIME_BETWEEN_DRAWS = 60 * 60 * 24; // 60 seconds * 60 minutes * 24 hours
    uint256 public lastDraw;
    
    bool internal canDrawWinner = false;
    bool internal saleIsActive = false;
    
    uint16[5] public suspects;
    uint16 public culprit;

    bytes32 internal keyHash;
    uint256 internal fee = 2 * 10 ** 18; // 2 LINKS;
    
    string public baseTokenURI; 
    
    constructor() 
        ERC721("Chicken Suspects", "CS") 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        ) 
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        lastDraw = block.timestamp - TIME_BETWEEN_DRAWS;
    }
    
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseUri(string memory baseURI) public onlyOwner{
        baseTokenURI = baseURI;
    }
    
    function flipSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 3;
        require(payable(ADRESS1).send(_each));
        require(payable(ADRESS2).send(_each));
        require(payable(ADRESS3).send(_each));
    }
    
    function mint(uint256 _count) public payable {
        uint256 total = totalSupply();
        require(total + _count < MAX_TOKENS + 1, "Not enough chickens left !");

        require(saleIsActive, "Sale is not active !");
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1, "You cannot buy that much chickens in a single transaction");
        require(msg.value >= PRICE.mul(_count), "Ether value sent is not correct");
        
        for(uint i = 0; i < _count; i++) {
            uint index = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, index);
            }
        }
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
    
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }
    
    function getCulprit() public onlyOwner {
        require(canDrawWinner == true, "You can't draw a winner yet !");
        
        bytes32 randomValue = getRandomNumber();
        
        culprit = suspects[uint256(randomValue)%5];
        
        canDrawWinner = false;
    }
    
    function getSuspect() public onlyOwner {
        
        require(lastDraw + TIME_BETWEEN_DRAWS < block.timestamp , "You need to wait more.");
        
        bytes32 randomValue = getRandomNumber();
        
        for (uint256 i = 0; i < 5; i++) {
            suspects[i] = uint16(uint256(keccak256(abi.encode(randomValue, i)))%4419);
        }
        
        lastDraw = block.timestamp;
        canDrawWinner = true;
    }
}