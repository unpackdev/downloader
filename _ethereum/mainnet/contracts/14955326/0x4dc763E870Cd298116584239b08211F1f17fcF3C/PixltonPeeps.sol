// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IPixls.sol";

// Pixlton Car Club contract
contract PixltonPeeps is PPERC721Enumerable, Ownable {
    string public baseURI;
    bool public ClaimActive = false;

    // Ledger of Pixl IDs that were claimed with.
    mapping(uint256 => bool) ClaimedPixlIds;

    string public constant Z = "We need a transformation. One we all can see. We need a revolution. So long as we stay free.";

    // Parent NFT Contract mainnet address
    address public nftAddress = 0x082903f4e94c5e10A2B116a4284940a36AFAEd63;
    IPixls nftContract = IPixls(nftAddress);

    constructor(string memory _baseURI) PPERC721("Pixlton Peeps", "PPVX") {
        baseURI = _baseURI;
    }    

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function toggleClaimState() public onlyOwner {
        ClaimActive = !ClaimActive;
    }

    function getClaimable() external view returns (uint256[] memory) {
        uint256 amount = nftContract.balanceOf(msg.sender);
        uint256[] memory lot = new uint256[](amount);
        uint16 arrayIndex = 0;

        for (uint i = 0; i < amount; i++) {
            uint256 id = nftContract.tokenOfOwnerByIndex(msg.sender, i);
            
            if(!ClaimedPixlIds[id])
            {
                lot[arrayIndex] = id;            
                arrayIndex += 1;
            }
        }

        uint256 needDec = amount - arrayIndex;
        assembly { mstore(lot, sub(mload(lot), needDec)) }
        
        return lot;
    }

    function checkIfClaimed(uint256 nftId) external view returns (bool) {
        return ClaimedPixlIds[nftId];
    }

    function claimWithPixl(uint256 nftId) public {
        require(ClaimActive, "Pixlton Peeps must be active to claim.");
        require(nftContract.ownerOf(nftId) == msg.sender, "Not the owner of this Pixltonian.");
        require(!ClaimedPixlIds[nftId], "This Pixltonian has already been used.");
        _safeMint(msg.sender, nftId);
        ClaimedPixlIds[nftId] = true;
    }

     function multiClaimWithPixl(uint256 [] memory nftIds) public {
        require(ClaimActive, "Pixlton Peeps must be active to claim.");

        for (uint i=0; i< nftIds.length; i++) {
            require(nftContract.ownerOf(nftIds[i]) == msg.sender, "Not the owner of this Pixltonian.");

            if(ClaimedPixlIds[nftIds[i]]) {
                continue;
            } else {
                _safeMint(msg.sender, nftIds[i]);
                ClaimedPixlIds[nftIds[i]] = true;
            }
        }
    }

    function multiClaimWithAll() external {
        require(ClaimActive, "Pixlton Peeps must be active to claim.");
        uint256 balance = nftContract.balanceOf(msg.sender);
        uint256[] memory lot = new uint256[](balance);

        for (uint i = 0; i < balance; i++) {
            lot[i] = nftContract.tokenOfOwnerByIndex(msg.sender, i);
        }

        multiClaimWithPixl(lot);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }

        return true;
    }

    function withdraw() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        payable(msg.sender).transfer(totalBalance);
    }
}