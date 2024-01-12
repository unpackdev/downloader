// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//   __      _  ___  __  ____  ____  __ _   __   _  _  ____  _  _  _   __   _  _  _  _  _       __   __  __  __ _  ____ 
//  / _\    / )/ __)/  \(    \(  __)(  ( \ / _\ ( \/ )(  __)(_)/ )( \ / _\ ( \/ )( \/ )( \    _(  ) /  \(  )(  ( \(_  _)
// /    \  ( (( (__(  O )) D ( ) _) /    //    \/ \/ \ ) _)  _ ) __ (/    \/ \/ \/ \/ \ ) )  / \) \(  O ))( /    /  )(  
// \_/\_/   \_)\___)\__/(____/(____)\_)__)\_/\_/\_)(_/(____)(_)\_)(_/\_/\_/\_)(_/\_)(_/(_/   \____/ \__/(__)\_)__) (__) 

import "./IERC20.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract ApesForChange is ERC721A, Ownable {
    IERC20 public tokenAddress;

    uint256 public maxMint = 100; 
    uint256 public immutable maxSupply = 10000; 
    uint256 public maxReserved = 2000;  

    uint256 public price = 1 * 10 ** 18;
    string public baseURI = "";
    bytes32 public root;
    
    struct MintHistory {
        uint64 ownerFreeClaim;
    }
    mapping(address => MintHistory) public mintHistory;

    constructor(address _tokenAddress) ERC721A("Apes For Change", "A4C") {
        tokenAddress = IERC20(_tokenAddress);
        }

    function mint(uint256 _mintAmount) public payable {
        require(_mintAmount < maxMint + 1, "Error - TX Limit Exceeded");
        require(totalSupply() + _mintAmount < maxSupply - maxReserved + 1, "Error - Max Supply Exceeded");
        require(totalSupply() + _mintAmount < maxSupply + 1, "Error - Max Supply Exceeded");

        tokenAddress.transferFrom(msg.sender, address(this), price * _mintAmount);

        _safeMint(msg.sender, _mintAmount);
    }

    function claim(bytes32[] memory _proof, uint8 _maxAllocation, uint256 _mintAmount) public {
        require(totalSupply() + _mintAmount < maxSupply + 1, "Error - Max Supply Exceeded");
        require(MerkleProof.verify(_proof,root,keccak256(abi.encodePacked(msg.sender, _maxAllocation))),"Error - Verify Qualification");
        require(mintHistory[msg.sender].ownerFreeClaim + _mintAmount < _maxAllocation + 1,"Error - Wallet Claimed");

        mintHistory[msg.sender].ownerFreeClaim += uint64(_mintAmount);
        maxReserved -= uint64(_mintAmount);

        _safeMint(msg.sender, _mintAmount);
    }

    function _baseURI() internal view override(ERC721A) virtual returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice * 10 ** 18;
    }

    function withdrawToken() public onlyOwner {
        tokenAddress.transfer(msg.sender, tokenAddress.balanceOf(address(this)));
    }

    function setRoot(bytes32 root_) public onlyOwner {
        root = root_;
    }

    function setReserved(uint256 maxReserved_) public onlyOwner {
        maxReserved = maxReserved_;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
}