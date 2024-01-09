// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./WithContractMetaData.sol";

contract MG is
ERC721Enumerable,
Ownable,
WithContractMetaData
{
    string public baseURI;
    uint256 private _totalSupply = 999;

    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);

    constructor(string memory _initBaseURI)
    ERC721("META GIRLS", "MG", _totalSupply)
    WithContractMetaData("")
    {
        baseURI = _initBaseURI;
        // premint to the contract creator because we dont want a user mint
        _initiator_levies_count = _totalSupply;
        _initiator = msg.sender;
        // emit that the creator has minted all tokens
        emit ConsecutiveTransfer(1, _totalSupply, address(0), _initiator);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw(address payable receiver) external onlyOwner {
        receiver.transfer(address(this).balance);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
}
