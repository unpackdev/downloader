// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./nftAttributes.sol";

contract EthJuanchos is ERC721, Ownable, ReentrancyGuard, Nftattributes{
    using Strings for uint256;
    using SafeMath for uint256;
    using Address for address;
    string public baseExtension = ".json";
    string public base = "";
    uint256 public cost = 50000000000000000;
    uint256 public maxSupply = 7777;
    bool public paused = true;
    address payable msig;
    address payable creators;
    mapping(address => bool) public whitelisted;
    mapping(uint256 => bool) private metadatas;
    mapping(uint256 => string) private tokenIdtoCandidate;
   
   
    uint256 public tokenCounter;
    event requestedCollectible(uint256 indexed candidate); 
    event transferFundsToCreator(uint256 amount, address creator);
    event transferFundsToMsig(uint256 amount, address msig);

    
   constructor() ERC721("Eth Juanchos", "JNH") {
      tokenCounter = 0;
  }

    function createCollectible() 
        public payable nonReentrant{
            //safe guards
            require(!paused, "Campaign is not live"); // campaign is on-going
            if (msg.sender != owner()) { //only request payment to non-whitelisted users
                if(whitelisted[msg.sender] != true) {
                require(msg.value >= cost, "You are not sending enough ETH");
                }
            }

            
            uint256 candidate = random();
            while (metadatas[candidate]) {
                candidate = (candidate.add(1)) % maxSupply;
            }
            metadatas[candidate] = true;

            //mint NFT
            uint256 newItemId = tokenCounter;
            _safeMint(msg.sender, newItemId);
            tokenIdtoCandidate[newItemId] = candidate.toString();
            emit requestedCollectible(candidate);
            tokenCounter++;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
 
    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }
 
    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token" );

        string memory currentBaseURI = base;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenIdtoCandidate[tokenId], baseExtension))
            : "";
    }
    function setBaseURI(string memory _base) public onlyOwner {
        base=_base;
    }

    function reserve(uint256 _quantity) public onlyOwner {

        for (uint256 i = 1; i <= _quantity; i++){
            uint256 candidate = random();
            while (metadatas[candidate]) {
                candidate = (candidate.add(1)) % maxSupply;
            }
            metadatas[candidate] = true;

            //mint NFT
            uint256 newItemId = tokenCounter;
            _safeMint(msg.sender, newItemId);
            tokenIdtoCandidate[newItemId] = candidate.toString();
            emit requestedCollectible(candidate);
            tokenCounter++;
        }
    }


    function random() private view returns (uint) {
        // sha3 and now have been deprecated
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, 'g2R2Jbe5MosRDDMB24oaRQfHqyTIe8SCqA36MctFMlhJQb7CCJ'))) % maxSupply;

        
    }
    function setMsig(address _msig) public onlyOwner{
        msig = payable(_msig);
    }

    function setMaxSupply(uint256 _supply) public onlyOwner{
        maxSupply = _supply;
    }

    function setCost(uint256 _cost) public onlyOwner{
        cost = _cost;
    }
    
    function setCreators(address _creators) public onlyOwner{
        creators = payable(_creators);
    }

    function withdrawAllFunds() public payable onlyOwner {
        require(msig != payable(0x0000000000000000000000000000000000000000), "You first need to set a msig account");
        require(creators != payable(0x0000000000000000000000000000000000000000), "You first need to set a creators account");
        require(address(this).balance > 0, "Not enough ETH in the contract");
        // TODO: create test to asset address(this).balance = 0 after withdraw() and what happens when balance = 0 when withdraw is called.
        uint256 baseFunds = (cost.mul(tokenCounter)).div(2);
        uint256 tipFundsWithBase2 = address(this).balance - baseFunds; //this contains the left overs from div(2), so the other half and all the tips.
        creators.transfer(baseFunds);
        emit transferFundsToCreator(baseFunds, creators);
        msig.transfer(tipFundsWithBase2);
        emit transferFundsToMsig(tipFundsWithBase2, msig);
    }
}
