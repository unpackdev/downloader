pragma solidity ^0.8.2;

import "./Ownable.sol";

interface Hollow {
    function createTo(address to, string memory URI) external;
    function editTokenURI(uint256 tokenId, string memory newURI) external;
    function transferOwnership(address newOwner) external;
}

contract HollowController is Ownable {
    address hollowDeployer = address(0xb1120f07C94d7F2E16C7F50707A26A74bF0B12Ec);
    
    Hollow hollowContract;
    
    constructor(address _hollowContractAddress) {
        hollowContract = Hollow(_hollowContractAddress);
    }
    
    function transferHollowOwnership(address _newOwner) public onlyOwner {
        hollowContract.transferOwnership(_newOwner);
    }
    
    function mintMultiple(string[] memory _tokenURIs) public onlyOwner {
        for(uint256 i = 0; i < _tokenURIs.length; i++) {
            hollowContract.createTo(hollowDeployer, _tokenURIs[i]);
        }
    }
    
    function mintMultipleTo(address to, string[] memory _tokenURIs) public onlyOwner {
        for(uint256 i = 0; i < _tokenURIs.length; i++) {
            hollowContract.createTo(to, _tokenURIs[i]);
        }
    }
    
    function editMultiple(uint256[] memory _tokenIds, string[] memory _newTokenURIs) public onlyOwner {
        require(_tokenIds.length == _newTokenURIs.length, "Array lengths must match");
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            hollowContract.editTokenURI(_tokenIds[i], _newTokenURIs[i]);
        }
    }
}