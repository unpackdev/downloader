//SPDX-License-Identifier: MIT

/*
  __________  ___    _   _______ __  _________________ ________  _   _______
 /_  __/ __ \/   |  / | / / ___//  |/  /  _/ ___/ ___//  _/ __ \/ | / / ___/
  / / / /_/ / /| | /  |/ /\__ \/ /|_/ // / \__ \\__ \ / // / / /  |/ /\__ \ 
 / / / _, _/ ___ |/ /|  /___/ / /  / // / ___/ /__/ // // /_/ / /|  /___/ / 
/_/ /_/ |_/_/  |_/_/ |_//____/_/  /_/___//____/____/___/\____/_/ |_//____/  
    __________  ____  __  ___
   / ____/ __ \/ __ \/  |/  /
  / /_  / /_/ / / / / /|_/ / 
 / __/ / _, _/ /_/ / /  / /  
/_/   /_/ |_|\____/_/  /_/   
    ___    __    ___________   __   _       ______  ____  __    ____ 
   /   |  / /   /  _/ ____/ | / /  | |     / / __ \/ __ \/ /   / __ \
  / /| | / /    / // __/ /  |/ /   | | /| / / / / / /_/ / /   / / / /
 / ___ |/ /____/ // /___/ /|  /    | |/ |/ / /_/ / _, _/ /___/ /_/ / 
/_/  |_/_____/___/_____/_/ |_/     |__/|__/\____/_/ |_/_____/_____/  
BY BEEBLEBLOCKS
*/

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";


contract TRANSMISSIONS is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public constant maxSupply = 500;
    uint256 public WLcost = 0.014 ether;
    uint256 public pubCost = 0.02 ether;
    bytes32 private merkleRoot;
    bool public wlActive;
    bool public pubActive;
    string private baseURI;
    bool public appendedID;
    mapping(address => uint256) public whitelistPaidClaimed;
    mapping(address => uint256) public pubPaidMintAmount;

    constructor() ERC721A("TRANSMISSIONS FROM ALIEN WORLD", "TRANSMISSION") {
    }

    function mintWL(uint256 _quantity, bytes32[] memory _merkleProof) public payable {
        require(_quantity > 0);
        require(wlActive, "PRESALE_INACTIVE");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(msg.value >= WLcost * _quantity);
        require(whitelistPaidClaimed[msg.sender] + _quantity <= 2, "WLPAID_MAXED");
        unchecked {
            whitelistPaidClaimed[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
        delete s;
    }


    function mintPublic(uint256 _quantity) external payable {
        require(_quantity > 0);
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(pubActive, "PUBLIC_INACTIVE");
        require(msg.value >= pubCost * _quantity, "INCORRECT_ETH");
        require(pubPaidMintAmount[msg.sender] + _quantity <= 2, "PUBLICPAID_MAXED");
        unchecked {
            pubPaidMintAmount[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
        delete s;
    }

    function treasuryMint(address _account, uint256 _quantity)
        external
        onlyOwner
    {
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Over Supply");
        require(_quantity > 0, "QUANTITY_INVALID");
        _safeMint(_account, _quantity);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWLCost(uint256 _newCost) public onlyOwner {
        WLcost = _newCost;
    }

    function setPubCost(uint256 _newCost) public onlyOwner {
        pubCost = _newCost;
    }

    function activateWLSale() external onlyOwner {
        !wlActive ? wlActive = true : wlActive = false;
    }

    function activatePublicSale() external onlyOwner {
        !pubActive ? pubActive = true : pubActive = false;
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata _baseURI, bool appendID) external onlyOwner {
        if (!appendedID && appendID) appendedID = appendID; 
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Cannot query non-existent token");
        if (appendedID) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
        } else {
            return baseURI;
        }
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withdrawAny(uint256 _amount) public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success);
    }
}