// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract SpeakerCard is ERC721, Ownable {
    using Address for address payable;
    using Strings for uint256;

    //0 = init phase, 1 = sell phase, 2 = end phase
    uint256 public currentPhase;

    //current minted supply
    uint256 public totalSupply;

    //pbws address
    address public pbwsAddress;

    //metadatas
    string public baseURI;

    mapping(uint256 => uint256) private prices;

    constructor(address _pbwsAddress)
    ERC721("Paris NFT Day Speaker Cards", "PND SC")
        {
            pbwsAddress = _pbwsAddress;
        }

    function dropCards(address speakerAddress, address teamAddress) external onlyOwner {
        require(currentPhase==0, "the contract status doesn't allow this");
        require(_balances[speakerAddress]==0, "speaker already dropped");
        _mintSpeaker(speakerAddress);
        _mintTeam(teamAddress);
        _mintPbws();
    }

    function setPrice(uint256 tokenId, uint256 price) external onlyOwner {
        require(currentPhase==0, "the contract status doesn't allow this");
        prices[tokenId] = price;
    }

    function retrieveFunds(address fundsAddress) external onlyOwner {
        payable(fundsAddress).sendValue(address(this).balance);
    }
    
    function getPrice(uint256 tokenId) public view returns(uint256) {
        if(tokenId % 11 != 0){
            return 0;
        }
        return prices[tokenId];
    }

    function buySpeakerCard(uint256 tokenId) external payable {
        require(currentPhase==1, "the contract status doesn't allow this");
        require(tokenId % 11 == 0, "given tokenId is not a speaker card");
        require(prices[tokenId]!=0,"this speaker card is not for sale or has already been sold");
        require(msg.value == prices[tokenId], "wei amount doesn't match with card price");
        address payable speakerAddress = payable(_owners[tokenId]);
        address to = msg.sender;
        _balances[speakerAddress]--;
        _balances[to]++;
        _owners[tokenId] = to;
        delete prices[tokenId];
        speakerAddress.sendValue((msg.value * 9000)/10000);
        emit Transfer(speakerAddress, to, tokenId);
    }

    function activateSellPhase() public onlyOwner {
        require(currentPhase==0, "the contract status doesn't allow this");
        currentPhase=1;
    }

    function activateLastPhase() public onlyOwner {
        require(currentPhase==1, "the contract status doesn't allow this");
        currentPhase=2;
    }
    
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _mintSpeaker(address speakerAddress) private {
        _owners[totalSupply] = speakerAddress;
        _balances[speakerAddress]++;
        emit Transfer(address(0), speakerAddress, totalSupply++);
    }

    function _mintTeam(address teamAddress) private {
        for(uint i = 0; i < 8; i++){
            _owners[totalSupply] = teamAddress;
            emit Transfer(address(0), teamAddress, totalSupply++);
        }
        _balances[teamAddress] = _balances[teamAddress] + 8;
    }

    function _mintPbws() private {
        for(uint i = 0; i < 2; i++){
            _owners[totalSupply] = pbwsAddress;
            emit Transfer(address(0), pbwsAddress, totalSupply++);
        }
        _balances[pbwsAddress] = _balances[pbwsAddress] + 2;
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(tokenId % 11 != 0, "you cannot transfer a speaker card");
    }

}