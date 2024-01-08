// SPDX-License-Identifier: MIT
// HeadOfHeroes collection from Platinum
pragma solidity 0.8.7;

import "./ERC1155Supply.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract HeadOfHero1155 is ERC1155Supply, Ownable {

    using Strings for uint256;
    using Strings for uint160;

    struct TokenReq {
        uint256 delayForMint;
        uint256 maxSupply;
        bool dependTotalSupply;
    }

    string public name = "Head of HEROES - Galaxy Modificators";
    uint256 public MAX_TOTAL_SUPPLY = 999;
    uint256 public totalContractSupply;

    mapping(uint256 => TokenReq) public tokenReq;
    
    mapping(address => uint256) public lastMintTime;


    constructor(string memory baseUri)
       ERC1155(baseUri)  {
    }

    function mint(uint256 _tokenId) external {
        // Checks
        require(totalSupply(_tokenId) > 0, "NFT not created yet");

        if (tokenReq[_tokenId].maxSupply > 0) { 
            require(
                totalSupply(_tokenId) + 1 <= tokenReq[_tokenId].maxSupply, 
                "NFT Supply exceeded"
            );
        }

        require(
            lastMintTime[msg.sender] + tokenReq[_tokenId].delayForMint  < block.timestamp, 
            "Too early for minting"
        );
        
        if (tokenReq[_tokenId].dependTotalSupply) {
            require(
                totalContractSupply + 1 <= MAX_TOTAL_SUPPLY, 
                "Contract Supply exceeded"
            );
            totalContractSupply += 1;
        }

        lastMintTime[msg.sender] = block.timestamp;

        _mint(msg.sender, _tokenId, 1, bytes('0'));
    }

    function getTokenReq(uint256 _tokenId) external view returns (TokenReq memory) {
        return tokenReq[_tokenId];
    }
    
    ///////////////////////////////////////////////////////////////////
    /////  Owners Functions ///////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////
    
    function createNew(
        address _account,
        uint256 _id,
        uint256 _amount,
        uint256 _delayForMint,
        uint256 _maxSupply,
        bool _dependTotalSupply
    ) external onlyOwner {
        _mint(_account, _id, _amount, bytes('0'));
        _setTokenReq(_id, _delayForMint, _maxSupply, _dependTotalSupply);
    }

    
    function editTokenReq(
        uint256 _id,
        uint256 _delayForMint,
        uint256 _maxSupply,
        bool _dependTotalSupply
    ) external onlyOwner {
        _setTokenReq(_id, _delayForMint, _maxSupply, _dependTotalSupply);
    }

    function setMaxTotalSupply(uint256 _newMaxSupply) external onlyOwner {
        MAX_TOTAL_SUPPLY = _newMaxSupply;
    }

    ///////////////////////////////////////////////////////////////////
    /////  INTERNALS      /////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////

    function _setTokenReq(
        uint256 _id,
        uint256 _delayForMint,
        uint256 _maxSupply,
        bool _dependTotalSupply
    ) internal {
        tokenReq[_id] = TokenReq({
            delayForMint: _delayForMint,
            maxSupply: _maxSupply,
            dependTotalSupply: _dependTotalSupply
            });
    }

    function uri(uint256 _tokenID) public view virtual override 
        returns (string memory) 
    {
        return string(abi.encodePacked(
            ERC1155.uri(0),
            uint160(address(this)).toHexString(),
            "/", _tokenID.toString())
        );
    }
}
