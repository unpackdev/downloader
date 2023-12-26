// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./ERC721.sol";

contract Invaders is ERC721 {
    uint public invader_cost = 0.02 ether ; //cost of 1 invader
    uint public max_amount = 51 ; //maximum invader amount/address
    uint public max_supply = 10000 ; //max total supply ever
    uint public start_unix = 1631237400 ;  //start minting time

    bool public live = true ; 

    address public OpenSeaRegistry_address  = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; 

    address public owner ;

    uint public _totalSupply = 0 ;

    constructor() ERC721("Invaders", "ALIEN") {
        owner = msg.sender ; 
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "INVADERS: sender not owner") ; 
        _;
    }

    /**
     * @dev transfer ownership of contract to newOwner 
     * @param newOwner new owner (note: must be EOA or implements withdraw() or funds might get lost)
     */
    function transferOwnership(address newOwner) onlyOwner external {
        require(newOwner != address(0), "INVADERS: cannot transfer ownership to blackhole") ; 
        owner = newOwner ; 
    }

    /**
     * @dev minting function for 1 invader
     */
    function mint() public payable {
        uint tokenID = totalSupply() ;
        require(live, "INVADERS: minting is not live") ; 
        require(block.timestamp >= start_unix, "INVADERS: minting has not yet started") ; 
        require(msg.value >= invader_cost, "INVADERS: msg.value not enough") ; 
        require(_totalSupply < max_supply, "INVADERS: max supply is reached") ; 
        _mint(msg.sender, tokenID) ; 
        _totalSupply += 1 ; 
        require(balanceOf(msg.sender) <= max_amount, "INVADERS: user balance exceeds max_amount") ;
    }    

    /**
    * @dev bulk mint invaders in 1 tx
    * @param amount amount of invaders to mint
    */
    function bulkMint(uint amount) public payable {
        require(live, "INVADERS: minting is not live") ; 
        require(block.timestamp >= start_unix, "INVADERS: minting has not yet started") ; 
        require(msg.value >= amount * invader_cost, "INVADERS: msg.value not enough") ; 
        require(_totalSupply + amount < max_supply, "INVADERS: max supply is reached") ; 

        for (uint i = _totalSupply; i < _totalSupply + amount; i++) {
            _mint(msg.sender, i) ; 
        }

        _totalSupply += amount ; 
        require(balanceOf(msg.sender) <= max_amount, "INVADERS: user balance exceeds max_amount") ;
    }

    /**
    * @dev mint on ether receival, automatically determines how many, division results in integer 
    */
    receive() payable external {
        uint _amount = msg.value / invader_cost ; 

        if (_amount == 1) {
            mint() ; 
        } else {
            bulkMint(_amount) ; 
        }
    }

    /**
    * @dev withdraw funds from contract to receiver, only owner can call
    * @param receiver, receiver of the funds (note: EOA or payable contract)
    */
    function withdraw(address payable receiver) onlyOwner external {
        require(receiver != address(0), "INVADERS: cannot withdaw to blackhole") ; 
        receiver.transfer(address(this).balance) ;
    }

    /**
    * @dev change live status to state, only owner can call
    * @param state, state of minting process (true = live)
     */
    function changeLive(bool state) onlyOwner external {
        require(state != live, "INVADERS: live equals input state") ; 
        live = state ; 
    }

    /**
    * @dev set OpenSea registry address for ApprovedForAll, only owner can call
    * @param _addr, address of OpenSea registry contract
     */
    function set_registry_address(address _addr) external onlyOwner {
        OpenSeaRegistry_address = _addr ; 
    }

    /**
    * @dev OpenSea: as another option for supporting trading without requiring meta transactions, override isApprovedForAll to whitelist OpenSea proxy accounts
    */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        if (_operator == address(OpenSeaRegistry_address)) {
            return true;
        }
        
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    /**
    * @dev Get total amount of existent invaders
    */
    function totalSupply() public view returns (uint) {
        return _totalSupply ; 
    }

    /** 
    * @dev returns baseTokenURI for metadata   
    */
    function baseTokenURI() public pure returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmedfUttbMsiiELCXrGwAr1Na2bHXdq9yPnvXpZR9b2DnR/";
    }

    /**
    * @dev Returns an URI for a given token ID, token must exist
    * @param _tokenId uint256 ID of the token to query
    */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(exists(_tokenId));
        return concatenate(baseTokenURI(), uint2str(_tokenId), ".json") ; 
    }

    /**
    * @dev Returns whether the specified token exists
    * @param _tokenId uint256 ID of the token to query the existence of
    */
    function exists(uint256 _tokenId) public view returns (bool) {
        address _owner = ownerOf(_tokenId);
        return _owner != address(0);
    }

    /**
    * @dev concatenate two strings a, b and c in order: a + b + c
    * @param a, string a
    * @param b, string b
    * @param c, string c
    */
    function concatenate(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));

    }

    /**
    * @dev convert uint to string (memory)
    * @param _i, integer to convert to string
    */
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
        }
}