// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract DfNft is ERC721Enumerable,ERC721Burnable,ERC721Pausable,ReentrancyGuard,Ownable{

    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;

    event SetFeeTo(address indexed operator,address oldFeeTo,address newFeeTo);
    event SetTokenBaseURI(address indexed operator,string oldTokenBaseURI,string newTokenBaseURI);
    event SetUnrevealedURI(address indexed operator,string oldUnrevealedURI,string newUnrevealedURI);
    event Pause(address indexed operator,bool pause);
    event SetStage(address indexed operator, uint mintFee, uint maxMint, uint startTime, uint endTime, bool isWhitelist);

    Counters.Counter private _tokenIdTracker;

    struct Stage{
        uint mintFee;
        uint maxMint;
        uint startTime;
        uint endTime;
        bool isWhitelist;
    }

    Stage[] public stages;

    address public _feeTo;
    string public _tokenBaseURI;
    string public _unrevealedURI;

    mapping(uint => uint) public stageMinted;
    mapping(uint => mapping(address => uint)) public stageUserMinted;
    mapping(uint => mapping(address => uint)) public stageUserMinting;

    uint256 public constant MAX_MINT = 8888;
    uint256 public constant MAX_PER_MINT = 10;

    constructor(
        address feeTo,
        string memory unrevealedURI
    ) ERC721("Defense Force", "DFWN") {
        require(feeTo != address(0) ,"feeTo is the zero address");
        require(bytes(unrevealedURI).length > 0,"unrevealedURI can't be empty");

        _feeTo = feeTo;
        _unrevealedURI = unrevealedURI;

        Stage memory preSale = Stage({
            mintFee: 0.1 ether,
            maxMint: 5000,
            startTime: 1654099200,
            endTime: 1654358399,
            isWhitelist: true
        });
        stages.push(preSale);

        Stage memory airDrop = Stage({
            mintFee: 0,
            maxMint: 2800,
            startTime: 1654358400,
            endTime: 1654531199,
            isWhitelist: true
        });
        stages.push(airDrop);

        Stage memory sale = Stage({
            mintFee: 0.15 ether,
            maxMint: MAX_MINT,
            startTime: 1654531200,
            endTime: 1664553599,
            isWhitelist: false
        });
        stages.push(sale);
    }

    function mintNft(uint _count) external payable nonReentrant whenNotPaused{
        require(_count > 0,"Illegal _count");
        uint position = curStagePosition();
        require(position > 0, "Not on sale");
        mintNft(position.sub(1),_count);
    }

    function mintNft(uint index, uint _count) private{
        uint mintFee = stages[index].mintFee;

        uint _mintable = mintable(index,_msgSender());
        require(_mintable >= _count, "There is not enough surplus");
        require(msg.value >= mintFee.mul(_count), "The ether value sent is not correct");

        payable(_feeTo).transfer(msg.value);
        multipleMint(_count);

        stageMinted[index] = stageMinted[index].add(_count);
        stageUserMinted[index][_msgSender()] = stageUserMinted[index][_msgSender()].add(_count);
    }

    function curStagePosition() public view returns (uint){
        for(uint i=0; i< stages.length; i++){
            if(block.timestamp >= stages[i].startTime && block.timestamp <= stages[i].endTime){
                return i+1;
            }
        }
        return 0;
    }

    function mintable(uint index, address account) public view returns (uint){
        Stage storage stage = stages[index];
        if(block.timestamp < stage.startTime || block.timestamp > stage.endTime){
            return 0;
        }

        uint minted = totalSupply();
        uint _stageMinted = stageMinted[index];
        uint userMinted = stageUserMinted[index][account];
        uint userMinting = stageUserMinting[index][account];

        if(minted >= MAX_MINT){
            return 0;
        }

        if(_stageMinted >= stage.maxMint){
            return 0;
        }

        return stage.isWhitelist ? userMinting.sub(userMinted) : MAX_PER_MINT.sub(userMinted);
    }

    function multipleMint(uint count) private{
        for(uint i=0; i<count; i++){
            _tokenIdTracker.increment();
            _safeMint(_msgSender(), _tokenIdTracker.current());
        }
    }

    function setFeeTo(address newFeeTo) public onlyOwner{
        address oldFeeTo = _feeTo;
        _feeTo = newFeeTo;

        emit SetFeeTo(_msgSender(),oldFeeTo,newFeeTo);
    }

    function setTokenBaseURI(string memory newTokenBaseURI) public onlyOwner{
        string memory oldTokenBaseURI = _tokenBaseURI;
        _tokenBaseURI = newTokenBaseURI;

        emit SetTokenBaseURI(_msgSender(),oldTokenBaseURI,newTokenBaseURI);
    }

    function setUnrevealedURI(string memory newUnrevealedURI) public onlyOwner{
        string memory oldUnrevealedURI = _unrevealedURI;
        _unrevealedURI = newUnrevealedURI;

        emit SetUnrevealedURI(_msgSender(),oldUnrevealedURI,newUnrevealedURI);
    }

    function pause() public onlyOwner{
        _pause();
        emit Pause(_msgSender(),paused());
    }

    function unpause() public onlyOwner{
        _unpause();
        emit Pause(_msgSender(),paused());
    }

    function setWhitelist(address[] memory whitelist, uint index, uint minting) public onlyOwner{
        require(minting > 0, "Illegal minting");
        for(uint i=0; i< whitelist.length; i++){
            address account = whitelist[i];
            require(stageUserMinted[index][account] <= minting, "Illegal minting");
            stageUserMinting[index][account] = minting;
        }
    }

    function setStage(uint index, uint mintFee, uint maxMint, uint startTime, uint endTime, bool isWhitelist) public onlyOwner{
        require(maxMint > 0,"Illegal maxMint");
        require(startTime < endTime,"Illegal time");

        Stage storage stage = stages[index];
        stage.mintFee = mintFee;
        stage.maxMint = maxMint;
        stage.startTime = startTime;
        stage.endTime = endTime;
        stage.isWhitelist = isWhitelist;

        emit SetStage(_msgSender(),mintFee,maxMint,startTime,endTime,isWhitelist);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(_tokenBaseURI).length > 0 ? string(abi.encodePacked(_tokenBaseURI, tokenId.toString())) : _unrevealedURI;
    }

    function showBlockTime() public view returns(uint){
        return block.timestamp;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }
}
