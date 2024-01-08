pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Strings.sol";

interface IStaking {
    function depositsOf(address account) external view returns (uint256[] memory);
}

contract HeavenOrHell is Ownable, ERC721Enumerable {
    using Strings for uint256;
    //berries token address
    IERC20 public berriesAddress;
    //staking address 
    IStaking public stakingAddress;
    //bear address
    IERC721 public bearAddress;

    //checks if tokenId has been used to roll. 
    mapping (uint256=>bool) public rollUsed;

    //uints
    //angel Supply 
    uint256 public angelSupply = 1000;
    //angel total supply
    uint256 public angelTotalSupply;
    //witch supply
    uint256 public witchSupply = 8000;
    //witch total supply
    uint256 public witchTotalSupply;
    //current supply 
    uint256 public totalBears;
    //roll price 50000000000000000000
    uint256 public berriesCost = 50000000000000000000; 

    //bool
    bool private started;

    //string 
    string public baseURI;

    //constructor args 
    constructor(
        string memory name_, 
        string memory symbol_, 
        string memory _baseURI, 
        address _berriesAddress, 
        address _stakingAddress,
        address _bearAddress
        ) 
        ERC721(
            name_, 
            symbol_
            ) 
    {
        baseURI = _baseURI;
        berriesAddress = IERC20(_berriesAddress);
        stakingAddress = IStaking(_stakingAddress);
        bearAddress = IERC721(_bearAddress); 
    }

    function setAddresses(address _berriesAddress, address _stakingAddress, address _bearAddress) public onlyOwner {
        berriesAddress = IERC20(_berriesAddress);
        stakingAddress = IStaking(_stakingAddress);
        bearAddress = IERC721(_bearAddress);
    }

    function random(string memory input) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function roll() internal view returns (uint256) {
        uint256 rand = random(block.timestamp.toString()) % 10;
        if (rand == 1) {
            return 0;
        }
        if (rand == 2) {
            return 1;
        }
        if (rand > 2 && rand <= 10) {
            return 2;
        }
    }

    function mintBearStaked(uint256 amount, uint256 tokenId) public returns (string memory) {
        require(amount >= berriesCost, "need more berries");
        require(!rollUsed[tokenId], "roll used!");
        require(started, "not started");
        require(totalBears < angelSupply + witchSupply, "too many bears");
        berriesAddress.transferFrom(_msgSender(), address(this), amount);
        uint256[] memory deposits = stakingAddress.depositsOf(_msgSender()); 
        for (uint256 i; i < deposits.length; i++) {
            if (deposits[i] == tokenId) {
                rollUsed[tokenId] = true;
                uint256 rollOutcome = roll();
                if (rollOutcome == 1 && angelTotalSupply < 1000) {
                    _mint(_msgSender(), ++angelTotalSupply);
                    totalBears++;
                    return "Heaven";
                }
                if (rollOutcome == 2 && witchTotalSupply < 8000) {
                    _mint(_msgSender(), angelSupply + ++witchTotalSupply);
                    totalBears++;
                    return "Hell";
                }
                return "Nothing!";
            }
        }
        revert("Invalid tokenId given");
    }

    function mintBear(uint256 amount, uint256 tokenId) public returns (string memory) {
        require(bearAddress.ownerOf(tokenId) == _msgSender(), "Must own bear");
        require(amount >= berriesCost, "need more berries");
        require(!rollUsed[tokenId], "roll has been used");
        require(started, "not started");
        require(totalBears < angelSupply + witchSupply, "too many bears");
        rollUsed[tokenId] = true;
        berriesAddress.transferFrom(_msgSender(), address(this), amount);
        uint256 rollOutcome = roll();
        if (rollOutcome == 1 && angelTotalSupply < 1000) {
            _mint(_msgSender(), ++angelTotalSupply);
            totalBears++;
            return "Heaven";
        }
        if (rollOutcome == 2 && witchTotalSupply < 8000) {
            _mint(_msgSender(), angelSupply + ++witchTotalSupply);
            totalBears++;
            return "Hell";
        }
        return "Nothing!";
    }

    function resetRoll(uint256[] calldata tokenIds) public onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            rollUsed[tokenIds[i]] = false; 
        }
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '.json';
    }
    function setStart(bool _start) public onlyOwner {
        started = _start;
    }
}