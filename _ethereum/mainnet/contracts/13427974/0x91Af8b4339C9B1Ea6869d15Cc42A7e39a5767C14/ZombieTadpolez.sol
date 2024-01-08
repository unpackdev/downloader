pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";
import "./ERC721Burnable.sol";
import "./IERC721Receiver.sol";
import "./IERC20.sol";

/*

▒███████▒ ▒█████   ███▄ ▄███▓ ▄▄▄▄    ██▓▓█████▄▄▄█████▓ ▄▄▄      ▓█████▄  ██▓███   ▒█████   ██▓    ▓█████ ▒███████▒
▒ ▒ ▒ ▄▀░▒██▒  ██▒▓██▒▀█▀ ██▒▓█████▄ ▓██▒▓█   ▀▓  ██▒ ▓▒▒████▄    ▒██▀ ██▌▓██░  ██▒▒██▒  ██▒▓██▒    ▓█   ▀ ▒ ▒ ▒ ▄▀░
░ ▒ ▄▀▒░ ▒██░  ██▒▓██    ▓██░▒██▒ ▄██▒██▒▒███  ▒ ▓██░ ▒░▒██  ▀█▄  ░██   █▌▓██░ ██▓▒▒██░  ██▒▒██░    ▒███   ░ ▒ ▄▀▒░ 
  ▄▀▒   ░▒██   ██░▒██    ▒██ ▒██░█▀  ░██░▒▓█  ▄░ ▓██▓ ░ ░██▄▄▄▄██ ░▓█▄   ▌▒██▄█▓▒ ▒▒██   ██░▒██░    ▒▓█  ▄   ▄▀▒   ░
▒███████▒░ ████▓▒░▒██▒   ░██▒░▓█  ▀█▓░██░░▒████▒ ▒██▒ ░  ▓█   ▓██▒░▒████▓ ▒██▒ ░  ░░ ████▓▒░░██████▒░▒████▒▒███████▒
░▒▒ ▓░▒░▒░ ▒░▒░▒░ ░ ▒░   ░  ░░▒▓███▀▒░▓  ░░ ▒░ ░ ▒ ░░    ▒▒   ▓▒█░ ▒▒▓  ▒ ▒▓▒░ ░  ░░ ▒░▒░▒░ ░ ▒░▓  ░░░ ▒░ ░░▒▒ ▓░▒░▒
░░▒ ▒ ░ ▒  ░ ▒ ▒░ ░  ░      ░▒░▒   ░  ▒ ░ ░ ░  ░   ░      ▒   ▒▒ ░ ░ ▒  ▒ ░▒ ░       ░ ▒ ▒░ ░ ░ ▒  ░ ░ ░  ░░░▒ ▒ ░ ▒
░ ░ ░ ░ ░░ ░ ░ ▒  ░      ░    ░    ░  ▒ ░   ░    ░        ░   ▒    ░ ░  ░ ░░       ░ ░ ░ ▒    ░ ░      ░   ░ ░ ░ ░ ░
  ░ ░        ░ ░         ░    ░       ░     ░  ░              ░  ░   ░                 ░ ░      ░  ░   ░  ░  ░ ░    
░                                  ░                               ░                                       ░                                         ░                                        ░      ░                                  
*/

contract ZombieTadpolez is ERC721URIStorage, Ownable, IERC721Receiver {
    using Strings for uint256;
    event MintTadpole(address indexed sender, uint256 startWith, uint256 times);


    //uints 
    uint256 public totalTadpolez;
    uint256 public constant totalCount = 5555;
    uint256 public constant maxBatch = 10;
    address public zombieToadzAddress;
    address public brainzTokenAddress;
    uint32 public breedingCooldown = uint32(8 hours);
    uint256[] toadLastBred = new uint256[](5555);
    address public contractAddress;

    //strings 
    string public baseURI;

    //bool
    bool private started;

    //constructor args 
    constructor(string memory name_, string memory symbol_, address _zombieToadzAddress, address _brainzTokenAddress, string memory baseURI_) ERC721(name_, symbol_) {
        baseURI = baseURI_;
        zombieToadzAddress = _zombieToadzAddress;
        brainzTokenAddress = _brainzTokenAddress;
        contractAddress = address(this);
    }
    function totalSupply() public view virtual returns (uint256) {
        return totalTadpolez;
    }
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : ".json";
    }
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }
    function setStart(bool _start) public onlyOwner {
        started = _start;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function currentBrainzCost() public view returns (uint256) {

        if (totalTadpolez <= 999) {
            return 1000000000000000000000;
        }
        if (totalTadpolez <= 1999) {
            return 2000000000000000000000;
        }
        if (totalTadpolez <= 2999) {
            return 3000000000000000000000;
        }
        if (totalTadpolez <= 3999) {
            return 4000000000000000000000;
        }
        if (totalTadpolez <= 4999) {
            return 5000000000000000000000;
        }
        if (totalTadpolez <= 5555) {
            return 6000000000000000000000;
        }

        revert();
    }

    function getToadLastBred(uint256 tokenId) public view returns (uint256) {
        return toadLastBred[tokenId];
    }

    function breedToads(uint256[] calldata _tokenIds, uint256 amount) public {
        require(started, "not started");
        require(totalTadpolez < totalCount, "too many tadpolez");
        require(_tokenIds.length == 2, "you need 2 zombie toads to breed");
        require(amount >= currentBrainzCost(), "not enough brainz");
        // both toadz given must be owned by the caller of the function
        require(IERC721(zombieToadzAddress).ownerOf(_tokenIds[0]) == _msgSender()
            && IERC721(zombieToadzAddress).ownerOf(_tokenIds[1]) == _msgSender(),
            "must be the owner of both zombie toadz to breed");
        // both toadz must not have been recently bred
        require(block.timestamp - toadLastBred[_tokenIds[0]] > breedingCooldown
            && block.timestamp - toadLastBred[_tokenIds[1]] > breedingCooldown,
            "one or more zombietoad is on breeding cooldown");
        uint256 allowance = IERC20(brainzTokenAddress).allowance(msg.sender, address(this));
        require(amount <= allowance,
            string(abi.encodePacked("amount greater than allowed value of: ", allowance.toString())));

        // Transfer the required amount of brainz to this contract as payment for breeding
        IERC20(brainzTokenAddress).transferFrom(msg.sender, address(this), currentBrainzCost());
        // Create a tadpole and transfer it to the caller of the function
        emit MintTadpole(_msgSender(), totalTadpolez+1, 1);
        _mint(_msgSender(), ++totalTadpolez);

        // Assign the current time to the toad ids used for this breeding
        toadLastBred[_tokenIds[0]] = block.timestamp;
        toadLastBred[_tokenIds[1]] = block.timestamp;
    }

    function withdrawBrainz() public onlyOwner {
        uint256 brainzSupply = IERC20(brainzTokenAddress).balanceOf(address(this));
        IERC20(brainzTokenAddress).transfer(msg.sender, brainzSupply);
    }
    
}