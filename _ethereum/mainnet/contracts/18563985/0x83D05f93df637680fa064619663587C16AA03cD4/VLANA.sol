// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract Vlana is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    uint256 public constant _MAX_ONCE = 6;
    uint256 public constant _MAX_TOTAL_SUPPLY = 11111;
    uint256 public _public_price = 0.028 ether;
    uint256 public _whitelist_price = 0.025 ether;

    uint256 public _whitelist_time = 1697839200; //2023/10/21 6:00
    uint256 public _public_time = 1697925600; //2023/10/22 6:00
    uint256 public _revealed_time = 1703570400; //2023/12/26 6:00
    bytes32 private _merkleRoot = 0x82a5a0a6f5c1183150df04cb1d146c6a07ea043b9d0cc59130414841cd77fcd5;
    string public _notRevealedUri = "ipfs://bafybeigqmctnt5xczo2hxvkkvji6zdv46apmpukhujoq6pmzfic4lapsyy/1.json";
    string private _baseTokenURI;

    constructor() ERC721A("Vlana", "VLA") Ownable(msg.sender) {
        _safeMint( msg.sender, 1 );
    }

    function airDrop( address[] memory wellet, uint256[] memory amount ) public onlyOwner {
        require( block.timestamp > _public_time, "airdrop : public mint not ready " );
        require( wellet.length == amount.length, "airdrop : wellet and amount size are different" );
 
        for( uint256 i = 0 ; i < wellet.length ; )
        {
            require( amount[i] <= _MAX_ONCE, "airdrop : too much " );
            require( getCurrentCounter() + amount[i] <= _MAX_TOTAL_SUPPLY, "airdrop : not enough to mint " );
            _safeMint( wellet[i], amount[i] );
            unchecked{
                i++;
            }
        }

    }

    function mintWhiteList( bytes32[] memory proof, uint256 amount ) public payable {

        require( block.timestamp > _whitelist_time, "mint : public mint not ready " );
        require( amount <= _MAX_ONCE, "mint : too much " );

        require( getCurrentCounter() + amount <= _MAX_TOTAL_SUPPLY, "mint : not enough to mint " );

        require( msg.value >= _whitelist_price * amount, "mint : ETH not enough to mint " );
        require(MerkleProof.verify(proof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))), "not in merkle proof whitelist");
        
        _safeMint( msg.sender, amount );
    }

    function mintVlana( uint256 amount ) public payable {
        require( block.timestamp > _public_time, "mint : public mint not ready " );
        require( amount <= _MAX_ONCE, "mint : too much " );

        require( getCurrentCounter() + amount <= _MAX_TOTAL_SUPPLY, "mint : not enough to mint " );

        require( msg.value >= _public_price * amount, "mint : ETH not enough to mint " );

        _safeMint( msg.sender, amount );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require( _exists(tokenId), "URI query for nonexistent token");

        if( block.timestamp < _revealed_time ){
            return _notRevealedUri;
        } else {
            return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
        }
    }

    function getMerkleRoot() public view returns ( bytes32 ) {
        return _merkleRoot;
    }

    function setMerkleRoot( bytes32 root ) public onlyOwner {
        _merkleRoot = root;
    }

    function getCurrentCounter() public view returns (uint256){
        return totalSupply();
    }

    function setTimeConfig( uint256 whiteListTime, uint256 publicTime, uint256 revealedTime ) public onlyOwner {
        if( whiteListTime != 0 )
            _whitelist_time = whiteListTime;
        
        if( publicTime != 0 )
            _public_time = publicTime;

        if( revealedTime != 0 )
            _revealed_time = revealedTime;
    }

    function setPublicPrice( uint256 p_price, uint256 wl_price ) public onlyOwner {
        _public_price = p_price;
        _whitelist_price = wl_price;
    }

    function setNotRevealedUri( string memory uri ) public onlyOwner{
        _notRevealedUri = uri;
    }

    function setBaseURI( string memory uri ) public onlyOwner {
        _baseTokenURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return _baseTokenURI;
    }

    function startTokenId() public view returns (uint256) {
        return _startTokenId();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "Transfer failed.");
    }

}