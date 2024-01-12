// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721SBT.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Base64.sol";

contract TORAPASS is
    ERC721SBT, ReentrancyGuard, Ownable
{

    struct TimeConfig{
        uint64 wlStartTime;
        uint64 wlEndTime;
        uint64 devStartTime;
        uint64 devEndTime;
    }

    string private constant _SYMBOL = "TAP"; 
    string private constant _NAME = "TORAPASS";
    uint256 public _PRICE = 200000000000000000; 
    bytes32 private wlRoot = 0xa76e40920641ee77ba02cf8867129234268e185d3bad05ece9990e99be619cf7; 
    bytes32 private constant devRoot = 0xab46b1f0c9d16b8e6e183ab520c1e44b537a9a0815c679a7312a70515328fefb;
    TimeConfig private _time; 

    constructor() ERC721SBT(_NAME, _SYMBOL) {
        _time.wlStartTime = uint64(1657771200);
        _time.wlEndTime = uint64(1658289600);
        _time.devStartTime = uint64(1658289600);
        _time.devEndTime = uint64(1658332799);
    }

    modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

    function wlMint(bytes32[] calldata _merkleProof) external payable nonReentrant callerIsUser{ 
        uint256 wlStartTime = uint256(_time.wlStartTime);
        uint256 wlEndTime = uint256(_time.wlEndTime);

        // Check if Chosen Mint has started or has ended
        require(block.timestamp > wlStartTime, "Chosen Mint has not started!");
        require(block.timestamp < wlEndTime, "Chosen Mint has ended!");

        // Basic Checks
        require(msg.value == _PRICE, "Strictly As Per Mint Price Required");
        require(isWhitelisted(_merkleProof, wlRoot, msg.sender), "You are not chosen to mint!");
        _safeMint(msg.sender);
    }

    function devMint(bytes32[] calldata _merkleProof) external payable nonReentrant callerIsUser{ 
        uint256 devStartTime = uint256(_time.devStartTime);
        uint256 devEndTime = uint256(_time.devEndTime);

        // Check if Chosen Mint has started or has ended
        require(block.timestamp > devStartTime, "Dev Mint has not started!");
        require(block.timestamp < devEndTime, "Dev Mint has ended!");

        require(isWhitelisted(_merkleProof, devRoot, msg.sender), "You are not eligible for dev mint!");

        _safeMint(msg.sender);
    }

    function isWhitelisted(bytes32[] calldata _merkleProof, bytes32 root, address user) private pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        require(MerkleProof.verify(_merkleProof, root, leaf), "User is not whitelisted");
        return true;
  }

    

    /*******************
     * Owner Functions *
     *******************/
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setWlRoot(bytes32 root) external onlyOwner nonReentrant {
        wlRoot = root;
    }

    function setMintConfig(uint256 _price, uint256 _wlStart, uint256 _wlEnd) external onlyOwner nonReentrant {
        _PRICE = _price;
        _time.wlStartTime = uint64(_wlStart);
        _time.wlEndTime = uint64(_wlEnd);
    }



    /***********************
     * Convenience getters *
     ***********************/
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "TORA PASS", "description": "TORA PASS gives you lifetime access to TORA Arsenal - our dashboard of tools for trading NFTs.",  "image_url": "ipfs://Qmb43U7D3MtPforkQ8Rr66rQMhrTDSNXLXzVZ3J2SS9eJn",  "animation_url": "ipfs://bafybeiah5sjiq4yw54lwbym7jmqk7e6to3jgou3bobjfruukjf6gnuxrbi"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));

    }

    function mintTimings() public view returns (TimeConfig memory) {
        return _time;
    }
    

    
}

